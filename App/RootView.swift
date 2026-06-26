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
    
    let loadingPhase: AppLoadingPhase
    
    @State private var contentVisible = false
    @State private var plantFadeIn = false
    @State private var selectedTab: TabItem = .garden
    
    var body: some View {
        Group {
            if userStore.hasCompletedOnboarding {
                mainView
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 20)
            } else {
                OnboardingView()
                    .opacity(contentVisible ? 1 : 0)
                    .offset(y: contentVisible ? 0 : 20)
            }
        }
        .task {
            if userStore.hasCompletedOnboarding {
                await downloadCloudData()
                plantEngine.processOverdueDays()
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                contentVisible = true
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                plantFadeIn = true
            }
        }
    }
    
    private var mainView: some View {
        ZStack(alignment: .bottom) {
            // 内容页面
            TabContent(selectedTab: selectedTab, plantFadeIn: plantFadeIn)
                .ignoresSafeArea()
            
            // Apple 风格底部 TabBar
            AppleTabBar(selectedTab: $selectedTab)
            
            // 网络状态提示
            if !networkMonitor.isConnected {
                VStack {
                    offlineBanner
                    Spacer()
                }
                .padding(.bottom, 56)
            }
            
            // 同步状态提示
            SyncToastView(
                state: cloudSyncManager.syncToastState,
                onDismiss: {
                    cloudSyncManager.resetToastState()
                },
                progress: mapProgress(cloudSyncManager.syncProgress),
                canRetry: canRetrySync,
                showsSettings: showsSettingsButton,
                onRetry: {
                    Task {
                        await cloudSyncManager.retryLastSync()
                    }
                },
                onOpenSettings: {
                    cloudSyncManager.openSystemSettings()
                }
            )
            
            // 成就解锁提示
            if let achievement = achievementStore.newlyUnlocked {
                AchievementCelebrationOverlay(achievement: achievement) {
                    achievementStore.newlyUnlocked = nil
                }
            }
        }
    }
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            Text(NSLocalizedString("离线模式 - 数据已本地保存", comment: "Offline mode - data saved locally"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bloomWarning)
        .clipShape(Capsule())
        .padding(.top, 8)
    }
    
    private var canRetrySync: Bool {
        if case .failed(let error) = cloudSyncManager.syncStatus {
            return error.canRetry
        }
        return false
    }
    
    private var showsSettingsButton: Bool {
        if case .failed(let error) = cloudSyncManager.syncStatus {
            return error.showsSettingsButton
        }
        return false
    }
    
    private func mapProgress(_ progress: CloudSyncManager.SyncProgress?) -> SyncProgressStep {
        guard let progress = progress else { return .downloading }
        switch progress {
        case .downloading: return .downloading
        case .merging: return .merging
        case .uploading: return .uploading
        }
    }
    
    private func downloadCloudData() async {
        if cloudSyncManager.isSyncing { return }
        await cloudSyncManager.syncAll()
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: TabItem
    let plantFadeIn: Bool
    
    var body: some View {
        switch selectedTab {
        case .garden:
            NavigationStack {
                GardenView()
            }
        case .history:
            NavigationStack {
                HistoryView()
            }
        case .collection:
            NavigationStack {
                CollectionView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}
