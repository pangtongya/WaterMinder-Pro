// Theme.swift
// 主题系统 —— Pro 用户可自定义外观

import Foundation
import SwiftUI

// MARK: - 主题定义

struct Theme: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let nameEn: String
    let isPro: Bool
    let description: String
    let descriptionEn: String
    
    // 颜色配置
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let backgroundColor: String
    let cardColor: String
    
    // 植物外观
    let plantTint: String?  // 植物色调覆盖（nil 表示使用品种默认色）
    
    // 图标
    let icon: String
    
    // MARK: - 颜色快捷访问
    
    var primary: Color { Color(hex: primaryColor) }
    var secondary: Color { Color(hex: secondaryColor) }
    var accent: Color { Color(hex: accentColor) }
    var background: Color { Color(hex: backgroundColor) }
    var card: Color { Color(hex: cardColor) }
    var plantTintColor: Color? { plantTint.map { Color(hex: $0) } }
    
    var isFree: Bool { !isPro }
    
    /// 本地化的名称
    var localizedName: String {
        Bundle.main.preferredLocalizations.contains("zh") ? name : nameEn
    }
    
    /// 本地化的描述
    var localizedDescription: String {
        Bundle.main.preferredLocalizations.contains("zh") ? description : descriptionEn
    }
}

// MARK: - 主题库

enum ThemeLibrary {
    
    /// 免费主题
    static let free: [Theme] = [.classic, .light, .dark]
    
    /// Pro 主题
    static let pro: [Theme] = [.ocean, .forest, .sunset, .lavender, .midnight]
    
    /// 所有主题
    static let all: [Theme] = free + pro
    
    /// 默认主题
    static let `default` = Theme.classic
    
    /// 按 ID 查找
    static func theme(id: String) -> Theme {
        all.first { $0.id == id } ?? .classic
    }
}

// MARK: - 主题定义

extension Theme {
    
    /// 经典主题（免费默认）
    static let classic = Theme(
        id: "classic",
        name: "经典",
        nameEn: "Classic",
        isPro: false,
        description: "Bloom 默认配色，清新自然",
        descriptionEn: "Bloom's default color scheme, fresh and natural",
        primaryColor: "#4CAF50",
        secondaryColor: "#8BC34A",
        accentColor: "#FF9800",
        backgroundColor: "#F5F5F5",
        cardColor: "#FFFFFF",
        plantTint: nil,
        icon: "leaf.fill"
    )
    
    /// 浅色主题
    static let light = Theme(
        id: "light",
        name: "明亮",
        nameEn: "Light",
        isPro: false,
        description: "清爽明亮的白色基调",
        descriptionEn: "Fresh and bright white theme",
        primaryColor: "#2196F3",
        secondaryColor: "#03A9F4",
        accentColor: "#FF5722",
        backgroundColor: "#FAFAFA",
        cardColor: "#FFFFFF",
        plantTint: nil,
        icon: "sun.max.fill"
    )
    
    /// 深色主题
    static let dark = Theme(
        id: "dark",
        name: "暗夜",
        nameEn: "Dark",
        isPro: false,
        description: "护眼的深色模式",
        descriptionEn: "Eye-friendly dark mode",
        primaryColor: "#4CAF50",
        secondaryColor: "#66BB6A",
        accentColor: "#FFA726",
        backgroundColor: "#1A1A1A",
        cardColor: "#2C2C2C",
        plantTint: nil,
        icon: "moon.fill"
    )
    
    // MARK: - Pro 主题
    
    static let ocean = Theme(
        id: "ocean",
        name: "海洋",
        nameEn: "Ocean",
        isPro: true,
        description: "深邃的海洋蓝调",
        descriptionEn: "Deep ocean blue tones",
        primaryColor: "#00BCD4",
        secondaryColor: "#0097A7",
        accentColor: "#FF9800",
        backgroundColor: "#E0F7FA",
        cardColor: "#FFFFFF",
        plantTint: "#00BCD4",
        icon: "water.waves"
    )
    
    static let forest = Theme(
        id: "forest",
        name: "森林",
        nameEn: "Forest",
        isPro: true,
        description: "浓郁的森林绿意",
        descriptionEn: "Rich forest green tones",
        primaryColor: "#2E7D32",
        secondaryColor: "#4CAF50",
        accentColor: "#FFC107",
        backgroundColor: "#E8F5E9",
        cardColor: "#FFFFFF",
        plantTint: "#2E7D32",
        icon: "tree.fill"
    )
    
    static let sunset = Theme(
        id: "sunset",
        name: "日落",
        nameEn: "Sunset",
        isPro: true,
        description: "温暖的夕阳橙红",
        descriptionEn: "Warm sunset orange and red",
        primaryColor: "#FF5722",
        secondaryColor: "#FF9800",
        accentColor: "#FFC107",
        backgroundColor: "#FFF3E0",
        cardColor: "#FFFFFF",
        plantTint: "#FF5722",
        icon: "sunset.fill"
    )
    
    static let lavender = Theme(
        id: "lavender",
        name: "薰衣草",
        nameEn: "Lavender",
        isPro: true,
        description: "浪漫的紫色梦幻",
        descriptionEn: "Romantic purple dreams",
        primaryColor: "#9C27B0",
        secondaryColor: "#BA68C8",
        accentColor: "#FF9800",
        backgroundColor: "#F3E5F5",
        cardColor: "#FFFFFF",
        plantTint: "#9C27B0",
        icon: "flower.fill"
    )
    
    static let midnight = Theme(
        id: "midnight",
        name: "午夜",
        nameEn: "Midnight",
        isPro: true,
        description: "神秘的午夜蓝黑",
        descriptionEn: "Mysterious midnight blue-black",
        primaryColor: "#3F51B5",
        secondaryColor: "#5C6BC0",
        accentColor: "#FF4081",
        backgroundColor: "#0D1B2A",
        cardColor: "#1B2838",
        plantTint: "#3F51B5",
        icon: "star.fill"
    )
}
