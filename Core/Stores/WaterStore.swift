import WidgetKit
// WaterStore.swift
// 喝水记录 store —— 植物的"水分"来源，也是用户行为凭证

import Foundation
import SwiftUI

@MainActor
final class WaterStore: ObservableObject {
    /// 单例：整个 app 共用同一个 WaterStore 实例，避免多实例数据不一致
    static let shared = WaterStore()

    @Published private(set) var records: [WaterRecord] = []

    /// 当日目标（从 UserStore 同步，避免循环依赖，用闭包注入）
    var dailyGoalProvider: () -> Int = { 2000 }

    /// HealthKit 管理器（由 BloomApp 注入，用于自动同步写入并回写 UUID）
    weak var healthManager: HealthManager?

    private let storage = PersistenceManager.shared
    private let filename = "water_records.json"
    private let cloudSync = CloudSyncManager.shared
    
    /// 防抖同步（避免每次喝水都触发同步）
    private var syncTask: Task<Void, Never>?

    init() {
        records = storage.load([WaterRecord].self, filename: filename) ?? []
    }

    // MARK: - 记录操作

    @discardableResult
    func add(amount: Int, cupType: CupType = .medium) -> WaterRecord {
        let record = WaterRecord(amount: amount, cupType: cupType)
        records.insert(record, at: 0)

        // HealthKit 自动同步 + 回写 UUID（双向同步：删除记录时可反向删除 HealthKit 样本）
        if let healthManager = healthManager, healthManager.isAuthorized {
            let recordID = record.id
            Task { @MainActor in
                do {
                    let uuid = try await healthManager.saveWater(amount)
                    if let idx = records.firstIndex(where: { $0.id == recordID }) {
                        records[idx].hkSampleUUID = uuid
                        persist()
                        triggerSync()
                    }
                } catch {
                    #if DEBUG
                    print("[WaterStore] 保存 HealthKit UUID 失败: \(error)")
                    #endif
                }
            }
        }

        // 先持久化记录
        persist()
        
        // 通知 Widget 刷新数据（由 BloomApp 监听并写入 App Group 后刷新 Widget）
        // 注意：必须在 persist() 后发送通知，确保数据已保存
        NotificationCenter.default.post(name: AppConstants.NotificationNames.refreshWidget, object: nil)
        
        triggerSync()
        updateAchievements()
        return record
    }
    
    /// 恢复已删除的记录（用于撤销功能）
    /// - Parameter record: 要恢复的记录（保持原始 id 和时间戳）
    func restore(record: WaterRecord) {
        // 避免重复添加
        guard !records.contains(where: { $0.id == record.id }) else { return }
        
        records.insert(record, at: 0)
        
        // HealthKit 同步（如果原记录有关联的 HK UUID，尝试删除后重新保存）
        if let healthManager = healthManager, healthManager.isAuthorized {
            Task {
                do {
                    let uuid = try await healthManager.saveWater(record.amount)
                    if let idx = records.firstIndex(where: { $0.id == record.id }) {
                        records[idx].hkSampleUUID = uuid
                    }
                } catch {
                    #if DEBUG
                    print("[WaterStore] 恢复记录时保存 HealthKit 失败: \(error)")
                    #endif
                }
            }
        }
        
        persist()
        NotificationCenter.default.post(name: AppConstants.NotificationNames.refreshWidget, object: nil)
        triggerSync()
        updateAchievements()
    }

