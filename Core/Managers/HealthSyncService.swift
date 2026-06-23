// HealthSyncService.swift
// HealthKit 双向同步服务
//
// 职责：
// 1. 在 App 启动 / 切前台时，读取 Health App 中新增的喝水记录
// 2. 与 WaterStore 已有记录做去重（HK UUID + 时间+水量兜底）
// 3. 把新记录写入 WaterStore
// 4. 对 WaterStore 新增的记录触发 PlantEngine.water()（让植物知道）
//
// 触发时机：
// - 用户手动点"立即同步"时
// - App 切前台时（根据同步频率设置）
// - 每小时后台刷新（如果 App 被系统唤醒且设置为每小时同步）
//
// 隐私合规：
// - 仅在用户明确授权后才进行同步
// - 用户可单独控制写入和读取开关
// - 用户可随时删除所有 Bloom 写入的健康数据

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthSyncService: ObservableObject {
    static let shared = HealthSyncService()

    /// 同步频率
    enum SyncFrequency: String, Codable, CaseIterable {
        case realtime   // 实时（每次切前台都同步）
        case hourly     // 每小时
        case manual     // 仅手动

        var localizedDescription: String {
            switch self {
            case .realtime:
                return NSLocalizedString("实时", comment: "Sync frequency: realtime")
            case .hourly:
                return NSLocalizedString("每小时", comment: "Sync frequency: hourly")
            case .manual:
                return NSLocalizedString("仅手动", comment: "Sync frequency: manual")
            }
        }
    }

    // MARK: - 存储 Keys

    private let lastSyncKey = "lastHealthKitSyncTimestamp"
    private let syncFrequencyKey = "healthKitSyncFrequency"
    private let totalSyncedRecordsKey = "healthKitTotalSyncedRecords"
    private let totalWrittenRecordsKey = "healthKitTotalWrittenRecords"

    // MARK: - 发布属性

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var lastSyncError: String?
    @Published private(set) var lastSyncErrorRecovery: String?
    @Published private(set) var newRecordsCount = 0

    /// 同步频率设置
    @Published var syncFrequency: SyncFrequency {
        didSet {
            storage.set(syncFrequency.rawValue, forKey: syncFrequencyKey)
        }
    }

    /// 累计从 HealthKit 同步到本地的记录数
    @Published private(set) var totalSyncedRecords: Int

    /// 累计写入 HealthKit 的记录数
    @Published private(set) var totalWrittenRecords: Int

    // MARK: - 依赖

    private let healthManager = HealthManager.shared
    private let storage = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard

    private init() {
        lastSyncTime = storage.object(forKey: lastSyncKey) as? Date
        totalSyncedRecords = storage.integer(forKey: totalSyncedRecordsKey)
        totalWrittenRecords = storage.integer(forKey: totalWrittenRecordsKey)

        if let raw = storage.string(forKey: syncFrequencyKey),
           let freq = SyncFrequency(rawValue: raw) {
            syncFrequency = freq
        } else {
            syncFrequency = .realtime
        }
    }

    // MARK: - 公开接口

    /// 根据同步频率设置，判断是否需要自动同步
    func shouldAutoSync() -> Bool {
        guard healthManager.readEnabled, healthManager.isReadAuthorized else {
            return false
        }

        switch syncFrequency {
        case .manual:
            return false
        case .realtime:
            return true
        case .hourly:
            guard let last = lastSyncTime else { return true }
            let hoursSince = Date().timeIntervalSince(last) / 3600
            return hoursSince >= 1
        }
    }

    /// 执行一次增量同步（读取上次同步之后的所有 HK 记录）
    /// - Parameters:
    ///   - waterStore: 目标 WaterStore
    ///   - plantEngine: 触发浇水用的 PlantEngine（传 nil 则只写记录不喂植物）
    func sync(
        waterStore: WaterStore,
        plantEngine: PlantEngine?
    ) async {
        guard !isSyncing else { return }
        guard healthManager.readEnabled else {
            lastSyncError = HealthManager.HealthError.readDisabled.errorDescription
            lastSyncErrorRecovery = HealthManager.HealthError.readDisabled.recoverySuggestion
            return
        }
        guard healthManager.isReadAuthorized else {
            lastSyncError = HealthManager.HealthError.notAuthorized.errorDescription
            lastSyncErrorRecovery = HealthManager.HealthError.notAuthorized.recoverySuggestion
            return
        }

        isSyncing = true
        lastSyncError = nil
        lastSyncErrorRecovery = nil
        newRecordsCount = 0

        defer { isSyncing = false }

        do {
            let startDate = lastSyncTime ?? Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let endDate = Date()

            let hkRecords = try await healthManager.fetchWaterRecords(from: startDate, to: endDate)

            guard !hkRecords.isEmpty else {
                updateLastSyncTime(to: endDate)
                return
            }

            // 逐条处理：去重 → 写入 WaterStore → 触发植物喝水
            var newCount = 0
            for sample in hkRecords {
                let amountML = Int(sample.quantity.doubleValue(for: .liter()) * 1000)
                let sampleUUID = sample.uuid

                let added = waterStore.addIfNotExists(
                    amount: amountML,
                    date: sample.startDate,
                    cupType: .medium,
                    hkSampleUUID: sampleUUID
                )

                if added != nil {
                    newCount += 1
                    if let engine = plantEngine, !engine.plant.isPaused {
                        engine.water(amount: amountML)
                    }
                }
            }

            newRecordsCount = newCount
            if newCount > 0 {
                totalSyncedRecords += newCount
                storage.set(totalSyncedRecords, forKey: totalSyncedRecordsKey)
            }
            updateLastSyncTime(to: endDate)

            // 记录同步结果到日志
            let log = SyncLog(
                timestamp: endDate,
                newRecords: newCount,
                totalHKRecords: hkRecords.count,
                error: nil
            )
            saveSyncLog(log)

        } catch let error as HealthManager.HealthError {
            lastSyncError = error.errorDescription
            lastSyncErrorRecovery = error.recoverySuggestion
            #if DEBUG
            print("[HealthSync] Sync failed: \(error)")
            #endif

            let log = SyncLog(
                timestamp: Date(),
                newRecords: 0,
                totalHKRecords: 0,
                error: error.errorDescription
            )
            saveSyncLog(log)

        } catch {
            lastSyncError = String(format: NSLocalizedString("同步失败：%@", comment: "Sync failed"),
                                   error.localizedDescription)
            #if DEBUG
            print("[HealthSync] Sync failed: \(error)")
            #endif

            let log = SyncLog(
                timestamp: Date(),
                newRecords: 0,
                totalHKRecords: 0,
                error: error.localizedDescription
            )
            saveSyncLog(log)
        }
    }

    /// 记录一次写入成功（用于统计）
    func incrementWriteCount() {
        totalWrittenRecords += 1
        storage.set(totalWrittenRecords, forKey: totalWrittenRecordsKey)
    }

    /// 重置同步统计（删除所有数据时调用）
    func resetStats() {
        totalSyncedRecords = 0
        totalWrittenRecords = 0
        lastSyncTime = nil
        storage.removeObject(forKey: totalSyncedRecordsKey)
        storage.removeObject(forKey: totalWrittenRecordsKey)
        storage.removeObject(forKey: lastSyncKey)
        storage.removeObject(forKey: "healthSyncLogs")
    }

    // MARK: - 同步日志

    private let syncLogsKey = "healthSyncLogs"

    private func saveSyncLog(_ log: SyncLog) {
        var logs = loadSyncLogs()
        logs.insert(log, at: 0)
        if logs.count > 20 { logs = Array(logs.prefix(20)) }
        if let data = try? JSONEncoder().encode(logs) {
            storage.set(data, forKey: syncLogsKey)
        }
    }

    func loadSyncLogs() -> [SyncLog] {
        guard let data = storage.data(forKey: syncLogsKey),
              let logs = try? JSONDecoder().decode([SyncLog].self, from: data) else {
            return []
        }
        return logs
    }

    // MARK: - 私有工具

    private func updateLastSyncTime(to date: Date) {
        lastSyncTime = date
        storage.set(date, forKey: lastSyncKey)
    }
}

// MARK: - 同步日志

struct SyncLog: Codable {
    let timestamp: Date
    let newRecords: Int
    let totalHKRecords: Int
    let error: String?
}
