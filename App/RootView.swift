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
                plantEngine.markActiveToday()
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
