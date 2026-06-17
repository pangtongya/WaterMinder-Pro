// BloomColors.swift
// Bloom 主题色系统 —— 自然绿系 + Hex 工具

import SwiftUI

extension Color {
    // MARK: - HSB 调节（返回新 Color，非 View modifier）
    // Canvas 里 .color() 需要 Color，不能用 .saturation() 这种 View modifier

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

    init(hex: String) {
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
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Bloom 品牌色（自然绿系）

extension Color {
    /// 主色 —— 嫩芽绿 #4CAF50
    static let bloomPrimary = Color(hex: "#4CAF50")

    /// 深绿（成株）#2E7D32
    static let bloomDeep = Color(hex: "#2E7D32")

    /// 叶绿（茎叶）#3D8A2E
    static let bloomLeaf = Color(hex: "#3D8A2E")

    /// 泥土暖色 #8D6E4F
    static let bloomSoil = Color(hex: "#8D6E4F")

    /// 水蓝（饮水元素）#4FC3F7
    static let bloomWater = Color(hex: "#4FC3F7")

    /// 花瓣金（向日葵）#F5B82E
    static let bloomGold = Color(hex: "#F5B82E")

    /// 成功绿 #66BB6A
    static let bloomSuccess = Color(hex: "#66BB6A")

    /// 警告橙（蔫了）#FFA726
    static let bloomWarning = Color(hex: "#FFA726")

    /// 危险红（枯萎）#EF5350
    static let bloomDanger = Color(hex: "#EF5350")
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
