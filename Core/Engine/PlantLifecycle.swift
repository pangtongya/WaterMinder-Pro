// PlantLifecycle.swift
// 生命周期编排 —— 把健康度、成长值、阶段推进串成完整流程
//
// 这是引擎层与状态层之间的桥梁：纯函数接收"旧状态+输入"，返回"新状态"。
// 状态层（PlantEngine / Stores）负责持久化，本层只做计算。

import Foundation

enum PlantLifecycle {
    // MARK: - 喝水（核心即时反馈）

    /// 用户喝了一口水后，植物的新状态
    static func applyWatering(_ plant: Plant, amount: Int) -> Plant {
        var p = plant
        p.health = HealthCalculator.applyWater(currentHealth: p.health, amount: amount)
        p.growthPoints += GrowthRules.growthFromWater(amount: amount)
        p.lastWateredAt = Date()

        // 成长值推进后，阶段自动升级
        let newStage = GrowthRules.stageFor(growthPoints: p.growthPoints)
        if newStage.rawValue > p.stage.rawValue {
            p.stage = newStage
        }
        return p
    }

    // MARK: - 当天达标结算

    /// 当天饮水达标时，给予额外奖励
    static func applyDailyGoalMet(_ plant: Plant) -> Plant {
        var p = plant
        p.health = HealthCalculator.applyGoalMet(currentHealth: p.health)
        p.growthPoints += GrowthRules.dailyGoalBonus

        let newStage = GrowthRules.stageFor(growthPoints: p.growthPoints)
        if newStage.rawValue > p.stage.rawValue {
            p.stage = newStage
        }
        return p
    }

    // MARK: - 每日断水结算

    /// 某天结束时未达标，应用衰减
    /// 如果植物处于暂停状态，不应用衰减
    static func applyDailyDecay(_ plant: Plant, consecutiveMissedDays: Int) -> Plant {
        // 暂停养护期间不衰减
        guard !plant.isPaused else {
            return plant
        }

        var p = plant
        p.health = HealthCalculator.applyDailyDecay(
            currentHealth: p.health,
            consecutiveMissedDays: consecutiveMissedDays,
            plantedAt: p.plantedAt
        )
        return p
    }

    // MARK: - 枯萎处理

    /// 健康度归零，植物枯萎 → 重置为一颗新种子（同一品种，保留名字）
    static func wilt(_ plant: Plant) -> Plant {
        var p = plant
        p.health = 60              // 给新生命一个温柔的开始
        p.stage = .seed
        p.growthPoints = 0
        p.plantedAt = Date()
        p.lastWateredAt = nil
        p.isPaused = false         // 枯萎后自动取消暂停
        p.pausedAt = nil
        return p
    }

    // MARK: - 收获

    /// 成熟收获 → 入花园（返回收获后的 garden item + 植物是否需要重置）
    static func harvest(_ plant: Plant) -> (gardenItem: GardenItem, resetPlant: Plant) {
        let item = GardenItem(
            speciesID: plant.speciesID,
            name: plant.name,
            plantedAt: plant.plantedAt,
            peakStage: plant.stage,
            daysToHarvest: plant.ageInDays
        )
        // 收获后重新种一株同品种新种子
        var reset = plant
        reset.health = 70
        reset.stage = .seed
        reset.growthPoints = 0
        reset.plantedAt = Date()
        reset.lastWateredAt = nil
        reset.isHarvested = false
        reset.isPaused = false     // 收获后取消暂停
        reset.pausedAt = nil
        return (item, reset)
    }
}
