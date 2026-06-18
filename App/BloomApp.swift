// BloomApp.swift
// @main 入口 —— 阶段1 最小骨架，阶段3 重写完整根视图

import SwiftUI

@main
struct BloomApp: App {
    // 关键 store：立即加载（决定显示引导还是主界面）
    @StateObject private var userStore = UserStore()
    
    // 其他 store：在 .task 中异步初始化
    @StateObject private var waterStore = WaterStore()
    @StateObject private var plantEngine = PlantEngine()
    @StateObject private var gardenStore = GardenStore()
    @StateObject private var achievementStore = AchievementStore()
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var healthManager = HealthManager.shared
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var healthSyncService = HealthSyncService.shared
    
    @State private var isReady = false
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 注册后台任务（尽早注册）
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isReady {
                    // 启动屏幕：显示品牌色，避免白屏
                    Color(.systemBackground)
                } else {
                    RootView()
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
                // 异步完成所有初始化
                await initializeApp()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    // App 进入后台时调度后台任务
                    BackgroundTaskManager.shared.scheduleHealthDecayTask()
                    BackgroundTaskManager.shared.scheduleWidgetRefreshTask()
                }
            }
        }
    }

    /// 异步初始化所有依赖
    @MainActor
    private func initializeApp() async {
        // 1. 注入 store 间的依赖
        wireStores()

        // 2. 加载保存的主题
        themeManager.loadSavedTheme(isPro: userStore.isPro)

        // 3. 数据归档（启动时检查，超过 90 天的旧记录移至归档文件）
        waterStore.autoArchiveIfNeeded()

        // 4. 请求 HealthKit 授权（仅在未决定时弹窗）
        await healthManager.requestAuthorizationIfNeeded()

        // 5. 同步 HealthKit 数据（如果有权限）
        if healthManager.isAuthorized {
            await healthSyncService.sync(waterStore: waterStore, plantEngine: plantEngine)
        }

        // 6. 标记就绪（显示 RootView）
        isReady = true
    }
    
    /// 注入 store 间的依赖（目标、Pro 状态）
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
        
        // 注入 CloudSync 依赖
        cloudSyncManager.isProProvider = { [weak userStore] in
            userStore?.isPro ?? false
        }
        
        // 注入成就系统依赖
        waterStore.achievementStore = achievementStore
        gardenStore.achievementStore = achievementStore
        SharingManager.shared.achievementStore = achievementStore
    }
}
