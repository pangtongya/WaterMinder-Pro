// RootView.swift
// 根视图 —— 根据 onboarding 状态决定显示引导还是主界面

import SwiftUI

struct RootView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var achievementStore: AchievementStore
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        Group {
            if userStore.hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
        .task {
            if userStore.hasCompletedOnboarding {
                await downloadCloudData()
                plantEngine.processOverdueDays()
                // 注意：打开 App 本身不调用 markActiveToday()，
                // 只有用户真正浇水/达标时才标记活跃，确保衰减逻辑正确。
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack { GardenView() }
                .tabItem { Label("花园".localized, systemImage: "leaf.fill") }

            NavigationStack { HistoryView() }
                .tabItem { Label("记录".localized, systemImage: "chart.bar.fill") }

            NavigationStack { CollectionView() }
                .tabItem { Label("收藏".localized, systemImage: "square.grid.2x2.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("设置".localized, systemImage: "gearshape.fill") }
        }
        .tint(themeManager.currentTheme.accent)
        .overlay {
            if !networkMonitor.isConnected {
                offlineBanner
            }
        }
        .overlay(alignment: .top) {
            SyncToastView(state: cloudSyncManager.syncToastState) {
                // 用户手动关闭 Toast（失败状态）→ 重置状态
                cloudSyncManager.resetToastState()
            }
        }
        // 成就解锁庆祝动画（全屏覆盖在最顶层）
        .overlay {
            if let achievement = achievementStore.newlyUnlocked {
                AchievementCelebrationOverlay(achievement: achievement) {
                    achievementStore.newlyUnlocked = nil
                }
            }
        }
    }
    
    private var offlineBanner: some View {
        VStack {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                Text(NSLocalizedString("离线模式 - 数据已本地保存", comment: "Offline mode - data saved locally"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            
            Spacer()
        }
        .transition(.move(edge: .top))
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
    
    private func downloadCloudData() async {
        guard cloudSyncManager.isSyncAvailable else { return }

        // 下载并合并植物数据
        if let cloudPlant = await cloudSyncManager.downloadPlant() {
            plantEngine.mergeWithCloudPlant(cloudPlant)
        }

        // 下载并合并喝水记录
        if let cloudRecords = await cloudSyncManager.downloadWaterRecords() {
            waterStore.mergeWithCloudRecords(cloudRecords)
        }

        // 下载并合并花园数据
        if let cloudItems = await cloudSyncManager.downloadGardenItems() {
            gardenStore.mergeWithCloudItems(cloudItems)
        }
    }
}

// MARK: - 成就解锁庆祝动画（内联以保证编译稳定性）

struct AchievementCelebrationOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    @State private var animateIn = false
    @State private var particles = Array(0..<15)

    var body: some View {
        ZStack {
            // 背景遮罩（半透明）
            Color.black.opacity(animateIn ? 0.55 : 0)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // 庆祝粒子（上升中的星星）
                ZStack {
                    ForEach(particles, id: \.self) { i in
                        Image(systemName: particleSymbol(i))
                            .font(.system(size: CGFloat.random(in: 16...28), weight: .bold))
                            .foregroundStyle(particleColor(i))
                            .opacity(animateIn ? 0 : 1)
                            .offset(y: animateIn ? CGFloat.random(in: -250...(-80)) : 80)
                            .rotationEffect(.degrees(animateIn ? Double.random(in: -90...90) : 0))
                            .animation(
                                Animation.easeOut(duration: Double.random(in: 1.8...2.8))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.08),
                                value: animateIn
                            )
                    }
                }
                .frame(height: 120)

                // 成就图标（大号）
                Image(systemName: achievement.icon)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Color.bloomGold)
                    .frame(width: 120, height: 120)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bloomGold.opacity(0.2), Color.bloomPrimary.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.bloomGold.opacity(0.5), lineWidth: 2)
                            .scaleEffect(animateIn ? 1.3 : 1)
                            .opacity(animateIn ? 0 : 1)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animateIn)
                    )
                    .scaleEffect(animateIn ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateIn)

                // 标题
                VStack(spacing: 8) {
                    Text("🎉 成就解锁！")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text(achievement.title)
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.95))
                    Text(achievement.description)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 32)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                // 关闭按钮
                Button(action: onDismiss) {
                    Text("太棒了！")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 32)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: animateIn)
            }
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 40)
            .overlay(alignment: .topTrailing) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(16)
                }
            }
        }
        .transition(.opacity)
        .animation(.easeOut(duration: 0.35), value: animateIn)
        .onAppear { animateIn = true }
        .onTapGesture { onDismiss() }
    }

    private func particleSymbol(_ index: Int) -> String {
        let symbols = ["sparkle", "star.fill", "leaf.fill", "circle.fill", "diamond.fill"]
        return symbols[index % symbols.count]
    }

    private func particleColor(_ index: Int) -> Color {
        let colors: [Color] = [.bloomGold, .bloomPrimary, .bloomSuccess, .yellow, .orange, .pink]
        return colors[index % colors.count].opacity(Double.random(in: 0.8...1.0))
    }
}
