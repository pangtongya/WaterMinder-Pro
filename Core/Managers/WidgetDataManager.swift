// WidgetDataManager.swift
// Widget 数据管理器 —— 通过 App Group 共享数据给 Widget

import Foundation

@MainActor
final class WidgetDataManager {
    
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = "group.com.pangtong.bloom"
    private var defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - 更新 Widget 数据
    
    /// 更新 Widget 显示的数据
    func updateWidgetData(
        currentIntake: Int,
        dailyGoal: Int,
        plantName: String,
        plantHealth: Double,
        plantStage: String,
        plantSymbol: String,
        isPaused: Bool
    ) {
        guard let defaults = defaults else {
            print("[WidgetDataManager] App Group not available")
            return
        }
        
        defaults.set(currentIntake, forKey: "widget.todayIntake")
        defaults.set(dailyGoal, forKey: "widget.dailyGoal")
        defaults.set(plantName, forKey: "widget.plantName")
        defaults.set(plantHealth, forKey: "widget.plantHealth")
        defaults.set(plantStage, forKey: "widget.plantStage")
        defaults.set(plantSymbol, forKey: "widget.plantSymbol")
        defaults.set(isPaused, forKey: "widget.isPaused")
        defaults.set(Date(), forKey: "widget.lastUpdated")
        
        // 强制同步
        defaults.synchronize()
    }
    
    /// 清除 Widget 数据
    func clearWidgetData() {
        guard let defaults = defaults else { return }
        
        let keys = [
            "widget.todayIntake",
            "widget.dailyGoal",
            "widget.plantName",
            "widget.plantHealth",
            "widget.plantStage",
            "widget.plantSymbol",
            "widget.isPaused",
            "widget.lastUpdated"
        ]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}
