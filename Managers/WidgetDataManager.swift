// WidgetDataManager.swift
// Widget 数据同步管理

import Foundation
import WidgetKit

final class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private init() {}
    
    func updateWidgetData(
        progress: Double,
        totalAmount: Int,
        goal: Int,
        streakDays: Int
    ) {
        guard let defaults = UserDefaults(suiteName: "group.com.pangtong.waterminder") else {
            print("[WidgetDataManager] Warning: App Group suite not available, will retry next time")
            return
        }
        
        defaults.set(progress, forKey: "todayProgress")
        defaults.set(totalAmount, forKey: "todayTotalAmount")
        defaults.set(goal, forKey: "dailyGoal")
        defaults.set(streakDays, forKey: "currentStreak")
        
        // 刷新 Widget
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "WaterMinderWidget")
        }
    }
}
