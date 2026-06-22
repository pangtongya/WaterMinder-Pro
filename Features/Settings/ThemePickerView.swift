// ThemePickerView.swift
// 主题选择器 —— 展示所有主题，Pro 主题显示锁定状态

import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedThemeID: String = "classic"
    @State private var showPaywall = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 说明文字
                Text("选择你喜欢的主题外观".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // 免费主题
                themeSection(
                    title: "免费主题".localized,
                    themes: ThemeLibrary.free,
                    isPro: false
                )
                
                // Pro 主题
                themeSection(
                    title: L.proThemes,
                    themes: ThemeLibrary.pro,
                    isPro: true
                )
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.themeAppearance)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedThemeID = userStore.profile.selectedThemeID
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(StoreManager.shared)
        }
    }
    
    // MARK: - 主题分区
    
    private func themeSection(title: String, themes: [Theme], isPro: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                if isPro {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.bloomGold)
                }
            }
            
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(themes) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: selectedThemeID == theme.id,
                        isPro: userStore.isPro,
                        onTap: { handleThemeTap(theme) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 主题点击处理
    
    private func handleThemeTap(_ theme: Theme) {
        // 如果已选中，不做任何事
        guard selectedThemeID != theme.id else { return }
        
        // 如果是 Pro 主题但未解锁，显示 Paywall
        if theme.isPro && !userStore.isPro {
            showPaywall = true
            return
        }
        
        // 更新主题
        if ThemeManager.shared.setTheme(theme.id, isPro: userStore.isPro) {
            selectedThemeID = theme.id
            userStore.updateThemeID(theme.id)
            Haptics.light()
        }
    }
}

// MARK: - 主题卡片

struct ThemeCard: View {
    let theme: Theme
    let isSelected: Bool
    let isPro: Bool
    let onTap: () -> Void
    
    var isLocked: Bool {
        theme.isPro && !isPro
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 颜色预览
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                    
                    // 植物色调预览
                    if let tint = theme.plantTintColor {
                        Circle()
                            .fill(tint)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            )
                    }
                    
                    // 锁定图标
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // 选中指示器
                    if isSelected && !isLocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                            .padding(4)
                    }
                }
                
                // 主题名称
                VStack(spacing: 2) {
                    Text(theme.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    
                    Text(theme.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isLocked)
    }
}
