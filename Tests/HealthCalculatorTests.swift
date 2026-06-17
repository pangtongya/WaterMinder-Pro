// HealthCalculatorTests.swift
// 健康度算法单测 —— 验证"温和枯萎"机制的正确性

import XCTest
@testable import Bloom

final class HealthCalculatorTests: XCTestCase {

    // MARK: - 喝水恢复

    func test喝水后健康度上升() {
        let result = HealthCalculator.applyWater(currentHealth: 50, amount: 250)
        // 250ml → 0.25L × 8 = +2
        XCTAssertEqual(result, 52, accuracy: 0.01)
    }

    func test喝水不超过100() {
        let result = HealthCalculator.applyWater(currentHealth: 95, amount: 1000)
        XCTAssertEqual(result, 100, accuracy: 0.01)
    }

    func test达标直接拉满或大幅回升() {
        let result = HealthCalculator.applyGoalMet(currentHealth: 40)
        // +20 = 60（不封顶到100，给累积空间）
        XCTAssertEqual(result, 60, accuracy: 0.01)
    }

    // MARK: - 衰减

    func test断水1天衰减15() {
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, missedDays: 1)
        XCTAssertEqual(result, 65, accuracy: 0.01)
    }

    func test断水3天衰减45() {
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, missedDays: 3)
        XCTAssertEqual(result, 35, accuracy: 0.01)
    }

    func test健康度不低于0() {
        let result = HealthCalculator.applyDailyDecay(currentHealth: 10, missedDays: 5)
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    // MARK: - 状态文案

    func test状态文案分段() {
        XCTAssertFalse(HealthCalculator.statusMessage(10).isEmpty)
        XCTAssertTrue(HealthCalculator.statusMessage(30).contains("蔫"))
        XCTAssertTrue(HealthCalculator.statusMessage(90).contains("生机"))
    }
}
