// PlantLifecycle.swift
// 生命周期编排 —— 把健康度、成长值、阶段推进串成完整流程
//
// 设计原则：
// - 纯函数：接收"旧状态+输入"，返回"新状态"，无副作用
// - 状态层（PlantEngine）负责持久化，本层只做计算
// - 阶段升级统一走 advanceStageIfPossible()，保证"每天最多升一级"

import Foundation

enum PlantLifecycle {
    // MARK: - 喝水（核心即时反馈）

    /// 用户喝了一口水后，植物的新状态
    /// - 每次喝水：健康度恢复 + 成长值 + 触发一次阶段检查（可能升级）
    static func applyWatering(_ plant: Plant, amount: Int) -> Plant {
        var p = plant
        p.health = HealthCalculator.applyWater(currentHealth: p.health, amount: amount)
        p.growthPoints += GrowthRules.growthFromWater(amount: amount)
        p.lastWateredAt = Date()
        return advanceStageIfPossible(p)
    }

    /// 用户删除了一条喝水记录，回退植物状态
    /// - 减少对应健康度与成长值，不触发阶段升级（可能降级）
    static func revertWatering(_ plant: Plant, amount: Int) -> Plant {
        var p = plant
        // 健康度回退（下限 0）
        p.health = max(0, p.health - HealthCalculator.healthFromWater(amount: amount))
        // 成长值回退（下限 0）
        p.growthPoints = max(0, p.growthPoints - GrowthRules.growthFromWater(amount: amount))
        // 根据当前成长值重新判断阶段（可能降级）
        let targetStage = GrowthRules.stageFor(growthPoints: p.growthPoints)
        if targetStage.rawValue < p.stage.rawValue {
            p.stage = targetStage
        }
        return p
    }

    // MARK: - 当天达标结算

    /// 当天饮水达标时，给予额外奖励
    /// - 额外成长值 + 阶段检查（可能升级）
    static func applyDailyGoalMet(_ plant: Plant) -> Plant {
        var p = plant
        p.health = HealthCalculator.applyGoalMet(currentHealth: p.health)
        p.growthPoints += GrowthRules.dailyGoalBonus
        return advanceStageIfPossible(p)
    }

    // MARK: - 每日断水结算

    /// 某天结束时未达标，应用衰减
    /// 如果植物处于暂停状态，不应用衰减
    static func applyDailyDecay(_ plant: Plant, consecutiveMissedDays: Int) -> Plant {
        guard !plant.isPaused else { return plant }

        var p = plant
        p.health = HealthCalculator.applyDailyDecay(
            currentHealth: p.health,
            consecutiveMissedDays: consecutiveMissedDays,
            plantedAt: p.plantedAt
        )
        return p
    }

    // MARK: - 阶段升级（统一入口，含每日上限）

    /// 根据当前成长值判断是否应升级阶段
    /// 每天最多触发一次升级（检查 lastStageUpAt），避免同一天连续弹两次庆祝弹窗
    /// - 成长值已经累积，只是不在当天立即生效 —— 下一天打开 App 仍然会升级
    static func advanceStageIfPossible(_ plant: Plant) -> Plant {
        var p = plant
        let current = p.stage
        let target = GrowthRules.stageFor(growthPoints: p.growthPoints)

        // 1. 没有可升的阶段
        guard target.rawValue > current.rawValue else { return p }

        // 2. 今天已经升过一级了 → 保留成长值，下次再触发
        if let lastUp = p.lastStageUpAt,
           Calendar.current.isDate(lastUp, inSameDayAs: Date()) {
            return p
        }

        // 3. 执行升级，并记录时间戳
        p.stage = target
        p.lastStageUpAt = Date()
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
        p.isPaused = false
        p.pausedAt = nil
        p.lastStageUpAt = nil       // 枯萎后清除升级记录
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
        var reset = plant
        reset.health = 70
        reset.stage = .seed
        reset.growthPoints = 0
        reset.plantedAt = Date()
        reset.lastWateredAt = nil
        reset.isHarvested = false
        reset.isPaused = false
        reset.pausedAt = nil
        reset.lastStageUpAt = nil   // 收获后清除升级记录
        return (item, reset)
    }
}
