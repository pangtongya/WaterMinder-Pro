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
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack(spacing: 20) {
                // 动画图标
                Image(systemName: achievement.icon)
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.4).delay(0.2), value: achievement)
                
                Text("成就解锁！".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(achievement.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("太棒了！".localized) {
                    dismiss()
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
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: achievement)
    }
}

#Preview {
    NavigationStack {
        AchievementView()
            .environmentObject(AchievementStore())
    }
}
