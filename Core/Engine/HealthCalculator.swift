// HealthCalculator.swift
// 健康度算法 —— 纯函数，可单测
//
// 设计哲学（温和枯萎）：
// - 当天达标 → 健康度回升/满血（即时正反馈）
// - 当天未达标 → 衰减，但远不到死（愧疚感够强但不伤感情）
// - 连续断水 → 持续恶化，归零才真正枯萎
// 补水就能立刻恢复生机，所以用户不会因怕死而卸载，却会因怕蔫而喝水。

import Foundation

enum HealthCalculator {
    /// 健康度上限
    static let maxHealth: Double = 100
    /// 健康度下限
    static let minHealth: Double = 0

    /// 喝一口水即时恢复的健康度（每升）
    static let healPerLiter: Double = 8.0

    /// 当天达标额外恢复
    static let goalMetHealBonus: Double = 20.0

    /// 当天未达标的衰减（蔫一下，但不致命）
    static let dailyDecay: Double = 15.0

    // MARK: - 喝水即时恢复

    /// 某次喝水后健康度应恢复多少
    static func healthFromWater(amount: Int) -> Double {
        Double(amount) / 1000.0 * healPerLiter
    }

    /// 应用喝水后的健康度（封顶 100）
    static func applyWater(currentHealth: Double, amount: Int) -> Double {
        min(currentHealth + healthFromWater(amount: amount), maxHealth)
    }

    /// 当天达标时的健康度（直接拉满，即时正反馈）
    static func applyGoalMet(currentHealth: Double) -> Double {
        min(currentHealth + goalMetHealBonus, maxHealth)
    }

    // MARK: - 每日结算衰减

    /// 某天未达标时健康度的衰减结果
    static func applyDailyDecay(currentHealth: Double, missedDays: Int) -> Double {
        // 连续断水天数越多，衰减越重（温和但累积）
        // 第1天 -15，第2天再 -15...线性叠加，归零即枯萎
        let totalDecay = dailyDecay * Double(missedDays)
        return max(currentHealth - totalDecay, minHealth)
    }

    // MARK: - 状态判断

    /// 健康度对应的生命状态文案
    static func statusMessage(_ health: Double) -> String {
        switch health {
        case ..<25:  return "它快要枯萎了……快救救它"
        case ..<50:  return "它有点蔫了，需要喝水"
        case ..<80:  return "它状态还行"
        default:     return "它生机勃勃！"
        }
    }
}
