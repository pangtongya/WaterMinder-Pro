// BloomApp.swift
// @main 入口 —— 阶段1 最小骨架，阶段3 重写完整根视图

import SwiftUI
import WidgetKit
import Combine

enum AppLoadingPhase {
    case initial
    case coreDataLoaded
    case highPriorityLoaded
    case fullyLoaded
}

@main
struct BloomApp: App {
    // 单例 store：用 @ObservedObject 共享同一个实例，避免 SwiftUI 错误地假设拥有生命周期
    @ObservedObject private var userStore = UserStore.shared
    @ObservedObject private var waterStore = WaterStore.shared
    @ObservedObject private var plantEngine = PlantEngine.shared
    @StateObject private var gardenStore = GardenStore()
    @StateObject private var achievementStore = AchievementStore()

    // 单例 manager：用 @ObservedObject 避免 SwiftUI 错误地假设拥有它们
    @ObservedObject private var storeManager = StoreManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var cloudSyncManager = CloudSyncManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var healthSyncService = HealthSyncService.shared
    
    @State private var loadingPhase: AppLoadingPhase = .initial
    @State private var showLaunchScreen = true
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    Color(.systemBackground)
                        .transition(.opacity)
                        .zIndex(1)
                }

                Group {
                    switch loadingPhase {
                    case .initial, .coreDataLoaded:
                        Color(.systemBackground)
                    case .highPriorityLoaded, .fullyLoaded:
                        RootView(loadingPhase: loadingPhase)
                    }
                }
                .environmentObject(userStore)
                .environmentObject(waterStore)
                .environmentObject(plantEngine)
                .environmentObject(gardenStore)
                .environmentObject(achievementStore)
                .environmentObject(storeManager)
                .environmentObject(notificationManager)
                .environmentObject(healthManager)
                .environmentObject(cloudSyncManager)
                .environmentObject(themeManager)
                .environmentObject(healthSyncService)
                .preferredColorScheme(userStore.colorScheme)
                .environment(\.scenePhase, scenePhase)
                .task {
                    await initializeApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: AppConstants.NotificationNames.refreshWidget)) { _ in
                    WidgetRefresher.shared.refresh(
                        waterStore: waterStore,
                        userStore: userStore,
                        plantEngine: plantEngine
                    )
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background {
                        UserDefaults.standard.set(
                            Date().timeIntervalSince1970,
                            forKey: AppConstants.UserDefaultsKeys.lastActiveDate
                        )
                        BackgroundTaskManager.shared.scheduleHealthDecayTask()
                        BackgroundTaskManager.shared.scheduleWidgetRefreshTask()
                    } else if newPhase == .active {
                        plantEngine.processOverdueDays()
                        Task { @MainActor in
                            if healthSyncService.shouldAutoSync() {
                                await healthSyncService.sync(waterStore: waterStore, plantEngine: plantEngine)
                            }
                        }
                        WidgetRefresher.shared.refresh(
                            waterStore: waterStore,
                            userStore: userStore,
                            plantEngine: plantEngine
                        )
                        WidgetCenter.shared.reloadAllTimelines()
                        if userStore.reminderEnabled {
                            Task {
                                await notificationManager.requestAuthorizationIfNeeded()
                                await notificationManager.scheduleSmartReminder(
                                    intervalMinutes: userStore.reminderInterval,
                                    health: plantEngine.plant.health,
                                    plantName: plantEngine.plant.name,
                                    isPaused: plantEngine.plant.isPaused
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func initializeApp() async {
        wireStores()
        waterStore.autoArchiveIfNeeded()
        themeManager.loadSavedTheme(isPro: userStore.isPro)
        
        if healthSyncService.shouldAutoSync() {
            await healthSyncService.sync(waterStore: waterStore, plantEngine: plantEngine)
        }
        
        WidgetRefresher.shared.refresh(
            waterStore: waterStore,
            userStore: userStore,
            plantEngine: plantEngine
        )
        
        if userStore.reminderEnabled {
            await notificationManager.requestAuthorizationIfNeeded()
            await notificationManager.scheduleSmartReminder(
                intervalMinutes: userStore.reminderInterval,
                health: plantEngine.plant.health,
                plantName: plantEngine.plant.name,
                isPaused: plantEngine.plant.isPaused
            )
        }
        
        achievementStore.refreshFromCurrentRecords(
            totalRecords: waterStore.records.count,
            totalAmount: waterStore.records.reduce(0) { $0 + $1.amount },
            longestStreak: waterStore.longestStreak
        )
        
        loadingPhase = .fullyLoaded
        try? await Task.sleep(nanoseconds: 400_000_000)
        showLaunchScreen = false
    }
    
    @MainActor
    private func wireStores() {
        waterStore.dailyGoalProvider = { [weak userStore] in
            userStore?.dailyGoal ?? 2000
        }
        storeManager.isProProvider = { [weak userStore] in
            userStore?.isPro ?? false
        }
        storeManager.onProUnlocked = { [weak userStore] productID in
            userStore?.unlockPro(productID: productID)
        }
        storeManager.onProRevoked = { [weak userStore] in
            userStore?.revokePro()
        }
        
        // 注入 CloudSync 依赖
        cloudSyncManager.isProProvider = { [weak userStore] in
            userStore?.isPro ?? false
        }
        
        // 注入成就系统依赖
        waterStore.achievementStore = achievementStore
        waterStore.healthManager = healthManager
        waterStore.healthSyncService = healthSyncService
        gardenStore.achievementStore = achievementStore
        SharingManager.shared.achievementStore = achievementStore
    }
}
