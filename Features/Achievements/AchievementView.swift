// AchievementView.swift
// 成就页面 —— 展示所有成就和进度

import SwiftUI

struct AchievementView: View {
    @EnvironmentObject var achievementStore: AchievementStore
    @State private var selectedCategory: AchievementCategory = .hydration
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 总体进度
                overallProgressCard
                
                // 分类选择器
                categorySelector
                
                // 成就列表
                achievementList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.achievements)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if let achievement = achievementStore.newlyUnlocked {
                AchievementUnlockOverlay(achievement: achievement) {
                    withAnimation(.spring(response: 0.4)) {
                        // Auto dismiss
                    }
                }
            }
        }
    }
    
    // MARK: - 总体进度卡片
    
    private var overallProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("成就进度".localized)
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(achievementStore.unlockedCount) / \(achievementStore.totalCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.bloomPrimary)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    
                    Circle()
                        .trim(from: 0, to: achievementStore.unlockPercentage / 100.0)
                        .stroke(Color.bloomPrimary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(achievementStore.unlockPercentage))%")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(width: 60, height: 60)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 分类选择器
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 成就列表
    
    private var achievementList: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 16
        ) {
            ForEach(achievementStore.achievements(for: selectedCategory)) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

// MARK: - 分类按钮

struct CategoryButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.bloomPrimary : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .hydration: return "drop.fill"
        case .streak: return "calendar.badge.checkmark"
        case .garden: return "leaf.fill"
        case .social: return "square.and.arrow.up"
        case .milestone: return "trophy.fill"
        }
    }
}

// MARK: - 成就卡片

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.bloomPrimary.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .bloomPrimary : .gray)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text(achievement.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 进度条
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progressPercentage)
                    .tint(.bloomPrimary)
                
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已解锁".localized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - 成就解锁动画

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    let dismiss: () -> Void

    /// 控制 overlay 显隐的动画状态
    @State private var isVisible = true

    /// 5 秒自动关闭定时器
    /// 用户也可以通过点击背景或"太棒了"按钮提前关闭
    private let autoDismissSeconds: Double = 5.0

    var body: some View {
        ZStack {
            // 半透明黑色背景（点击任意处关闭）
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismissAnimated() }

            // 成就卡片
            VStack(spacing: 20) {
                // 动画图标
                Image(systemName: achievement.icon)
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.spring(response: 0.4).delay(0.2), value: isVisible)

                Text(L.achievementUnlocked)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(achievement.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(achievement.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                // 进度指示器（倒计时）
                countdownBar

                Button(L.amazing) {
                    dismissAnimated()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.bloomPrimary)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(40)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 40)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            // 5 秒后自动淡出
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissSeconds) {
                dismissAnimated()
            }
        }
    }

    /// 倒计时进度条（UI 反馈）
    private var countdownBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width, height: 4)
                    .animation(.linear(duration: autoDismissSeconds), value: isVisible)
                    .scaleEffect(x: isVisible ? 1 : 0, y: 1, anchor: .leading)
            }
        }
        .frame(height: 4)
    }

    /// 带动画效果的关闭（淡出 + 缩放）
    private func dismissAnimated() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        // 等待动画完成后调用实际 dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// // #Preview {
//     NavigationStack {
//         AchievementView()
//             .environmentObject(AchievementStore())
//     }
