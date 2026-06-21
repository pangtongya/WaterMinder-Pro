// PlantLifecycleTests.swift
// 生命周期编排单测 —— 验证喝水/达标/枯萎/收获流程

import XCTest
@testable import Bloom

final class PlantLifecycleTests: XCTestCase {

    // MARK: - 喝水

    func test喝水后健康度回升且成长值增加() {
        var plant = Plant(name: "小绿", growthPoints: 0, health: 50)
        plant = PlantLifecycle.applyWatering(plant, amount: 500)
        XCTAssertEqual(plant.health, 54, accuracy: 0.01)   // 50 + 4
        XCTAssertEqual(plant.growthPoints, 2.0, accuracy: 0.01) // 0.5L × 4
        XCTAssertNotNil(plant.lastWateredAt)
    }

    func test喝水推进成长阶段() {
        var plant = Plant(name: "小绿", growthPoints: 2, health: 80)
        // 喝 250ml → +1 → 累积 3 → 发芽
        plant = PlantLifecycle.applyWatering(plant, amount: 250)
        XCTAssertEqual(plant.stage, .sprout)
    }

    // MARK: - 达标

    func test达标提升健康度和成长值() {
        var plant = Plant(name: "小绿", growthPoints: 5, health: 40)
        plant = PlantLifecycle.applyDailyGoalMet(plant)
        XCTAssertEqual(plant.health, 60, accuracy: 0.01) // +20
        XCTAssertEqual(plant.growthPoints, 11, accuracy: 0.01) // +6
    }

    // MARK: - 枯萎

    func test断水后健康度衰减() {
        // plantedAt 必须超过 48 小时才能触发衰减
        let plantedAt = Calendar.current.date(byAdding: .hour, value: -72, to: Date())!
        var plant = Plant(name: "小绿", health: 80, plantedAt: plantedAt)
        plant = PlantLifecycle.applyDailyDecay(plant, consecutiveMissedDays: 2)
        // Day 1 miss: -5, Day 2 miss: -10 → cumulative -15
        XCTAssertEqual(plant.health, 65, accuracy: 0.01) // 80 - 15
    }

    func test枯萎后重置为新种子但保留名字() {
        let plant = Plant(name: "陪伴很久的", speciesID: "sunflower", health: 10)
        let wilted = PlantLifecycle.wilt(plant)
        XCTAssertEqual(wilted.name, "陪伴很久的")
        XCTAssertEqual(wilted.speciesID, "sunflower")
        XCTAssertEqual(wilted.stage, .seed)
        XCTAssertEqual(wilted.growthPoints, 0)
        XCTAssertEqual(wilted.health, 60, accuracy: 0.01)
    }

    // MARK: - 收获

    func test收获返回花园藏品并重置植物() {
        let plant = Plant(
            name: "成熟花",
            speciesID: "sunflower",
            stage: .harvestable,
            growthPoints: 30
        )
        let (item, reset) = PlantLifecycle.harvest(plant)
        XCTAssertEqual(item.speciesID, "sunflower")
        XCTAssertEqual(item.name, "成熟花")
        XCTAssertEqual(item.peakStage, .harvestable)
        XCTAssertEqual(reset.stage, .seed)
        XCTAssertEqual(reset.growthPoints, 0)
    }
}
