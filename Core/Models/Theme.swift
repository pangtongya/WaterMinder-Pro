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
    let darkColor: String
    let accentColor: String
    let backgroundColor: String
    let cardColor: String
    
    // 深色模式颜色
    let primaryColorDark: String
    let secondaryColorDark: String
    let backgroundColorDark: String
    let cardColorDark: String
    
    // 植物外观
    let plantTint: String?  // 植物色调覆盖（nil 表示使用品种默认色）
    
    // 图标
    let icon: String
    
    // MARK: - 颜色快捷访问
    
    var primary: Color { Color(hex: primaryColor) }
    var secondary: Color { Color(hex: secondaryColor) }
    var dark: Color { Color(hex: darkColor) }
    var accent: Color { Color(hex: accentColor) }
    var background: Color { Color(hex: backgroundColor) }
    var card: Color { Color(hex: cardColor) }
    
    var primaryDark: Color { Color(hex: primaryColorDark) }
    var secondaryDark: Color { Color(hex: secondaryColorDark) }
    var backgroundDark: Color { Color(hex: backgroundColorDark) }
    var cardDark: Color { Color(hex: cardColorDark) }
    
    var plantTintColor: Color? { plantTint.map { Color(hex: $0) } }
    
    var isFree: Bool { !isPro }
    
    /// 本地化的名称
    var localizedName: String {
        NSLocalizedString("theme.name.\(id)", value: name, comment: "Theme name")
    }
    
    /// 本地化的描述
    var localizedDescription: String {
        NSLocalizedString("theme.desc.\(id)", value: description, comment: "Theme description")
    }
    
    /// 动态主色（自动适配浅色/深色模式）
    func dynamicPrimary(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? primaryDark : primary
    }
    
    /// 动态次色
    func dynamicSecondary(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryDark : secondary
    }
    
    /// 动态背景色
    func dynamicBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : background
    }
    
    /// 动态卡片色
    func dynamicCard(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardDark : card
    }
}

// MARK: - 主题库

enum ThemeLibrary {
    
    /// 免费主题
    static let free: [Theme] = [.classic, .sunflower]
    
    /// Pro 主题
    static let pro: [Theme] = [.sakura, .ocean, .midnightGold, .forest, .sunset, .lavender, .midnight]
    
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
    
    /// 经典主题（免费默认）- 绿色经典
    static let classic = Theme(
        id: "classic",
        name: "经典绿",
        nameEn: "Classic Green",
        isPro: false,
        description: "Bloom 默认配色，清新自然",
        descriptionEn: "Bloom's default color scheme, fresh and natural",
        primaryColor: "#4CAF50",
        secondaryColor: "#8BC34A",
        darkColor: "#2E7D32",
        accentColor: "#FF9800",
        backgroundColor: "#F5F5F5",
        cardColor: "#FFFFFF",
        primaryColorDark: "#66BB6A",
        secondaryColorDark: "#81C784",
        backgroundColorDark: "#121212",
        cardColorDark: "#1E1E1E",
        plantTint: nil,
        icon: "leaf.fill"
    )
    
    /// 向日葵黄（免费）
    static let sunflower = Theme(
        id: "sunflower",
        name: "向日葵黄",
        nameEn: "Sunflower",
        isPro: false,
        description: "温暖明亮的阳光色调",
        descriptionEn: "Warm and bright sunflower tones",
        primaryColor: "#FFC107",
        secondaryColor: "#FFD54F",
        darkColor: "#FF8F00",
        accentColor: "#FF5722",
        backgroundColor: "#FFFDE7",
        cardColor: "#FFFFFF",
        primaryColorDark: "#FFCA28",
        secondaryColorDark: "#FFD54F",
        backgroundColorDark: "#1A1200",
        cardColorDark: "#1E1E1E",
        plantTint: "#FFC107",
        icon: "sun.max.fill"
    )
    
    // MARK: - Pro 主题
    
    /// 樱花粉（Pro 专属）
    static let sakura = Theme(
        id: "sakura",
        name: "樱花粉",
        nameEn: "Sakura",
        isPro: true,
        description: "温柔浪漫的粉色系",
        descriptionEn: "Gentle and romantic pink theme",
        primaryColor: "#EC407A",
        secondaryColor: "#F48FB1",
        darkColor: "#C2185B",
        accentColor: "#AB47BC",
        backgroundColor: "#FCE4EC",
        cardColor: "#FFFFFF",
        primaryColorDark: "#F06292",
        secondaryColorDark: "#F48FB1",
        backgroundColorDark: "#1A0A10",
        cardColorDark: "#1E1E1E",
        plantTint: "#EC407A",
        icon: "flower.fill"
    )
    
    /// 海洋蓝（Pro 专属）
    static let ocean = Theme(
        id: "ocean",
        name: "海洋蓝",
        nameEn: "Ocean Blue",
        isPro: true,
        description: "深邃的海洋蓝调",
        descriptionEn: "Deep ocean blue tones",
        primaryColor: "#0288D1",
        secondaryColor: "#4FC3F7",
        darkColor: "#01579B",
        accentColor: "#FF9800",
        backgroundColor: "#E1F5FE",
        cardColor: "#FFFFFF",
        primaryColorDark: "#29B6F6",
        secondaryColorDark: "#4FC3F7",
        backgroundColorDark: "#0A1929",
        cardColorDark: "#132F4C",
        plantTint: "#0288D1",
        icon: "water.waves"
    )
    
    /// 暗夜金（Pro 专属）
    static let midnightGold = Theme(
        id: "midnightGold",
        name: "暗夜金",
        nameEn: "Midnight Gold",
        isPro: true,
        description: "深灰配金色，奢华典雅",
        descriptionEn: "Dark gray with gold, luxurious and elegant",
        primaryColor: "#FFD700",
        secondaryColor: "#FFA000",
        darkColor: "#FF6F00",
        accentColor: "#FFD700",
        backgroundColor: "#1A1A2E",
        cardColor: "#16213E",
        primaryColorDark: "#FFE082",
        secondaryColorDark: "#FFD54F",
        backgroundColorDark: "#0F0F1A",
        cardColorDark: "#1A1A2E",
        plantTint: "#FFD700",
        icon: "sparkles"
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
        darkColor: "#1B5E20",
        accentColor: "#FFC107",
        backgroundColor: "#E8F5E9",
        cardColor: "#FFFFFF",
        primaryColorDark: "#43A047",
        secondaryColorDark: "#66BB6A",
        backgroundColorDark: "#0D1F0D",
        cardColorDark: "#1A2E1A",
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
        darkColor: "#E64A19",
        accentColor: "#FFC107",
        backgroundColor: "#FFF3E0",
        cardColor: "#FFFFFF",
        primaryColorDark: "#FF7043",
        secondaryColorDark: "#FFA726",
        backgroundColorDark: "#1A0F00",
        cardColorDark: "#1E1E1E",
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
        darkColor: "#7B1FA2",
        accentColor: "#FF9800",
        backgroundColor: "#F3E5F5",
        cardColor: "#FFFFFF",
        primaryColorDark: "#AB47BC",
        secondaryColorDark: "#CE93D8",
        backgroundColorDark: "#1A0A1F",
        cardColorDark: "#1E1E1E",
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
        darkColor: "#303F9F",
        accentColor: "#FF4081",
        backgroundColor: "#0D1B2A",
        cardColor: "#1B2838",
        primaryColorDark: "#5C6BC0",
        secondaryColorDark: "#7986CB",
        backgroundColorDark: "#0A1018",
        cardColorDark: "#15202B",
        plantTint: "#3F51B5",
        icon: "star.fill"
    )
}
