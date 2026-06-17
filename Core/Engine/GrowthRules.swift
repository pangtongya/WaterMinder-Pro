// GrowthRules.swift
// 成长值规则 —— 纯函数，可单测
//
// 设计哲学：成长值 growthPoints 累积到阈值就推进成长阶段。
// 用户每次喝水都贡献成长值；当天达标额外奖励。

import Foundation

enum GrowthRules {
    /// 每升水贡献的成长值（喝水即时反馈）
    static let growthPerLiter: Double = 4.0

    /// 当天达标额外奖励的成长值
    static let dailyGoalBonus: Double = 6.0

    /// 各阶段的成长值阈值（累积超过即进入下一阶段）
    /// 种子→发芽→幼苗→成株→含苞→盛开，共需约 30 累积点
    static let stageThresholds: [GrowthStage: Double] = [
        .seed:        0,
        .sprout:      3,
        .seedling:    8,
        .mature:     15,
        .blooming:   22,
        .harvestable: 30
    ]

    // MARK: - 成长值计算

    /// 某次喝水贡献的成长值
    static func growthFromWater(amount: Int) -> Double {
        Double(amount) / 1000.0 * growthPerLiter
    }

    /// 当天达标的额外奖励（直接用 dailyGoalBonus 常量）

    // MARK: - 阶段推进

    /// 根据累积成长值判断应处的阶段
    static func stageFor(growthPoints: Double) -> GrowthStage {
        var result: GrowthStage = .seed
        for stage in GrowthStage.allCases {
            if let threshold = stageThresholds[stage], growthPoints >= threshold {
                result = stage
            }
        }
        return result
    }

    /// 判断阶段是否应推进（当前阶段 vs 成长值对应的阶段）
    static func shouldAdvance(current: GrowthStage, growthPoints: Double) -> Bool {
        stageFor(growthPoints: growthPoints).rawValue > current.rawValue
    }

    // MARK: - 成长进度（UI 展示用）

    /// 当前阶段的下一阶段（nil 表示已经是最高阶段）
    static func nextStage(after stage: GrowthStage) -> GrowthStage? {
        stage.next
    }

    /// 当前成长值在"当前阶段→下一阶段"之间的进度比例（0.0–1.0）
    /// 如果已是最高阶段，返回 1.0
    static func progressToNextStage(currentStage: GrowthStage, growthPoints: Double) -> Double {
        guard let next = nextStage(after: currentStage),
              let currentThreshold = stageThresholds[currentStage],
              let nextThreshold = stageThresholds[next] else {
            return 1.0
        }
        let span = nextThreshold - currentThreshold
        guard span > 0 else { return 1.0 }
        let progress = (growthPoints - currentThreshold) / span
        return min(max(progress, 0), 1.0)
    }

    /// 距离下一阶段还差多少成长值
    static func pointsToNextStage(currentStage: GrowthStage, growthPoints: Double) -> Double? {
        guard let next = nextStage(after: currentStage),
              let nextThreshold = stageThresholds[next] else {
            return nil  // 已满级
        }
        return max(nextThreshold - growthPoints, 0)
    }
}
