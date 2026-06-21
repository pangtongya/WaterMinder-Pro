// HealthCalculatorTests.swift
// 健康度算法单测 —— 验证"温和枯萎"机制的正确性
// 新温柔衰减曲线：
//   Day 1 miss → -5
//   Day 2 miss → -15 (cumulative)
//   Day 3+ miss → -30, -45, -60 ... per day
//   新手保护期（48h内）→ 0 衰减

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

    // MARK: - 温柔衰减曲线（decayForDays 纯函数）

    func test断水1天衰减5() {
        XCTAssertEqual(HealthCalculator.decayForDays(1), 5, accuracy: 0.01)
    }

    func test断水2天累积衰减15() {
        XCTAssertEqual(HealthCalculator.decayForDays(2), 15, accuracy: 0.01)
    }

    func test断水3天累积衰减30() {
        XCTAssertEqual(HealthCalculator.decayForDays(3), 30, accuracy: 0.01)
    }

    func test断水7天累积衰减90() {
        // 5 + 10 + 15*5 = 5 + 10 + 75 = 90
        XCTAssertEqual(HealthCalculator.decayForDays(7), 90, accuracy: 0.01)
    }

    func test断水0天无衰减() {
        XCTAssertEqual(HealthCalculator.decayForDays(0), 0, accuracy: 0.01)
    }

    // MARK: - 每日结算衰减（applyDailyDecay，含新手保护期）

    func test断水1天实际衰减5() {
        // 48h 前种下 → 超出保护期
        let planted = Calendar.current.date(byAdding: .hour, value: -49, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 1, plantedAt: planted)
        XCTAssertEqual(result, 75, accuracy: 0.01)
    }

    func test断水2天实际累积衰减15() {
        let planted = Calendar.current.date(byAdding: .hour, value: -72, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 2, plantedAt: planted)
        XCTAssertEqual(result, 65, accuracy: 0.01)
    }

    func test断水3天实际累积衰减30() {
        let planted = Calendar.current.date(byAdding: .hour, value: -72, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 3, plantedAt: planted)
        XCTAssertEqual(result, 50, accuracy: 0.01)
    }

    // MARK: - 新手保护期

    func test新手48小时内断水不衰减() {
        // 刚种下30分钟 → 仍在保护期
        let planted = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 7, plantedAt: planted)
        XCTAssertEqual(result, 80, accuracy: 0.01) // 健康度不变
    }

    func test刚好48小时开始衰减() {
        // 刚好 48 小时：gracePeriodEnd == Date()，所以 Date() < gracePeriodEnd 为 false
        let planted = Calendar.current.date(byAdding: .second, value: -48 * 60 * 60, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 1, plantedAt: planted)
        XCTAssertEqual(result, 75, accuracy: 0.01) // 开始衰减
    }

    func test超过48小时开始衰减() {
        let planted = Calendar.current.date(byAdding: .hour, value: -49, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 80, consecutiveMissedDays: 1, plantedAt: planted)
        XCTAssertEqual(result, 75, accuracy: 0.01)
    }

    // MARK: - 边界条件

    func test健康度不低于0() {
        let planted = Calendar.current.date(byAdding: .hour, value: -72, to: Date())!
        let result = HealthCalculator.applyDailyDecay(currentHealth: 10, consecutiveMissedDays: 5, plantedAt: planted)
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    // MARK: - 状态文案

    func test状态文案分段() {
        XCTAssertFalse(HealthCalculator.statusMessage(10).isEmpty)
        XCTAssertTrue(HealthCalculator.statusMessage(30).contains("蔫"))
        XCTAssertTrue(HealthCalculator.statusMessage(90).contains("生机"))
    }
}
