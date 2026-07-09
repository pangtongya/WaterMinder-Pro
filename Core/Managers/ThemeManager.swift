// ThemeManager.swift
// 主题管理器 —— 处理主题切换、Pro 验证、颜色提供、动画过渡

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = ThemeLibrary.default
    @Published var previewTheme: Theme? = nil
    @Published var isTransitioning: Bool = false
    
    private let userDefaultsKey = "bloom.selectedTheme"
    private let transitionDuration: TimeInterval = 0.3
    
    private init() {}
    
    // MARK: - 主题可用性检查
    
    /// 检查主题是否可用（免费 or Pro）
    func isThemeAvailable(_ theme: Theme, isPro: Bool) -> Bool {
        return !theme.isPro || isPro
    }
    
    // MARK: - 主题切换（带动画）
    
    /// 设置主题（带动画过渡效果）
    @discardableResult
    func setTheme(_ themeID: String, isPro: Bool, animated: Bool = true) -> Bool {
        let theme = ThemeLibrary.theme(id: themeID)
        
        guard isThemeAvailable(theme, isPro: isPro) else {
            return false
        }
        
        guard theme.id != currentTheme.id else {
            return true
        }
        
        if animated {
            performAnimatedTransition(to: theme)
        } else {
            currentTheme = theme
        }
        
        UserDefaults.standard.set(themeID, forKey: userDefaultsKey)
        return true
    }
    
    /// 执行动画过渡
    private func performAnimatedTransition(to theme: Theme) {
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: transitionDuration)) {
            currentTheme = theme
        }
        
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((self?.transitionDuration ?? 0.3) * 1_000_000_000))
            self?.isTransitioning = false
        }
    }
    
    // MARK: - 主题预览
    
    /// 开始预览主题（临时显示，不保存）
    func startPreview(_ theme: Theme) {
        previewTheme = theme
    }
    
    /// 结束预览，恢复当前主题
    func endPreview() {
        previewTheme = nil
    }
    
    /// 确认预览主题为当前主题
    func confirmPreview(isPro: Bool) -> Bool {
        guard let preview = previewTheme else { return false }
        let result = setTheme(preview.id, isPro: isPro)
        previewTheme = nil
        return result
    }
    
    /// 获取当前有效的主题（预览优先）
    var activeTheme: Theme {
        previewTheme ?? currentTheme
    }
    
    // MARK: - 持久化
    
    /// 加载已保存的主题
    func loadSavedTheme(isPro: Bool) {
        let themeID = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ThemeLibrary.default.id
        let success = setTheme(themeID, isPro: isPro, animated: false)
        if !success {
            currentTheme = ThemeLibrary.default
            UserDefaults.standard.set(ThemeLibrary.default.id, forKey: userDefaultsKey)
        }
    }
    
    /// 重置为默认主题
    func resetToDefault(isPro: Bool) {
        setTheme(ThemeLibrary.default.id, isPro: isPro)
    }
    
    // MARK: - 主题列表
    
    /// 获取可用的主题列表
    func availableThemes(isPro: Bool) -> [Theme] {
        return ThemeLibrary.all.filter { isThemeAvailable($0, isPro: isPro) }
    }
    
    /// 获取免费主题列表
    var freeThemes: [Theme] {
        ThemeLibrary.free
    }
    
    /// 获取 Pro 主题列表（用于展示锁定状态）
    var proThemes: [Theme] {
        ThemeLibrary.pro
    }
    
    /// 获取所有主题
    var allThemes: [Theme] {
        ThemeLibrary.all
    }
    
    // MARK: - 颜色访问器（动态适配深色模式）
    
    /// 获取当前主题的 AccentColor
    var accentColor: Color {
        activeTheme.accent
    }
    
    /// 获取当前主题的 PrimaryColor
    var primaryColor: Color {
        activeTheme.primary
    }
    
    /// 获取当前主题的 SecondaryColor
    var secondaryColor: Color {
        activeTheme.secondary
    }
    
    /// 获取当前主题的 DarkColor
    var darkColor: Color {
        activeTheme.dark
    }
    
    /// 获取当前主题的背景色
    var backgroundColor: Color {
        activeTheme.background
    }
    
    /// 获取当前主题的卡片色
    var cardColor: Color {
        activeTheme.card
    }
    
    /// 获取植物色调（如果有覆盖）
    var plantTintColor: Color? {
        activeTheme.plantTintColor
    }
    
    // MARK: - 动态颜色（适配浅色/深色模式）
    
    /// 根据 colorScheme 返回动态主色
    func dynamicPrimary(colorScheme: ColorScheme) -> Color {
        activeTheme.dynamicPrimary(colorScheme: colorScheme)
    }
    
    /// 根据 colorScheme 返回动态次色
    func dynamicSecondary(colorScheme: ColorScheme) -> Color {
        activeTheme.dynamicSecondary(colorScheme: colorScheme)
    }
    
    /// 根据 colorScheme 返回动态背景色
    func dynamicBackground(colorScheme: ColorScheme) -> Color {
        activeTheme.dynamicBackground(colorScheme: colorScheme)
    }
    
    /// 根据 colorScheme 返回动态卡片色
    func dynamicCard(colorScheme: ColorScheme) -> Color {
        activeTheme.dynamicCard(colorScheme: colorScheme)
    }
    
    // MARK: - 渐变
    
    /// 获取主题主渐变
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [activeTheme.primary, activeTheme.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 获取主题深色渐变
    var darkGradient: LinearGradient {
        LinearGradient(
            colors: [activeTheme.dark, activeTheme.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View 扩展：主题环境便捷访问

extension View {
    /// 应用主题背景
    func themeBackground() -> some View {
        self.background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    /// 应用主题卡片样式
    func themeCardStyle() -> some View {
        self
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
