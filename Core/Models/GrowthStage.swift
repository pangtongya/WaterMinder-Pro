// GrowthStage.swift
// 植物成长阶段 —— 积累达标天数推进生命历程

import Foundation

enum GrowthStage: Int, Codable, CaseIterable {
    case seed      = 0   // 种子（刚种下）
    case sprout    = 1   // 发芽
    case seedling  = 2   // 幼苗
    case mature    = 3   // 成株
    case blooming  = 4   // 开花
    case harvestable = 5 // 可收获（盛开到极致，等待收获入花园）

    /// 本地化的显示名
    var name: String {
        switch self {
        case .seed:        return NSLocalizedString("种子", comment: "Seed stage")
        case .sprout:      return NSLocalizedString("发芽", comment: "Sprout stage")
        case .seedling:    return NSLocalizedString("幼苗", comment: "Seedling stage")
        case .mature:      return NSLocalizedString("成株", comment: "Mature stage")
        case .blooming:    return NSLocalizedString("含苞", comment: "Blooming stage")
        case .harvestable: return NSLocalizedString("盛开", comment: "Harvestable stage")
        }
    }

    /// 该阶段的 emoji（用于通知、花园列表等非 Canvas 场景）
    var emoji: String {
        switch self {
        case .seed:        return "🌰"
        case .sprout:      return "🌱"
        case .seedling:    return "🌿"
        case .mature:      return "🪴"
        case .blooming:    return "🌷"
        case .harvestable: return "🌸"
        }
    }

    /// 茎的相对高度比例（0.0–1.0），供绘制引擎使用
    var stemRatio: Double {
        switch self {
        case .seed:        return 0.05
        case .sprout:      return 0.20
        case .seedling:    return 0.40
        case .mature:      return 0.65
        case .blooming:    return 0.85
        case .harvestable: return 1.0
        }
    }

    /// 该阶段应有的叶片数量
    var leafCount: Int {
        switch self {
        case .seed:        return 0
        case .sprout:      return 2
        case .seedling:    return 4
        case .mature:      return 6
        case .blooming:    return 8
        case .harvestable: return 8
        }
    }

    /// 是否开始绽放花朵
    var hasFlower: Bool { self == .blooming || self == .harvestable }

    var next: GrowthStage? {
        GrowthStage(rawValue: rawValue + 1)
    }
}
