// ColorExtensions.swift
// WaterMinder 品牌色系统

import SwiftUI

extension Color {
    // MARK: - WaterMinder Brand Colors
    // 水蓝色渐变系，传递清新、健康、信任感
    
    /// 主色 - 青绿渐变起始 #06B6D4 (Teal)
    static let waterminderPrimary = Color(red: 0.02, green: 0.71, blue: 0.83)
    
    /// 辅助色 - 深青绿 #0E7490
    static let waterminderSecondary = Color(red: 0.05, green: 0.45, blue: 0.56)
    
    /// 第三色 - 浅青绿 #A7FEF8
    static let waterminderAccent = Color(red: 0.65, green: 0.996, blue: 0.973)
    
    /// 成功绿 - 翠绿 #10B981
    static let waterminderSuccess = Color(red: 0.06, green: 0.73, blue: 0.51)
    
    /// 警告橙 - 琥珀 #F59E0B
    static let waterminderWarning = Color(red: 0.96, green: 0.62, blue: 0.04)
    
    /// 危险红 - 玫瑰 #F43F5E
    static let waterminderDanger = Color(red: 0.96, green: 0.25, blue: 0.37)
    
    // MARK: - Progress Colors
    /// 根据进度返回语义化颜色
    static func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.3:  return .waterminderDanger    // 需要加油
        case 0.3..<0.6: return .waterminderWarning   // 进行中
        case 0.6..<0.9: return .waterminderSecondary  // 快完成了
        case 0.9...:    return .waterminderSuccess    // 达成目标
        default:        return .gray
        }
    }
    
    // MARK: - Hex Color Initializer
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
