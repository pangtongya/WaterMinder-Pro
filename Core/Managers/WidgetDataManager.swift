// WidgetDataManager.swift
// Widget 数据管理器 —— 通过 App Group 共享数据给 Widget

import Foundation

@MainActor
final class WidgetDataManager {
    
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = AppConstants.appGroupIdentifier
    private var defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - 更新 Widget 数据
    
    /// 更新 Widget 显示的数据
    /// - Note: plantStageRawValue 传递 GrowthStage 的 rawValue (Int)，Widget 会自动本地化
    func updateWidgetData(
        currentIntake: Int,
        dailyGoal: Int,
        plantName: String,
        plantHealth: Double,
        plantStageRawValue: Int,
        plantSymbol: String,
        isPaused: Bool
    ) {
        guard let defaults = defaults else {
            print("[WidgetDataManager] App Group not available")
            return
        }
        
        defaults.set(currentIntake, forKey: AppConstants.WidgetKeys.todayIntake)
        defaults.set(dailyGoal, forKey: AppConstants.WidgetKeys.dailyGoal)
        defaults.set(plantName, forKey: AppConstants.WidgetKeys.plantName)
        defaults.set(plantHealth, forKey: AppConstants.WidgetKeys.plantHealth)
        defaults.set(plantStageRawValue, forKey: AppConstants.WidgetKeys.plantStageRawValue)
        defaults.set(plantSymbol, forKey: AppConstants.WidgetKeys.plantSymbol)
        defaults.set(isPaused, forKey: AppConstants.WidgetKeys.isPaused)
        defaults.set(Date(), forKey: AppConstants.WidgetKeys.lastUpdated)
        
        // 同时保存本地化的阶段名称（供 Widget 直接读取）
        let localizedStage = GrowthStage(rawValue: plantStageRawValue)?.name ?? "Seed"
        defaults.set(localizedStage, forKey: AppConstants.WidgetKeys.plantStage)
        
        // 强制同步
        defaults.synchronize()
    }
    
    /// 清除 Widget 数据
    func clearWidgetData() {
        guard let defaults = defaults else { return }
        
        let keys = [
            AppConstants.WidgetKeys.todayIntake,
            AppConstants.WidgetKeys.dailyGoal,
            AppConstants.WidgetKeys.plantName,
            AppConstants.WidgetKeys.plantHealth,
            AppConstants.WidgetKeys.plantStageRawValue,
            AppConstants.WidgetKeys.plantSymbol,
            AppConstants.WidgetKeys.isPaused,
            AppConstants.WidgetKeys.lastUpdated
        ]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}
