// Achievement.swift
// 成就系统 —— 激励用户坚持喝水养植物

import Foundation

// MARK: - 成就类型

enum AchievementType: String, Codable, CaseIterable {
    case streak
    case milestone
    case collection
    case special
    
    var localizedKey: String {
        switch self {
        case .streak: return "连续成就"
        case .milestone: return "里程碑"
        case .collection: return "收集成就"
        case .special: return "特殊成就"
        }
    }
    
    var localizedName: String {
        NSLocalizedString(localizedKey, comment: localizedKey)
    }
}

// MARK: - 成就定义

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let icon: String
    let category: AchievementCategory
    let type: AchievementType
    let isProOnly: Bool
    var requirement: Int
    var unlockedAt: Date?
    var progress: Int
    
    var targetValue: Int {
        return requirement
    }
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
    
    var title: String {
        NSLocalizedString(titleKey, comment: titleKey)
    }
    
    var description: String {
        NSLocalizedString(descriptionKey, comment: descriptionKey)
    }
    
    init(
        id: String,
        titleKey: String,
        descriptionKey: String,
        icon: String,
        category: AchievementCategory,
        type: AchievementType = .milestone,
        isProOnly: Bool = false,
        requirement: Int,
        unlockedAt: Date? = nil,
        progress: Int = 0
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.icon = icon
        self.category = category
        self.type = type
        self.isProOnly = isProOnly
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
    
    var localizedKey: String {
        switch self {
        case .hydration: return "喝水达人"
        case .streak: return "坚持不懈"
        case .garden: return "花园大师"
        case .social: return "社交分享"
        case .milestone: return "重要里程碑"
        }
    }
    
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

// MARK: - 所有成就

extension Achievement {
    static func allAchievements() -> [Achievement] {
        return [
            // MARK: - 喝水量成就（累计喝水升数）
            Achievement(
                id: "hydration_volume_50L",
                titleKey: "五十升水",
                descriptionKey: "累计喝水达到50升",
                icon: "drop.fill",
                category: .hydration,
                type: .milestone,
                requirement: 50000
            ),
            Achievement(
                id: "hydration_volume_100L",
                titleKey: "百升成就",
                descriptionKey: "累计喝水达到100升",
                icon: "drop.circle.fill",
                category: .hydration,
                type: .milestone,
                requirement: 100000
            ),
            Achievement(
                id: "hydration_volume_500L",
                titleKey: "五百升大师",
                descriptionKey: "累计喝水达到500升",
                icon: "waterbottle.fill",
                category: .hydration,
                type: .milestone,
                isProOnly: true,
                requirement: 500000
            ),
            Achievement(
                id: "hydration_volume_1000L",
                titleKey: "千升传奇",
                descriptionKey: "累计喝水达到1000升",
                icon: "sparkles",
                category: .hydration,
                type: .milestone,
                isProOnly: true,
                requirement: 1000000
            ),
            
            // MARK: - 连续达标成就
            Achievement(
                id: "streak_3",
                titleKey: "三日坚持",
                descriptionKey: "连续3天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                type: .streak,
                requirement: 3
            ),
            Achievement(
                id: "streak_7",
                titleKey: "一周达人",
                descriptionKey: "连续7天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                type: .streak,
                requirement: 7
            ),
            Achievement(
                id: "streak_14",
                titleKey: "两周习惯",
                descriptionKey: "连续14天完成喝水目标",
                icon: "calendar.badge.checkmark",
                category: .streak,
                type: .streak,
                requirement: 14
            ),
            Achievement(
                id: "streak_30",
                titleKey: "月度挑战",
                descriptionKey: "连续30天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                type: .streak,
                requirement: 30
            ),
            Achievement(
                id: "streak_45",
                titleKey: "四十五天",
                descriptionKey: "连续45天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                type: .streak,
                requirement: 45
            ),
            Achievement(
                id: "streak_60",
                titleKey: "双月坚守",
                descriptionKey: "连续60天完成喝水目标",
                icon: "trophy.fill",
                category: .streak,
                type: .streak,
                requirement: 60
            ),
            Achievement(
                id: "streak_90",
                titleKey: "季度达人",
                descriptionKey: "连续90天完成喝水目标",
                icon: "crown.fill",
                category: .streak,
                type: .streak,
                isProOnly: true,
                requirement: 90
            ),
            Achievement(
                id: "streak_100",
                titleKey: "百日筑基",
                descriptionKey: "连续100天完成喝水目标",
                icon: "crown.fill",
                category: .streak,
                type: .streak,
                isProOnly: true,
                requirement: 100
            ),
            Achievement(
                id: "streak_180",
                titleKey: "半年传奇",
                descriptionKey: "连续180天完成喝水目标",
                icon: "star.fill",
                category: .streak,
                type: .streak,
                isProOnly: true,
                requirement: 180
            ),
            Achievement(
                id: "streak_365",
                titleKey: "年度冠军",
                descriptionKey: "连续365天完成喝水目标",
                icon: "sparkles",
                category: .streak,
                type: .streak,
                isProOnly: true,
                requirement: 365
            ),
            
            // MARK: - 收集成就（植物品种）
            Achievement(
                id: "collection_3_species",
                titleKey: "初入花园",
                descriptionKey: "收集3种不同的植物品种",
                icon: "leaf.fill",
                category: .garden,
                type: .collection,
                requirement: 3
            ),
            Achievement(
                id: "collection_5_species",
                titleKey: "品种收集家",
                descriptionKey: "收集5种不同的植物品种",
                icon: "leaf.circle.fill",
                category: .garden,
                type: .collection,
                requirement: 5
            ),
            Achievement(
                id: "collection_7_species",
                titleKey: "植物学家",
                descriptionKey: "收集7种不同的植物品种",
                icon: "tree.fill",
                category: .garden,
                type: .collection,
                isProOnly: true,
                requirement: 7
            ),
            
            // MARK: - 收获成就
            Achievement(
                id: "harvest_1",
                titleKey: "首次收获",
                descriptionKey: "第一次收获植物到花园",
                icon: "leaf.fill",
                category: .garden,
                type: .milestone,
                requirement: 1
            ),
            Achievement(
                id: "harvest_5",
                titleKey: "花园新手",
                descriptionKey: "累计收获5株植物",
                icon: "leaf.fill",
                category: .garden,
                type: .milestone,
                requirement: 5
            ),
            Achievement(
                id: "harvest_10",
                titleKey: "园丁认证",
                descriptionKey: "累计收获10株植物",
                icon: "tree.fill",
                category: .garden,
                type: .milestone,
                requirement: 10
            ),
            Achievement(
                id: "harvest_20",
                titleKey: "园艺高手",
                descriptionKey: "累计收获20株植物",
                icon: "flower.fill",
                category: .garden,
                type: .milestone,
                requirement: 20
            ),
            Achievement(
                id: "harvest_50",
                titleKey: "传奇园丁",
                descriptionKey: "累计收获50株植物",
                icon: "sparkles",
                category: .garden,
                type: .milestone,
                isProOnly: true,
                requirement: 50
            ),
            
            // MARK: - 社交成就（连续打卡）
            Achievement(
                id: "social_checkin_7",
                titleKey: "周打卡达人",
                descriptionKey: "连续7天打卡分享",
                icon: "calendar.badge.clock",
                category: .social,
                type: .streak,
                requirement: 7
            ),
            Achievement(
                id: "social_checkin_30",
                titleKey: "月打卡冠军",
                descriptionKey: "连续30天打卡分享",
                icon: "rosette",
                category: .social,
                type: .streak,
                isProOnly: true,
                requirement: 30
            ),
            
            // MARK: - 完美一天成就
            Achievement(
                id: "perfect_day_1",
                titleKey: "完美一天",
                descriptionKey: "单日喝水目标完美达标1次",
                icon: "checkmark.seal.fill",
                category: .milestone,
                type: .special,
                requirement: 1
            ),
            Achievement(
                id: "perfect_day_7",
                titleKey: "完美一周",
                descriptionKey: "累计7天完美达成喝水目标",
                icon: "checkmark.seal.fill",
                category: .milestone,
                type: .special,
                requirement: 7
            ),
            Achievement(
                id: "perfect_day_30",
                titleKey: "完美一月",
                descriptionKey: "累计30天完美达成喝水目标",
                icon: "checkmark.seal.fill",
                category: .milestone,
                type: .special,
                isProOnly: true,
                requirement: 30
            )
        ]
    }
    
    static func achievements(for category: AchievementCategory) -> [Achievement] {
        return allAchievements().filter { $0.category == category }
    }
    
    static func achievements(ofType type: AchievementType) -> [Achievement] {
        return allAchievements().filter { $0.type == type }
    }
}

// MARK: - 成就库（保持向后兼容）

enum AchievementLibrary {
    
    static func allAchievements() -> [Achievement] {
        return Achievement.allAchievements()
    }
    
    static func achievements(for category: AchievementCategory) -> [Achievement] {
        return Achievement.achievements(for: category)
    }
}
