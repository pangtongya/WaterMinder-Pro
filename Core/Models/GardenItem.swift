// GardenItem.swift
// 花园藏品 —— 成熟收获后存入"我的花园"的纪念

import Foundation

struct GardenItem: Identifiable, Codable, Hashable {
    let id: UUID
    let speciesID: String
    let name: String              // 当时的名字
    let plantedAt: Date
    let harvestedAt: Date
    let peakStage: GrowthStage    // 收获时的阶段
    let daysToHarvest: Int        // 从种下到收获的天数

    init(
        id: UUID = UUID(),
        speciesID: String,
        name: String,
        plantedAt: Date,
        harvestedAt: Date = Date(),
        peakStage: GrowthStage = .harvestable,
        daysToHarvest: Int
    ) {
        self.id = id
        self.speciesID = speciesID
        self.name = name
        self.plantedAt = plantedAt
        self.harvestedAt = harvestedAt
        self.peakStage = peakStage
        self.daysToHarvest = daysToHarvest
    }

    var species: PlantSpecies { PlantLibrary.species(id: speciesID) }
}

// MARK: - 数据验证

extension GardenItem: Validatable {
    func validate() throws {
        // 名字不能为空
        guard !name.isEmpty else {
            throw PersistenceError.validationFailed("GardenItem", "Name cannot be empty")
        }
        
        // 收获时间不能早于种植时间
        guard harvestedAt >= plantedAt else {
            throw PersistenceError.validationFailed(
                "GardenItem",
                "harvestedAt (\(harvestedAt)) is before plantedAt (\(plantedAt))"
            )
        }
        
        // 收获天数不能为负
        guard daysToHarvest >= 0 else {
            throw PersistenceError.validationFailed(
                "GardenItem",
                "Negative days to harvest: \(daysToHarvest)"
            )
        }
        
        // 收获时间不能是未来（允许 1 分钟误差）
        guard harvestedAt <= Date().addingTimeInterval(60) else {
            throw PersistenceError.validationFailed(
                "GardenItem",
                "Future harvest date: \(harvestedAt)"
            )
        }
    }
}
