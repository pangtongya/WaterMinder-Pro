// WaterStore.swift
// 喝水记录 store —— 植物的"水分"来源，也是用户行为凭证

import Foundation
import SwiftUI

@MainActor
final class WaterStore: ObservableObject {
    @Published private(set) var records: [WaterRecord] = []

    /// 当日目标（从 UserStore 同步，避免循环依赖，用闭包注入）
    var dailyGoalProvider: () -> Int = { 2000 }

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
        persist()
        triggerSync()
        updateAchievements()
        return record
    }

    func delete(_ record: WaterRecord) {
        records.removeAll { $0.id == record.id }
        persist()
        triggerSync()
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
        
        // 更新连续天数成就
        achievementStore.updateStreakProgress(currentStreak: currentStreak)
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
    
    /// 合并云端喝水记录（去重）
    func mergeWithCloudRecords(_ cloudRecords: [WaterRecord]) {
        let existingIDs = Set(records.map(\.id))
        let newRecords = cloudRecords.filter { !existingIDs.contains($0.id) }
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
}
