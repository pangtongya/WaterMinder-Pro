// BloomColors.swift
// Bloom 主题色系统 —— 自然绿系 + Hex 工具 + 深色模式适配

import SwiftUI
import UIKit

enum BloomColorConstants {
    static let bloomPrimaryLight = UIColor(hex: "#4CAF50")
    static let bloomPrimaryDark = UIColor(hex: "#66BB6A")
    static let bloomSecondaryLight = UIColor(hex: "#8BC34A")
    static let bloomSecondaryDark = UIColor(hex: "#81C784")
    static let bloomDeepLight = UIColor(hex: "#2E7D32")
    static let bloomDeepDark = UIColor(hex: "#1B5E20")
    static let bloomLeafLight = UIColor(hex: "#3D8A2E")
    static let bloomLeafDark = UIColor(hex: "#4CAF50")
    static let bloomSoilLight = UIColor(hex: "#8D6E4F")
    static let bloomSoilDark = UIColor(hex: "#A1887F")
    static let bloomWaterLight = UIColor(hex: "#4FC3F7")
    static let bloomWaterDark = UIColor(hex: "#29B6F6")
    static let bloomGoldLight = UIColor(hex: "#F5B82E")
    static let bloomGoldDark = UIColor(hex: "#FFD54F")
    static let bloomSuccessLight = UIColor(hex: "#66BB6A")
    static let bloomSuccessDark = UIColor(hex: "#4CAF50")
    static let bloomWarningLight = UIColor(hex: "#FFA726")
    static let bloomWarningDark = UIColor(hex: "#FFB74D")
    static let bloomDangerLight = UIColor(hex: "#EF5350")
    static let bloomDangerDark = UIColor(hex: "#E53935")
    static let bloomErrorLight = UIColor(hex: "#F44336")
    static let bloomErrorDark = UIColor(hex: "#EF5350")
}

// MARK: - HSB 调节（返回新 Color，非 View modifier）
// Canvas 里 .color() 需要 Color，不能用 .saturation() 这种 View modifier

extension Color {
    /// 调节饱和度和亮度，返回新 Color
    func adjusted(saturation: Double = 1.0, brightness: Double = 1.0) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(
            hue: Double(h),
            saturation: Double(s) * saturation,
            brightness: Double(b) * brightness,
            opacity: Double(a)
        )
    }

    // MARK: - Hex 初始化器

    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
    
    /// 从 UIColor 初始化（支持动态颜色）
    init(uiColor: UIColor) {
        self.init(uiColor)
    }
}

// MARK: - 动态颜色创建工具

extension UIColor {
    /// 创建动态颜色（浅色/深色模式自动切换）
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension Color {
    /// 创建动态颜色（浅色/深色模式自动切换）
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor.dynamicColor(
            light: UIColor(light),
            dark: UIColor(dark)
        ))
    }
}

// MARK: - Bloom 品牌色（自然绿系）

extension Color {
    /// 主色 —— 嫩芽绿 #4CAF50
    static let bloomPrimary = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomPrimaryLight,
        dark: BloomColorConstants.bloomPrimaryDark
    ))

    /// 次色 —— 浅绿 #8BC34A
    static let bloomSecondary = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomSecondaryLight,
        dark: BloomColorConstants.bloomSecondaryDark
    ))

    /// 深绿（成株）#2E7D32
    static let bloomDeep = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomDeepLight,
        dark: BloomColorConstants.bloomDeepDark
    ))

    /// 叶绿（茎叶）#3D8A2E
    static let bloomLeaf = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomLeafLight,
        dark: BloomColorConstants.bloomLeafDark
    ))

    /// 泥土暖色 #8D6E4F
    static let bloomSoil = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomSoilLight,
        dark: BloomColorConstants.bloomSoilDark
    ))

    /// 水蓝（饮水元素）#4FC3F7
    static let bloomWater = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomWaterLight,
        dark: BloomColorConstants.bloomWaterDark
    ))

    /// 花瓣金（向日葵）#F5B82E
    static let bloomGold = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomGoldLight,
        dark: BloomColorConstants.bloomGoldDark
    ))

    /// 成功绿 #66BB6A
    static let bloomSuccess = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomSuccessLight,
        dark: BloomColorConstants.bloomSuccessDark
    ))

    /// 警告橙（蔫了）#FFA726
    static let bloomWarning = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomWarningLight,
        dark: BloomColorConstants.bloomWarningDark
    ))

    /// 危险红（枯萎）#EF5350
    static let bloomDanger = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomDangerLight,
        dark: BloomColorConstants.bloomDangerDark
    ))
    
    /// 错误红
    static let bloomError = Color(uiColor: .dynamicColor(
        light: BloomColorConstants.bloomErrorLight,
        dark: BloomColorConstants.bloomErrorDark
    ))
}

