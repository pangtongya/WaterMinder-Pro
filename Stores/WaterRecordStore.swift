// WaterRecordStore.swift
// 喝水记录数据管理 - 含连胜计算

import Foundation
import SwiftUI

@MainActor
class WaterRecordStore: ObservableObject {
    @Published var items: [WaterRecordModel] = []
    
    private var saveWorkItem: DispatchWorkItem?
    private var appState: AppState { AppState.shared }
    
    nonisolated private static let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("water_records.json")
    }()
    
    init() {
        load()
        setupBackgroundSave()
    }
    
    private func setupBackgroundSave() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleWillResignActive() {
        saveWorkItem?.cancel()
        performSave(items: items)
    }
    
    // MARK: - CRUD
    
    func addRecord(amount: Int, cupType: CupType = .medium, note: String? = nil) -> WaterRecordModel {
        let record = WaterRecordModel(
            amount: amount,
            cupType: cupType,
            note: note
        )
        items.insert(record, at: 0)
        NotificationCenter.default.post(
            name: .init("WaterRecordStoreDidAddRecord"),
            object: record
        )
        save()
        return record
    }
    
    func deleteRecord(_ record: WaterRecordModel) {
        items.removeAll { $0.id == record.id }
        NotificationCenter.default.post(
            name: .init("WaterRecordStoreDidDeleteRecord"),
            object: record
        )
        save()
    }
    
    func deleteRecords(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
    
    func updateRecord(_ record: WaterRecordModel, amount: Int, cupType: CupType, note: String?) {
        if let index = items.firstIndex(where: { $0.id == record.id }) {
            items[index].amount = amount
            items[index].cupType = cupType
            items[index].note = note
            save()
        }
    }
    
    // MARK: - Queries
    
    var todayRecords: [WaterRecordModel] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return items.filter { record in
            record.createdAt >= today && record.createdAt < tomorrow
        }
    }
    
    var todayTotalAmount: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }
    
    var todayProgress: Double {
        let goal = appState.dailyGoal
        guard goal > 0 else { return 0.0 }
        return min(Double(todayTotalAmount) / Double(goal), 1.0)
    }
    
    var thisWeekRecords: [WaterRecordModel] {
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        return items.filter { $0.createdAt >= weekAgo && $0.createdAt <= today }
    }
    
    var thisWeekAverage: Int {
        guard !thisWeekRecords.isEmpty else { return 0 }
        let total = thisWeekRecords.reduce(0) { $0 + $1.amount }
        return total / thisWeekRecords.count
    }
    
    // MARK: - Streak Calculation
    
    /// 当前连续达标天数
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    /// 历史最长连续达标天数
    var longestStreak: Int {
        calculateLongestStreak()
    }
    
    /// 按日分组的总量字典
    private var dailyTotals: [Date: Int] {
        let calendar = Calendar.current
        var totals: [Date: Int] = [:]
        
        for record in items {
            let day = calendar.startOfDay(for: record.createdAt)
            totals[day, default: 0] += record.amount
        }
        return totals
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let goal = appState.dailyGoal
        let totals = dailyTotals
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        while true {
            let dayTotal = totals[checkDate] ?? 0
            if dayTotal >= goal {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let goal = appState.dailyGoal
        let totals = dailyTotals
        
        guard !totals.isEmpty else { return 0 }
        
        // 获取所有有记录的日期，排序
        let sortedDays = totals.keys.sorted(by: >)
        
        var longestStreak = 0
        var currentRun = 0
        var lastDate: Date?
        
        for date in sortedDays {
            if let last = lastDate {
                let expectedNextDay = calendar.date(byAdding: .day, value: -1, to: last)!
                if calendar.isDate(date, inSameDayAs: expectedNextDay) {
                    // 连续日期
                    if (totals[date] ?? 0) >= goal {
                        currentRun += 1
                    } else {
                        longestStreak = max(longestStreak, currentRun)
                        currentRun = 0
                    }
                } else {
                    // 不连续
                    longestStreak = max(longestStreak, currentRun)
                    currentRun = (totals[date] ?? 0) >= goal ? 1 : 0
                }
            } else {
                currentRun = (totals[date] ?? 0) >= goal ? 1 : 0
            }
            lastDate = date
        }
        
        longestStreak = max(longestStreak, currentRun)
        return longestStreak
    }
    
    /// 按日期范围获取每日饮水总量
    func dailyAmounts(from startDate: Date, to endDate: Date) -> [(date: Date, amount: Int)] {
        let calendar = Calendar.current
        var result: [(date: Date, amount: Int)] = []
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        while currentDate <= endDay {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let dayTotal = items
                .filter { $0.createdAt >= currentDate && $0.createdAt < nextDay }
                .reduce(0) { $0 + $1.amount }
            result.append((currentDate, dayTotal))
            currentDate = nextDay
        }
        
        return result
    }
    
    // MARK: - Persistence
    
    func save() {
        saveWorkItem?.cancel()
        // 快照当前数据，避免在并发块中捕获 self
        let itemsSnapshot = items
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave(items: itemsSnapshot)
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func performSave(items: [WaterRecordModel]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: Self.storeURL)
        } catch {
            print("[WaterRecordStore] Save error: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: Self.storeURL)
            let decodedItems = try JSONDecoder().decode([WaterRecordModel].self, from: data)
            self.items = decodedItems
        } catch {
            print("[WaterRecordStore] Load error: \(error)")
        }
    }
    
    /// 清空所有记录（供设置页面重置数据使用）
    func deleteAllRecords() {
        items.removeAll()
        save()
    }
}
