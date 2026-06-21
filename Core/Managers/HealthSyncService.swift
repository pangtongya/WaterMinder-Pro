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
// - App 启动时
// - ScenePhase.active（用户切回 App）
// - 用户手动点"连接健康 App"时
// - 每 60 分钟后台刷新（如果 App 被系统唤醒）

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthSyncService: ObservableObject {
    static let shared = HealthSyncService()

    /// 最后一次同步时间（存储在 UserDefaults，通过 App Group 共享给 Widget）
    private let lastSyncKey = "lastHealthKitSyncTimestamp"

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var lastSyncError: String?
    @Published private(set) var newRecordsCount = 0  // 本次同步新增的记录数

    private let healthManager = HealthManager.shared
    private let storage = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard

    private init() {
        lastSyncTime = storage.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - 公开接口

    /// 执行一次增量同步（读取上次同步之后的所有 HK 记录）
    /// - Parameters:
    ///   - waterStore: 目标 WaterStore
    ///   - plantEngine: 触发浇水用的 PlantEngine（传 nil 则只写记录不喂植物）
    func sync(
        waterStore: WaterStore,
        plantEngine: PlantEngine?
    ) async {
        guard !isSyncing else { return }
        guard healthManager.isAuthorized else { return }

        isSyncing = true
        lastSyncError = nil
        newRecordsCount = 0

        defer { isSyncing = false }

        do {
            let startDate = lastSyncTime ?? Calendar.current.date(byAdding: .day, value: -7, to: Date())!
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
                // 从 sample.uuid 获取（HKQuantitySample 本身是 UUID-backed）
                let sampleUUID = sample.uuid

                let added = waterStore.addIfNotExists(
                    amount: amountML,
                    date: sample.startDate,
                    cupType: .medium,
                    hkSampleUUID: sampleUUID
                )

                if added != nil {
                    newCount += 1
                    // 新增一条 → 触发植物喝水（PlantEngine.water 内部会截断上限，
                    // 不必再做次数限制，避免"同步 200 条但植物只长 10 杯"的误导）
                    if let engine = plantEngine, !engine.plant.isPaused {
                        engine.water(amount: amountML)
                    }
                }
            }

            newRecordsCount = newCount
            updateLastSyncTime(to: endDate)

            // 记录同步结果到日志（可通过设置页查看诊断信息）
            let log = SyncLog(
                timestamp: endDate,
                newRecords: newCount,
                totalHKRecords: hkRecords.count,
                error: nil
            )
            saveSyncLog(log)

        } catch {
            lastSyncError = String(format: NSLocalizedString("同步失败：%@", comment: ""), error.localizedDescription)
            #if DEBUG
            print("[HealthSync] Sync failed: \(error)")
            #endif
        }
    }

    // MARK: - 私有工具

    private func updateLastSyncTime(to date: Date) {
        lastSyncTime = date
        storage.set(date, forKey: lastSyncKey)
    }

    private func saveSyncLog(_ log: SyncLog) {
        // 最多保留最近 20 条日志
        var logs = loadSyncLogs()
        logs.insert(log, at: 0)
        if logs.count > 20 { logs = Array(logs.prefix(20)) }
        if let data = try? JSONEncoder().encode(logs) {
            storage.set(data, forKey: "healthSyncLogs")
        }
    }

    private func loadSyncLogs() -> [SyncLog] {
        guard let data = storage.data(forKey: "healthSyncLogs"),
              let logs = try? JSONDecoder().decode([SyncLog].self, from: data) else {
            return []
        }
        return logs
    }
}

// MARK: - 同步日志

struct SyncLog: Codable {
    let timestamp: Date
    let newRecords: Int
    let totalHKRecords: Int
    let error: String?
}
