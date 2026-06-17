// ThemeManager.swift
// 主题管理器 —— 处理主题切换、Pro 验证、颜色提供

import Foundation
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = ThemeLibrary.default
    
    /// 检查主题是否可用（免费 or Pro）
    func isThemeAvailable(_ theme: Theme, isPro: Bool) -> Bool {
        return !theme.isPro || isPro
    }
    
    /// 设置主题（会检查 Pro 权限）
    func setTheme(_ themeID: String, isPro: Bool) -> Bool {
        let theme = ThemeLibrary.theme(id: themeID)
        
        // 检查 Pro 权限
        guard isThemeAvailable(theme, isPro: isPro) else {
            return false
        }
        
        currentTheme = theme
        UserDefaults.standard.set(themeID, forKey: "bloom.selectedTheme")
        return true
    }
    
    /// 加载已保存的主题
    func loadSavedTheme(isPro: Bool) {
        let themeID = UserDefaults.standard.string(forKey: "bloom.selectedTheme") ?? "classic"
        let success = setTheme(themeID, isPro: isPro)
        if !success {
            // 如果主题不可用（比如 Pro 过期），回退到默认
            currentTheme = ThemeLibrary.default
        }
    }
    
    /// 获取可用的主题列表
    func availableThemes(isPro: Bool) -> [Theme] {
        return ThemeLibrary.all.filter { isThemeAvailable($0, isPro: isPro) }
    }
    
    /// 获取 Pro 主题列表（用于展示锁定状态）
    var proThemes: [Theme] {
        ThemeLibrary.pro
    }
    
    /// 获取当前主题的 AccentColor
    var accentColor: Color {
        currentTheme.accent
    }
    
    /// 获取当前主题的 PrimaryColor
    var primaryColor: Color {
        currentTheme.primary
    }
    
    /// 获取植物色调（如果有覆盖）
    var plantTintColor: Color? {
        currentTheme.plantTintColor
    }
}
