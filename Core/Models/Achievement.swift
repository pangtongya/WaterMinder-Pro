// Achievement.swift
// 成就系统 —— 激励用户坚持喝水养植物

import Foundation

// MARK: - 成就定义

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    var requirement: Int  // 完成条件（如喝水次数、天数等）
    var unlockedAt: Date?
    var progress: Int     // 当前进度
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
    
    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        unlockedAt: Date? = nil,
        progress: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.unlockedAt = unlockedAt
        self.progress = progress
    }
}

// MARK: - 成就分类

enum AchievementCategory: String, Codable, CaseIterable {
    case hydration = "喝水达人"
    case streak = "坚持不懈"
    case garden = "花园大师"
    case social = "社交分享"
    case milestone = "重要里程碑"
    
    var color: String {
        switch self {
        case .hydration: return "blue"
        case .streak: return "green"
        case .garden: return "orange"
        case .social: return "purple"
        case .milestone: return "gold"
        }
    }
}

// MARK: - 成就库

enum AchievementLibrary {
    
    /// 获取所有成就定义
    static func allAchievements() -> [Achievement] {
        return [
            // 喝水达人系列
            Achievement(
                id: "hydration_first",
                title: "第一口水",
                description: "完成第一次喝水记录",
                icon: "drop.fill",
                category: .hydration,
                requirement: 1
            ),
            Achievement(
                id: "hydration_10",
                title: "初入门径",
                description: "累计喝水10次",
                icon: "drop.fill",
                category: .hydration,
                requirement: 10
            ),
            Achievement(
                id: "hydration_50",
                title: "饮水习惯",
                description: "累计喝水50次",
                icon: "cup.and.saucer.fill",
                category: .hydration,
                requirement: 50
            ),
            Achievement(
                id: "hydration_100",
                title: "百杯成就",
                description: "累计喝水100次",
                icon: "mug.fill",
                category: .hydration,
                requirement: 100
            ),
            Achievement(
                id: "hydration_500",
                title: "喝水大师",
                description: "累计喝水500次",
                icon: "waterbottle.fill",
                category: .hydration,
                requirement: 500
            ),
            Achievement(
                id: "hydration_1000",
                title: "千杯不醉",
                description: "累计喝水1000次",
                icon: "sparkles",
                category: .hydration,
                requirement: 1000
            ),
            
            // 坚持不懈系列
            Achievement(
                id: "streak_3",
                title: "三日坚持",
                description: "连续3天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 3
            ),
            Achievement(
                id: "streak_7",
                title: "一周达人",
                description: "连续7天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 7
            ),
            Achievement(
                id: "streak_14",
                title: "两周习惯",
                description: "连续14天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 14
            ),
            Achievement(
                id: "streak_30",
                title: "月度挑战",
                description: "连续30天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                requirement: 30
            ),
            Achievement(
                id: "streak_60",
                title: "双月坚守",
                description: "连续60天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                requirement: 60
            ),
            Achievement(
                id: "streak_100",
                title: "百日筑基",
                description: "连续100天完成喝水目标",
                icon: "crown.fill",
                category: .streak,
                requirement: 100
            ),
            
            // 花园大师系列
            Achievement(
                id: "garden_first_harvest",
                title: "首次收获",
                description: "第一次收获植物到花园",
                icon: "leaf.fill",
                category: .garden,
                requirement: 1
            ),
            Achievement(
                id: "garden_5_harvests",
                title: "花园新手",
                description: "累计收获5次",
                icon: "leaf.fill",
                category: .garden,
                requirement: 5
            ),
            Achievement(
                id: "garden_10_harvests",
                title: "园丁认证",
                description: "累计收获10次",
                icon: "tree.fill",
                category: .garden,
                requirement: 10
            ),
            Achievement(
                id: "garden_25_harvests",
                title: "花园大师",
                description: "累计收获25次",
                icon: "flower.fill",
                category: .garden,
                requirement: 25
            ),
            Achievement(
                id: "garden_50_harvests",
                title: "传奇园丁",
                description: "累计收获50次",
                icon: "sparkles",
                category: .garden,
                requirement: 50
            ),
            Achievement(
                id: "garden_5_species",
                title: "品种收集家",
                description: "收集5种不同植物品种",
                icon: "leaf.fill",
                category: .garden,
                requirement: 5
            ),
            Achievement(
                id: "garden_10_species",
                title: "植物学家",
                description: "收集10种不同植物品种",
                icon: "tree.fill",
                category: .garden,
                requirement: 10
            ),
            Achievement(
                id: "garden_all_species",
                title: "全品种大师",
                description: "收集所有植物品种",
                icon: "crown.fill",
                category: .garden,
                requirement: PlantLibrary.all.count
            ),
            
            // 社交分享系列
            Achievement(
                id: "social_first_share",
                title: "初次分享",
                description: "第一次分享植物状态",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: 1
            ),
            Achievement(
                id: "social_10_shares",
                title: "社交达人",
                description: "累计分享10次",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: 10
            ),
            
            // 重要里程碑
            Achievement(
                id: "milestone_10000ml",
                title: "万水千山",
                description: "累计喝水10000ml",
                icon: "drop.fill",
                category: .milestone,
                requirement: 10000
            ),
            Achievement(
                id: "milestone_50000ml",
                title: "五万成就",
                description: "累计喝水50000ml",
                icon: "sparkles",
                category: .milestone,
                requirement: 50000
            ),
            Achievement(
                id: "milestone_100000ml",
                title: "十万喝水王",
                description: "累计喝水100000ml",
                icon: "crown.fill",
                category: .milestone,
                requirement: 100000
            ),
        ]
    }
    
    /// 获取某个分类的成就
    static func achievements(for category: AchievementCategory) -> [Achievement] {
        return allAchievements().filter { $0.category == category }
    }
}
