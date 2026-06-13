// ColorExtensions.swift
// 品牌色扩展

import SwiftUI

extension Color {
    // WaterMinder 品牌色
    static let waterminderPrimary = Color.blue
    static let waterminderSecondary = Color.cyan
    static let waterminderBackground = Color(.systemBackground)
    static let waterminderCardBackground = Color(.secondarySystemBackground)
    
    // 语义化颜色
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    
    // 根据进度返回颜色
    static func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.25: return .red
        case 0.25..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        case 0.75...1.0: return .green
        default: return .gray
        }
    }
}
