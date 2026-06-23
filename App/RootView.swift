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
    
    var body: some View {
        Group {
            if userStore.hasCompletedOnboarding {
                mainTabs
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

    private var mainTabs: some View {
        TabView {
            NavigationStack { GardenView(plantFadeIn: plantFadeIn) }
                .tabItem { Label(L.myGarden, systemImage: "leaf.fill") }

            NavigationStack { HistoryView() }
                .tabItem { Label(L.waterLog, systemImage: "chart.bar.fill") }

            NavigationStack { CollectionView() }
                .tabItem { Label(L.myGarden, systemImage: "square.grid.2x2.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label(L.settings, systemImage: "gearshape.fill") }
        }
        .tint(themeManager.currentTheme.accent)
        .overlay {
            if !networkMonitor.isConnected {
                offlineBanner
            }
        }
        .overlay(alignment: .top) {
            SyncToastView(
                state: cloudSyncManager.syncToastState,
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
            ) {
                cloudSyncManager.resetToastState()
            }
        }
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

        if let cloudPlant = await cloudSyncManager.downloadPlant() {
            plantEngine.mergeWithCloudPlant(cloudPlant)
        }

        if let cloudRecords = await cloudSyncManager.downloadWaterRecords() {
            waterStore.mergeWithCloudRecords(cloudRecords)
        }

        if let cloudItems = await cloudSyncManager.downloadGardenItems() {
            gardenStore.mergeWithCloudItems(cloudItems)
        }
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
    
    private func mapProgress(_ progress: CloudSyncManager.SyncProgress) -> SyncProgressStep {
        switch progress {
        case .downloading: return .downloading
        case .merging: return .merging
        case .uploading: return .uploading
        }
    }
}
