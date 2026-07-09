//
//  AppleTabBar.swift
//  Bloom
//
//  Apple 风格的底部导航栏
//  基于 Apple Human Interface Guidelines 设计
//

import SwiftUI

// MARK: - Tab Item

enum TabItem: Int, CaseIterable {
    case garden = 0
    case history = 1
    case collection = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .garden: return NSLocalizedString("花园", comment: "Garden tab")
        case .history: return NSLocalizedString("记录", comment: "History tab")
        case .collection: return NSLocalizedString("收藏", comment: "Collection tab")
        case .settings: return NSLocalizedString("设置", comment: "Settings tab")
        }
    }
    
    var icon: String {
        switch self {
        case .garden: return "leaf.fill"
        case .history: return "chart.bar.fill"
        case .collection: return "square.grid.2x2.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var unselectedIcon: String {
        switch self {
        case .garden: return "leaf"
        case .history: return "chart.bar"
        case .collection: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Apple Tab Bar

struct AppleTabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                    Haptics.light()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 0)
        .frame(height: 56)
        .background(
            VisualEffectBlur(blurStyle: .systemThinMaterial)
                .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.bloomBorder)
                .frame(height: 0.5)
        }
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.unselectedIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Color.bloomPrimary : Color.bloomTextTertiary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.bloomPrimary : Color.bloomTextTertiary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Visual Effect Blur (for background blur)

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Frosted Glass Background

struct FrostedGlassBackground: View {
    var opacity: Double = 0.72
    
    var body: some View {
        Color.bloomSurface
            .opacity(opacity)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        AppleTabBar(selectedTab: .constant(.garden))
    }
}
