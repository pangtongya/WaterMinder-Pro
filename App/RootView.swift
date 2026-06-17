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

#Preview {
    RootView()
        .environmentObject(UserStore())
        .environmentObject(PlantEngine())
        .environmentObject(WaterStore())
        .environmentObject(GardenStore())
        .environmentObject(CloudSyncManager.shared)
}