    /// 从 HealthKit 同步记录时使用（带 HK UUID 去重）
    /// - Returns: 新增的记录数量（0 表示无新增）
    @discardableResult
    func addIfNotExists(
        amount: Int,
        date: Date,
        cupType: CupType = .medium,
        hkSampleUUID: UUID
    ) -> WaterRecord? {
        // 1. HK UUID 去重（最精确）
        if records.contains(where: { $0.hkSampleUUID == hkSampleUUID }) {
            return nil
        }
        // 2. 时间+水量去重（兜底：同分钟同水量不重复）
        let cal = Calendar.current
        let rounded = cal.date(bySettingHour: cal.component(.hour, from: date),
                               minute: cal.component(.minute, from: date),
                               second: 0, of: date) ?? date
        if records.contains(where: {
            cal.isDate($0.createdAt, equalTo: rounded, toGranularity: .minute)
            && $0.amount == amount
        }) {
            return nil
        }
        let record = WaterRecord(
            amount: amount,
            cupType: cupType,
            hkSampleUUID: hkSampleUUID
        )
        records.insert(record, at: 0)
        persist()
        NotificationCenter.default.post(name: AppConstants.NotificationNames.refreshWidget, object: nil)
        triggerSync()
        updateAchievements()
        return record
    }

    func delete(_ record: WaterRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records.remove(at: idx)
            persist()
            NotificationCenter.default.post(name: AppConstants.NotificationNames.refreshWidget, object: nil)
            triggerSync()
        }
    }

    func deleteAll() {
        records.removeAll()
        persist()
        triggerSync()
    }

    private func persist() {
        storage.save(records, filename: filename)
    }
    
    /// 触发 iCloud 同步（防抖 2 秒）
    private func triggerSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await cloudSync.syncWaterRecords(records)
        }
    }
    // MARK: - 成就系统集成
    
    var achievementStore: AchievementStore?
    
    /// 更新成就进度（在喝水后调用）
    private func updateAchievements() {
        guard let achievementStore = achievementStore else { return }
        
        // 计算总喝水次数
        let totalRecords = records.count
        
        // 计算总喝水量
        let totalAmount = records.reduce(0) { $0 + $1.amount }
        
        // 更新喝水成就
        achievementStore.updateHydrationProgress(
            totalRecords: totalRecords,
            totalAmount: totalAmount
        )
        
        // 更新连续天数成就（用 longestStreak 而非 currentStreak：
        // 连续天数成就衡量的是"曾经达到过多少天连续达标"，而非"当前连续多少天"）
        achievementStore.updateStreakProgress(currentStreak: longestStreak)
    }

    // MARK: - 今日查询

    var todayRecords: [WaterRecord] {
        let (start, end) = todayBounds
        return records.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    var dailyGoal: Int { dailyGoalProvider() }

    var todayProgress: Double {
        let goal = dailyGoal
        guard goal > 0 else { return 0 }
        return min(Double(todayTotal) / Double(goal), 1.0)
    }

    var isGoalMetToday: Bool { todayTotal >= dailyGoal }

    /// 今天还需多少毫升
    var remaining: Int { max(dailyGoal - todayTotal, 0) }

    // MARK: - 连胜

    var currentStreak: Int {
        calculateStreak(includeToday: true)
    }

    var longestStreak: Int {
        calculateLongestStreak()
    }

    // MARK: - 周期统计

    func dailyTotals(from start: Date, to end: Date) -> [(date: Date, amount: Int)] {
        let cal = Calendar.current
        var cur = cal.startOfDay(for: start)
        let last = cal.startOfDay(for: end)
        var result: [(date: Date, amount: Int)] = []
        while cur <= last {
            guard let next = cal.date(byAdding: .day, value: 1, to: cur) else {
                continue
            }
            let total = records
                .filter { $0.createdAt >= cur && $0.createdAt < next }
                .reduce(0) { $0 + $1.amount }
            result.append((cur, total))
            cur = next
        }
        return result
    }

    var weekAverage: Int {
        let cal = Calendar.current
        let end = Date()
        guard let start = cal.date(byAdding: .day, value: -6, to: end) else {
            return 0
        }
        let totals = dailyTotals(from: start, to: end)
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0) { $0 + $1.amount } / totals.count
    }

    // MARK: - 私有：连胜计算

    private var todayBounds: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else {
            return (start, start)
        }
        return (start, end)
    }

    /// 每日总量字典 [日期起点: 总量]
    private var totalsByDay: [Date: Int] {
        let cal = Calendar.current
        var dict: [Date: Int] = [:]
        for r in records {
            dict[cal.startOfDay(for: r.createdAt), default: 0] += r.amount
        }
        return dict
    }

    private func calculateStreak(includeToday: Bool) -> Int {
        let cal = Calendar.current
        let goal = dailyGoal
        let totals = totalsByDay
        var streak = 0
        var check = cal.startOfDay(for: Date())

        // 今天还没达标不算中断（今天还没结束），从昨天往前数
        if !includeToday || (totals[check] ?? 0) < goal {
            guard let newCheck = cal.date(byAdding: .day, value: -1, to: check) else {
                return 0
            }
            check = newCheck
        }
        while (totals[check] ?? 0) >= goal {
            streak += 1
            guard let newCheck = cal.date(byAdding: .day, value: -1, to: check) else {
                break
            }
            check = newCheck
        }
        return streak
    }

    private func calculateLongestStreak() -> Int {
        let cal = Calendar.current
        let goal = dailyGoal
        let totals = totalsByDay
        guard !totals.isEmpty else { return 0 }

        let sorted = totals.keys.sorted()
        var longest = 0
        var run = 0
        var prev: Date?

        for day in sorted {
            let met = (totals[day] ?? 0) >= goal
            if met {
                if let p = prev, let next = cal.date(byAdding: .day, value: 1, to: p), next == day {
                    run += 1
                } else {
                    run = 1
                }
                longest = max(longest, run)
            } else {
                run = 0
            }
            prev = day
        }
        return longest
    }

    // MARK: - 云端数据合并
    
    /// 合并云端喝水记录（去重）：hkSampleUUID 优先 → id 次优先
    /// 多设备 HealthKit 同步时，同一 HealthKit 样本在不同设备上 WaterRecord.id 不同，
    /// 必须按 hkSampleUUID 去重，否则会产生重复记录。
    func mergeWithCloudRecords(_ cloudRecords: [WaterRecord]) {
        let localHKUUIDs = Set(records.compactMap(\.hkSampleUUID))
        let localIDs = Set(records.map(\.id))

        let newRecords = cloudRecords.filter { cloud in
            if let hk = cloud.hkSampleUUID, localHKUUIDs.contains(hk) {
                return false  // 本地已存在同一条 HealthKit 样本
            }
            return !localIDs.contains(cloud.id)
        }

        if !newRecords.isEmpty {
            records.append(contentsOf: newRecords)
            records.sort { $0.createdAt > $1.createdAt }
            persist()
            triggerSync()
        }
    }

    // MARK: - 备份恢复

    /// 替换所有记录（用于恢复备份）
    func replaceAllRecords(with newRecords: [WaterRecord]) {
        records = newRecords
        persist()
    }

    // MARK: - 数据归档（控制内存占用）

    /// 归档超过指定天数的旧记录（保留最近 N 天数据）
    /// - Parameter keepDays: 保留最近多少天的数据（默认 90 天）
    /// - Returns: 被归档的记录数量
    @discardableResult
    func archiveOldRecords(keepDays: Int = 90) -> Int {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -keepDays, to: Date()) else {
            return 0
        }

        let oldRecords = records.filter { $0.createdAt < cutoff }
        guard !oldRecords.isEmpty else { return 0 }

        // 将旧记录归档到单独文件
        let archiveFilename = "water_records_archive_\(Int(cutoff.timeIntervalSince1970)).json"
        storage.save(oldRecords, filename: archiveFilename)

        // 从内存中移除旧记录（保留需保留的，时间复杂度 O(n)）
        records.removeAll(where: { $0.createdAt < cutoff })
        persist()

        #if DEBUG
        print("[WaterStore] 归档了 \(oldRecords.count) 条旧记录到 \(archiveFilename)")
        #endif
        return oldRecords.count
    }

    /// 应用启动时自动检查并归档（由 App 启动流程调用）
    func autoArchiveIfNeeded() {
        let archived = archiveOldRecords(keepDays: 90)
        if archived > 0 {
            NotificationCenter.default.post(name: AppConstants.NotificationNames.refreshWidget, object: nil)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
