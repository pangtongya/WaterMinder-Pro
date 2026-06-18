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
            print("[BackgroundTask] 健康衰减任务已调度")
        } catch {
            print("[BackgroundTask] 调度健康衰减任务失败: \(error)")
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
            print("[BackgroundTask] 调度Widget刷新任务失败: \(error)")
        }
    }

    // MARK: - 任务处理

    private func handleHealthDecayTask(_ task: BGAppRefreshTask) {
        // 重新调度下一次
        scheduleHealthDecayTask()

        // 设置超时
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // 计算离线时间并应用衰减
        let lastActiveKey = AppConstants.UserDefaultsKeys.lastActiveDate
        if let lastActiveInterval = UserDefaults.standard.object(forKey: lastActiveKey) as? TimeInterval {
            let lastActiveDate = Date(timeIntervalSince1970: lastActiveInterval)
            let hoursSinceLastActive = Calendar.current.dateComponents([.hour], from: lastActiveDate, to: Date()).hour ?? 0

            if hoursSinceLastActive >= 1 {
                // 在后台任务中直接加载并修改植物状态
                Task { @MainActor in
                    let engine = PlantEngine()
                    engine.applyOfflineDecay(hours: hoursSinceLastActive)

                    // 更新 Widget 数据
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
            }
        }

        task.setTaskCompleted(success: true)
    }

    private func handleWidgetRefreshTask(_ task: BGAppRefreshTask) {
        scheduleWidgetRefreshTask()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // 在后台任务中直接读取最新数据写入 App Group
        Task { @MainActor in
            let waterStore = WaterStore()
            let plantEngine = PlantEngine()
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
        }
        task.setTaskCompleted(success: true)
    }
}

// MARK: - Notification Names（已迁移到 AppConstants.NotificationNames，保留向后兼容）

extension Notification.Name {
    static let applyOfflineDecay = AppConstants.NotificationNames.applyOfflineDecay
}
