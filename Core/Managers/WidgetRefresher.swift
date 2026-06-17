// WidgetRefresher.swift
// Widget 数据刷新器 —— 集中管理所有需要更新Widget的场景

import Foundation

@MainActor
final class WidgetRefresher {
    
    static let shared = WidgetRefresher()
    
    private init() {}
    
    /// 刷新 Widget 数据
    func refresh(
        waterStore: WaterStore,
        userStore: UserStore,
        plantEngine: PlantEngine
    ) {
        let plant = plantEngine.plant
        let species = plant.species
        
        WidgetDataManager.shared.updateWidgetData(
            currentIntake: waterStore.todayTotal,
            dailyGoal: userStore.dailyGoal,
            plantName: plant.name,
            plantHealth: plant.health,
            plantStage: plant.stage.name,
            plantSymbol: species.symbol,
            isPaused: plant.isPaused
        )
    }
    
    /// 异步刷新（用于异步上下文）
    func refreshAsync(
        waterStore: WaterStore,
        userStore: UserStore,
        plantEngine: PlantEngine
    ) {
        Task { @MainActor in
            refresh(
                waterStore: waterStore,
                userStore: userStore,
                plantEngine: plantEngine
            )
        }
    }
}
