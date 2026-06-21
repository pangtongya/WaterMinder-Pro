// BackgroundTaskManager.swift
// 后台任务调度器 —— 管理植物健康衰减的定时任务

import BackgroundTasks
import Foundation
import WidgetKit

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    /// 后台任务标识符
    static let healthDecayTaskIdentifier = "com.pangtong.bloom.healthDecay"
    static let widgetRefreshTaskIdentifier = "com.pangtong.bloom.widgetRefresh"

    private init() {}

    // MARK: - 注册后台任务

    /// 注册所有后台任务
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.healthDecayTaskIdentifier,
            using: nil
        ) { task in
            self.handleHealthDecayTask(task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.widgetRefreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleWidgetRefreshTask(task as! BGAppRefreshTask)
        }
    }

    // MARK: - 调度任务

    /// 调度健康衰减后台任务
    func scheduleHealthDecayTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.healthDecayTaskIdentifier)
        // 1小时后执行，给用户时间打开app
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[BackgroundTask] 健康衰减任务已调度")
            #endif
        } catch {
            #if DEBUG
            print("[BackgroundTask] 调度健康衰减任务失败: \(error)")
            #endif
        }
    }

    /// 调度 Widget 刷新任务
    func scheduleWidgetRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.widgetRefreshTaskIdentifier)
        // 15分钟后执行
        request.earliestBeginDate = Date(timeIntervalSinceNow: 900)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("[BackgroundTask] 调度Widget刷新任务失败: \(error)")
            #endif
        }
    }

    // MARK: - 任务处理

    private func handleHealthDecayTask(_ task: BGAppRefreshTask) {
        // 重新调度下一次（每次进入后台都会被重新排队）
        scheduleHealthDecayTask()

        // 标记当前时刻为 lastActiveDate（避免下次再以同一基准算衰减）
        let lastActiveKey = AppConstants.UserDefaultsKeys.lastActiveDate
        let nowInterval = Date().timeIntervalSince1970
        let nowDate = Date()

        // 计算离线时间并应用衰减
        let hoursSinceLastActive: Int
        if let lastActiveInterval = UserDefaults.standard.object(forKey: lastActiveKey) as? TimeInterval {
            let lastActiveDate = Date(timeIntervalSince1970: lastActiveInterval)
            hoursSinceLastActive = Calendar.current.dateComponents([.hour], from: lastActiveDate, to: nowDate).hour ?? 0
        } else {
            // 首次安装，没有之前的活跃时间 → 不应用衰减
            hoursSinceLastActive = 0
        }

        // 用 Task 提交到主线程完成 IO / 植物状态修改
        Task { @MainActor in
            defer { task.setTaskCompleted(success: true) }

            // 1. 应用离线衰减
            if hoursSinceLastActive >= 1 {
                let engine = PlantEngine.shared
                engine.applyOfflineDecay(hours: hoursSinceLastActive)

                let waterStore = WaterStore()
                let userStore = UserStore()
                WidgetDataManager.shared.updateWidgetData(
                    currentIntake: waterStore.todayTotal,
                    dailyGoal: userStore.dailyGoal,
                    plantName: engine.plant.name,
                    plantHealth: engine.plant.health,
                    plantStageRawValue: engine.plant.stage.rawValue,
                    plantSymbol: engine.plant.species.symbol,
                    isPaused: engine.plant.isPaused
                )
                WidgetCenter.shared.reloadAllTimelines()
            }

            // 2. 重新写入 lastActiveDate（避免下一次后台任务再用同一基准时间衰减）
            UserDefaults.standard.set(nowInterval, forKey: lastActiveKey)
        }

        // 若系统在异步任务完成前要求超时 → 立即标记完成
        task.expirationHandler = {
            // 重新写入当前时间，避免未完成的任务导致重复衰减
            UserDefaults.standard.set(nowInterval, forKey: lastActiveKey)
            task.setTaskCompleted(success: false)
        }
    }

    private func handleWidgetRefreshTask(_ task: BGAppRefreshTask) {
        scheduleWidgetRefreshTask()

        let lastActiveKey = AppConstants.UserDefaultsKeys.lastActiveDate
        let nowInterval = Date().timeIntervalSince1970

        Task { @MainActor in
            defer { task.setTaskCompleted(success: true) }

            // 仅刷新 Widget 数据，不修改植物状态
            let waterStore = WaterStore()
            let plantEngine = PlantEngine.shared
            let userStore = UserStore()

            WidgetDataManager.shared.updateWidgetData(
                currentIntake: waterStore.todayTotal,
                dailyGoal: userStore.dailyGoal,
                plantName: plantEngine.plant.name,
                plantHealth: plantEngine.plant.health,
                plantStageRawValue: plantEngine.plant.stage.rawValue,
                plantSymbol: plantEngine.plant.species.symbol,
                isPaused: plantEngine.plant.isPaused
            )
            WidgetCenter.shared.reloadAllTimelines()

            // 写入 lastActiveDate，保持时间基准一致
            UserDefaults.standard.set(nowInterval, forKey: lastActiveKey)
        }

        task.expirationHandler = {
            UserDefaults.standard.set(nowInterval, forKey: lastActiveKey)
            task.setTaskCompleted(success: false)
        }
    }
}

// MARK: - Notification Names（已迁移到 AppConstants.NotificationNames，保留向后兼容）

extension Notification.Name {
    static let applyOfflineDecay = AppConstants.NotificationNames.applyOfflineDecay
}