// MARK: - Surface 表面颜色

extension Color {
    /// 主表面色（背景）
    static let bloomSurface = Color(uiColor: .dynamicColor(
        light: UIColor.systemBackground,
        dark: UIColor.systemBackground
    ))
    
    /// 次表面色（卡片、列表背景）
    static let bloomSurfaceSecondary = Color(uiColor: .dynamicColor(
        light: UIColor.secondarySystemBackground,
        dark: UIColor.secondarySystemBackground
    ))
    
    /// 三级表面色
    static let bloomSurfaceTertiary = Color(uiColor: .dynamicColor(
        light: UIColor.tertiarySystemBackground,
        dark: UIColor.tertiarySystemBackground
    ))
    
    /// 分组背景
    static let bloomGroupedBackground = Color(uiColor: .dynamicColor(
        light: UIColor.systemGroupedBackground,
        dark: UIColor.systemGroupedBackground
    ))
    
    /// 分组次背景
    static let bloomGroupedSecondary = Color(uiColor: .dynamicColor(
        light: UIColor.secondarySystemGroupedBackground,
        dark: UIColor.secondarySystemGroupedBackground
    ))
}

// MARK: - 文本颜色

extension Color {
    /// 主要文本颜色
    static let bloomTextPrimary = Color(uiColor: .dynamicColor(
        light: UIColor.label,
        dark: UIColor.label
    ))
    
    /// 次要文本颜色
    static let bloomTextSecondary = Color(uiColor: .dynamicColor(
        light: UIColor.secondaryLabel,
        dark: UIColor.secondaryLabel
    ))
    
    /// 三级文本颜色
    static let bloomTextTertiary = Color(uiColor: .dynamicColor(
        light: UIColor.tertiaryLabel,
        dark: UIColor.tertiaryLabel
    ))
    
    /// 四级文本颜色
    static let bloomTextQuaternary = Color(uiColor: .dynamicColor(
        light: UIColor.quaternaryLabel,
        dark: UIColor.quaternaryLabel
    ))
    
    /// 占位符文本颜色
    static let bloomPlaceholderText = Color(uiColor: .dynamicColor(
        light: UIColor.placeholderText,
        dark: UIColor.placeholderText
    ))
}

// MARK: - 边框和分隔线

extension Color {
    /// 分隔线颜色
    static let bloomSeparator = Color(uiColor: .dynamicColor(
        light: UIColor.separator,
        dark: UIColor.separator
    ))
    
    /// 不透明分隔线
    static let bloomOpaqueSeparator = Color(uiColor: .dynamicColor(
        light: UIColor.opaqueSeparator,
        dark: UIColor.opaqueSeparator
    ))
    
    /// Apple 设计系统边框色
    static let bloomBorder = Color(hex: "000000", opacity: 0.06)
    
    /// Apple 设计系统分隔线色
    static let bloomDivider = Color(hex: "3C3C43", opacity: 0.08)
    
    /// Apple 设计系统填充色
    static let bloomFill = Color(hex: "787880", opacity: 0.12)
    
    /// Apple 信息蓝
    static let bloomInfo = Color(hex: "007AFF")
}

// MARK: - Apple 风格动态背景色

extension Color {
    /// Apple 浅色模式页面背景 #F2F2F7
    static let bloomBackgroundLight = Color(hex: "F2F2F7")
    
    /// Apple 深色模式页面背景 #000000
    static let bloomBackgroundDark = Color(hex: "000000")
    
    /// 页面背景（自动适配深色模式）
    static let bloomBackground = Color(uiColor: .dynamicColor(
        light: bloomBackgroundLight,
        dark: bloomBackgroundDark
    ))
}

// MARK: - Apple 风格语义颜色

extension Color {
    /// Muted 主色（12% 透明度）
    static let bloomPrimaryMuted = Color.bloomPrimary.opacity(0.12)
    
    /// Subtle 主色（6% 透明度）
    static let bloomPrimarySubtle = Color.bloomPrimary.opacity(0.06)
    
    /// Muted 水蓝色（12% 透明度）
    static let bloomWaterMuted = Color.bloomWater.opacity(0.12)
    
    /// Muted 金色（15% 透明度）
    static let bloomGoldMuted = Color.bloomGold.opacity(0.15)
}

// MARK: - 健康度 → 状态颜色

extension Color {
    /// 根据健康度返回语义色
    static func healthColor(_ health: Double) -> Color {
        switch health {
        case ..<25:  return .bloomDanger    // 枯萎边缘
        case ..<50:  return .bloomWarning   // 蔫了
        case ..<80:  return .bloomPrimary   // 还行
        default:     return .bloomSuccess   // 生机勃勃
        }
    }
}

// MARK: - UIColor Hex 扩展

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
