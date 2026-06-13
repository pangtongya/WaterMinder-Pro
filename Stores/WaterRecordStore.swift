// WaterRecordStore.swift
// 喝水记录数据管理

import Foundation
import SwiftUI

@MainActor
class WaterRecordStore: ObservableObject {
    @Published var items: [WaterRecordModel] = []
    
    private var saveWorkItem: DispatchWorkItem?
    
    private static let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("water_records.json")
    }()
    
    init() {
        load()
    }
    
    // MARK: - CRUD
    
    func addRecord(amount: Int, cupType: CupType = .medium, note: String? = nil) -> WaterRecordModel {
        let record = WaterRecordModel(
            amount: amount,
            cupType: cupType,
            note: note
        )
        items.insert(record, at: 0) // 新记录插入到开头
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
        guard let appState = try? getAppState() else { return 0.0 }
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
    
    // MARK: - Helper Methods
    
    private func getAppState() throws -> AppState {
        // 通过 NotificationCenter 或其他方式获取 AppState
        // 这里简单返回 shared instance
        AppState.shared
    }
    
    // MARK: - Persistence
    
    func save() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func performSave() {
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
            items = try JSONDecoder().decode([WaterRecordModel].self, from: data)
        } catch {
            items = []
            print("[WaterRecordStore] Load error: \(error)")
        }
    }
}
