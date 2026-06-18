// HealthCalculator.swift
// 健康度算法 —— 纯函数，可单测
//
// 设计哲学（温和枯萎 + 温柔衰减曲线）：
// - 当天达标 → 健康度回升/满血（即时正反馈）
// - 断水第1天 → -5（温柔提醒，不伤感情）
// - 断水第2天 → -10（开始焦虑，但还有救）
// - 断水第3天+ → 每天 -15（持续恶化，归零才真正枯萎）
// - 新手保护期（种下48小时内）→ 不触发衰减
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

    // MARK: - 温柔衰减曲线（每日结算）
    //
    // Day 1 miss: -5   (gentle nudge)
    // Day 2 miss: -10  (growing concern)
    // Day 3+ miss: -15/day (serious but survivable)
    //
    // Cumulative examples:
    //   1 day missed  → health -5   (barely noticeable)
    //   2 days missed → health -15  (starts to look wilted)
    //   3 days missed → health -30  (clearly needs attention)
    //   7 days missed → health -90  (critically low, but not dead)

    /// 断水第1天的衰减量（温柔提醒）
    private static let decayDay1: Double = 5.0
    /// 断水第2天的衰减量（引起注意）
    private static let decayDay2: Double = 10.0
    /// 断水第3天+每天的衰减量（持续恶化）
    private static let decayDay3Plus: Double = 15.0
    /// 新手保护期（小时数）：种下后48小时内不触发衰减
    static let newPlantGracePeriodHours: Int = 48

    /// 计算连续断水后的总衰减量
    static func decayForDays(_ missedDays: Int) -> Double {
        guard missedDays > 0 else { return 0 }
        switch missedDays {
        case 1:
            return decayDay1
        case 2:
            return decayDay1 + decayDay2
        default:
            return decayDay1 + decayDay2 + decayDay3Plus * Double(missedDays - 2)
        }
    }

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

    /// 某天未达标时健康度的衰减结果（温柔曲线版）
    /// - Parameters:
    ///   - currentHealth: 当前健康度
    ///   - missedDays: 连续断水天数
    ///   - plantedAt: 植物种下时间（用于新手保护期）
    static func applyDailyDecay(
        currentHealth: Double,
        consecutiveMissedDays: Int,
        plantedAt: Date = Date()
    ) -> Double {
        // 新手保护期：种下48小时内，即使断水也不衰减
        let gracePeriodEnd = Calendar.current.date(
            byAdding: .hour,
            value: newPlantGracePeriodHours,
            to: plantedAt
        ) ?? plantedAt
        if Date() < gracePeriodEnd {
            return currentHealth
        }
        let totalDecay = decayForDays(consecutiveMissedDays)
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
