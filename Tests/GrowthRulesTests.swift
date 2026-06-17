// GrowthRulesTests.swift
// 成长值规则单测 —— 验证阶段推进逻辑

import XCTest
@testable import Bloom

final class GrowthRulesTests: XCTestCase {

    // MARK: - 喝水贡献成长值

    func test喝水贡献成长值() {
        // 500ml → 0.5L × 4 = 2.0
        XCTAssertEqual(GrowthRules.growthFromWater(amount: 500), 2.0, accuracy: 0.01)
    }

    func test达标额外奖励() {
        XCTAssertEqual(GrowthRules.dailyGoalBonus, 6.0, accuracy: 0.01)
    }

    // MARK: - 阶段推进

    func test初始成长值是种子() {
        XCTAssertEqual(GrowthRules.stageFor(growthPoints: 0), .seed)
    }

    func test成长值3进入发芽() {
        XCTAssertEqual(GrowthRules.stageFor(growthPoints: 3), .sprout)
    }

    func test成长值15进入成株() {
        XCTAssertEqual(GrowthRules.stageFor(growthPoints: 15), .mature)
    }

    func test成长值30进入盛开() {
        XCTAssertEqual(GrowthRules.stageFor(growthPoints: 30), .harvestable)
    }

    // MARK: - 是否应推进

    func test阶段应推进() {
        XCTAssertTrue(GrowthRules.shouldAdvance(current: .seed, growthPoints: 5))
    }

    func test阶段不应倒退() {
        XCTAssertFalse(GrowthRules.shouldAdvance(current: .mature, growthPoints: 5))
    }
}
