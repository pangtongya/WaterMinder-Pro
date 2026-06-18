// Achievement.swift
// 成就系统 —— 激励用户坚持喝水养植物

import Foundation

// MARK: - 成就定义

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let titleKey: String       // 本地化 key
    let descriptionKey: String // 本地化 key
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
    
    /// 获取本地化的标题
    var title: String {
        NSLocalizedString(titleKey, comment: titleKey)
    }
    
    /// 获取本地化的描述
    var description: String {
        NSLocalizedString(descriptionKey, comment: descriptionKey)
    }
    
    init(
        id: String,
        titleKey: String,
        descriptionKey: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        unlockedAt: Date? = nil,
        progress: Int = 0
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.unlockedAt = unlockedAt
        self.progress = progress
    }
}

// MARK: - 成就分类

enum AchievementCategory: String, Codable, CaseIterable {
    case hydration
    case streak
    case garden
    case social
    case milestone
    
    /// 本地化的分类名称 key
    var localizedKey: String {
        switch self {
        case .hydration: return "喝水达人"
        case .streak: return "坚持不懈"
        case .garden: return "花园大师"
        case .social: return "社交分享"
        case .milestone: return "重要里程碑"
        }
    }
    
    /// 本地化的分类名称
    var localizedName: String {
        NSLocalizedString(localizedKey, comment: localizedKey)
    }
    
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
                titleKey: "第一口水",
                descriptionKey: "完成第一次喝水记录",
                icon: "drop.fill",
                category: .hydration,
                requirement: 1
            ),
            Achievement(
                id: "hydration_10",
                titleKey: "初入门径",
                descriptionKey: "累计喝水10次",
                icon: "drop.fill",
                category: .hydration,
                requirement: 10
            ),
            Achievement(
                id: "hydration_50",
                titleKey: "饮水习惯",
                descriptionKey: "累计喝水50次",
                icon: "cup.and.saucer.fill",
                category: .hydration,
                requirement: 50
            ),
            Achievement(
                id: "hydration_100",
                titleKey: "百杯成就",
                descriptionKey: "累计喝水100次",
                icon: "mug.fill",
                category: .hydration,
                requirement: 100
            ),
            Achievement(
                id: "hydration_500",
                titleKey: "喝水大师",
                descriptionKey: "累计喝水500次",
                icon: "waterbottle.fill",
                category: .hydration,
                requirement: 500
            ),
            Achievement(
                id: "hydration_1000",
                titleKey: "千杯不醉",
                descriptionKey: "累计喝水1000次",
                icon: "sparkles",
                category: .hydration,
                requirement: 1000
            ),
            
            // 坚持不懈系列
            Achievement(
                id: "streak_3",
                titleKey: "三日坚持",
                descriptionKey: "连续3天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 3
            ),
            Achievement(
                id: "streak_7",
                titleKey: "一周达人",
                descriptionKey: "连续7天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 7
            ),
            Achievement(
                id: "streak_14",
                titleKey: "两周习惯",
                descriptionKey: "连续14天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                requirement: 14
            ),
            Achievement(
                id: "streak_30",
                titleKey: "月度挑战",
                descriptionKey: "连续30天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                requirement: 30
            ),
            Achievement(
                id: "streak_60",
                titleKey: "双月坚守",
                descriptionKey: "连续60天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                requirement: 60
            ),
            Achievement(
                id: "streak_100",
                titleKey: "百日筑基",
                descriptionKey: "连续100天完成喝水目标",
                icon: "crown.fill",
                category: .streak,
                requirement: 100
            ),
            
            // 花园大师系列
            Achievement(
                id: "garden_first_harvest",
                titleKey: "首次收获",
                descriptionKey: "第一次收获植物到花园",
                icon: "leaf.fill",
                category: .garden,
                requirement: 1
            ),
            Achievement(
                id: "garden_5_harvests",
                titleKey: "花园新手",
                descriptionKey: "累计收获5次",
                icon: "leaf.fill",
                category: .garden,
                requirement: 5
            ),
            Achievement(
                id: "garden_10_harvests",
                titleKey: "园丁认证",
                descriptionKey: "累计收获10次",
                icon: "tree.fill",
                category: .garden,
                requirement: 10
            ),
            Achievement(
                id: "garden_25_harvests",
                titleKey: "花园大师",
                descriptionKey: "累计收获25次",
                icon: "flower.fill",
                category: .garden,
                requirement: 25
            ),
            Achievement(
                id: "garden_50_harvests",
                titleKey: "传奇园丁",
                descriptionKey: "累计收获50次",
                icon: "sparkles",
                category: .garden,
                requirement: 50
            ),
            Achievement(
                id: "garden_5_species",
                titleKey: "品种收集家",
                descriptionKey: "收集5种不同植物品种",
                icon: "leaf.fill",
                category: .garden,
                requirement: 5
            ),
            Achievement(
                id: "garden_10_species",
                titleKey: "植物学家",
                descriptionKey: "收集7种不同植物品种",
                icon: "tree.fill",
                category: .garden,
                requirement: 7
            ),
            Achievement(
                id: "garden_all_species",
                titleKey: "全品种大师",
                descriptionKey: "收集所有植物品种",
                icon: "crown.fill",
                category: .garden,
                requirement: PlantLibrary.all.count
            ),
            
            // 社交分享系列
            Achievement(
                id: "social_first_share",
                titleKey: "初次分享",
                descriptionKey: "第一次分享植物状态",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: 1
            ),
            Achievement(
                id: "social_10_shares",
                titleKey: "社交达人",
                descriptionKey: "累计分享10次",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: 10
            ),
            
            // 重要里程碑
            Achievement(
                id: "milestone_10000ml",
                titleKey: "万水千山",
                descriptionKey: "累计喝水10000ml",
                icon: "drop.fill",
                category: .milestone,
                requirement: 10000
            ),
            Achievement(
                id: "milestone_50000ml",
                titleKey: "五万成就",
                descriptionKey: "累计喝水50000ml",
                icon: "sparkles",
                category: .milestone,
                requirement: 50000
            ),
            Achievement(
                id: "milestone_100000ml",
                titleKey: "十万喝水王",
                descriptionKey: "累计喝水100000ml",
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
