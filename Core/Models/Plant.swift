// Plant.swift
// 当前植物模型 —— 用户正在养的那一株生命

import Foundation

struct Plant: Identifiable, Codable {
    let id: UUID
    var name: String                 // 用户起的名字（情感依恋）
    var speciesID: String            // 品种 id → PlantSpecies
    var stage: GrowthStage           // 当前成长阶段
    var growthPoints: Double         // 成长值（累积达标推进阶段）
    var health: Double               // 健康度 0–100
    var plantedAt: Date              // 种下时间
    var lastWateredAt: Date?         // 最近一次喝水时间
    var isHarvested: Bool            // 是否已收获（入花园后变 true）
    var isPaused: Bool               // 是否暂停养护（出差/旅游模式）
    var pausedAt: Date?              // 暂停时间
    /// 最近一次升级阶段的时间（用于实现"每天最多升一级"）
    var lastStageUpAt: Date?

    init(
        id: UUID = UUID(),
        name: String = "小绿",
        speciesID: String = PlantSpecies.sunflower.id,
        stage: GrowthStage = .seed,
        growthPoints: Double = 0,
        health: Double = 70,
        plantedAt: Date = Date(),
        lastWateredAt: Date? = nil,
        isHarvested: Bool = false,
        isPaused: Bool = false,
        pausedAt: Date? = nil,
        lastStageUpAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.speciesID = speciesID
        self.stage = stage
        self.growthPoints = growthPoints
        self.health = health
        self.plantedAt = plantedAt
        self.lastWateredAt = lastWateredAt
        self.isHarvested = isHarvested
        self.isPaused = isPaused
        self.pausedAt = pausedAt
        self.lastStageUpAt = lastStageUpAt
    }

    // MARK: - 便捷访问

    var species: PlantSpecies { PlantLibrary.species(id: speciesID) }

    /// 是否还活着（健康度 > 0）
    var isAlive: Bool { health > 0 }

    /// 是否蔫了（当天没达标的表现，健康度偏低）
    var isWilting: Bool { health < 50 }

    /// 是否可以收获
    var canHarvest: Bool { stage == .harvestable && !isHarvested }

    /// 种植天数
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: plantedAt, to: Date()).day ?? 0
    }
    
    /// 暂停剩余天数（最长 14 天）
    var remainingPauseDays: Int {
        guard isPaused, let pausedAt = pausedAt else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: pausedAt, to: Date()).day ?? 0
        return max(0, 14 - elapsed)
    }
    
    /// 暂停是否已过期（超过 14 天自动恢复）
    var isPauseExpired: Bool {
        guard isPaused, let pausedAt = pausedAt else { return false }
        let elapsed = Calendar.current.dateComponents([.day], from: pausedAt, to: Date()).day ?? 0
        return elapsed >= 14
    }
}

// MARK: - 数据验证

extension Plant: Validatable {
    func validate() throws {
        // 植物名字不能为空
        guard !name.isEmpty else {
            throw PersistenceError.validationFailed("Plant", "Name cannot be empty")
        }
        
        // 健康值必须在 0-100 范围内
        guard health >= 0.0 && health <= 100.0 else {
            throw PersistenceError.validationFailed(
                "Plant",
                "Invalid health: \(health) (must be 0-100)"
            )
        }
        
        // 成长点数不能为负
        guard growthPoints >= 0 else {
            throw PersistenceError.validationFailed(
                "Plant",
                "Negative growth points: \(growthPoints)"
            )
        }
        
        // 种植时间不能是未来
        guard plantedAt <= Date() else {
            throw PersistenceError.validationFailed(
                "Plant",
                "Future planted date: \(plantedAt)"
            )
        }
        
        // 暂停时间不能早于种植时间
        if let pausedAt = pausedAt {
            guard pausedAt >= plantedAt else {
                throw PersistenceError.validationFailed(
                    "Plant",
                    "pausedAt (\(pausedAt)) is before plantedAt (\(plantedAt))"
                )
            }
        }
    }
}
