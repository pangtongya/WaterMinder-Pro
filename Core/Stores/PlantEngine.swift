import WidgetKit
// PlantEngine.swift
// ⭐ 植物生命引擎 —— 整个 app 的心脏
//
// 职责：把 PlantLifecycle（纯函数）与持久化状态粘合，
// 对外暴露语义化动作：喝水、每日结算、枯萎检查、收获、种新植物。
// UI 层只调用这些动作，不直接碰生命周期算法。

import Foundation
import SwiftUI

@MainActor
final class PlantEngine: ObservableObject {
    @Published private(set) var plant: Plant

    /// 最近一次阶段升级到的目标阶段（用于驱动庆祝动画）
    @Published private(set) var lastStageUpCelebration: GrowthStage?

    private let storage = PersistenceManager.shared
    private let filename = "current_plant.json"
    private let cloudSync = CloudSyncManager.shared

    /// 达标奖励发放记录的日期（按日期持久化，防止重启/跨天重复发放）
    private let goalBonusDateKey = "bloom.goalBonusDate"
    
    /// 防抖同步
    private var syncTask: Task<Void, Never>?

    init() {
        plant = storage.load(Plant.self, filename: filename) ?? Plant()
    }

    /// 今天是否已发放达标奖励（对比存储的日期是否为今天）
    var goalBonusAppliedToday: Bool {
        isSameDayAsStoredGoalBonus(Date())
    }

    // MARK: - 喝水（核心即时反馈）

    /// 用户喝水后调用 —— 植物立刻恢复生机 + 累积成长
    @discardableResult
    func water(amount: Int) -> GrowthStage? {
        let oldStage = plant.stage
        plant = PlantLifecycle.applyWatering(plant, amount: amount)
        markActiveToday()
        persist()
        triggerSync()

        // 阶段升级 → 触发庆祝
        if plant.stage.rawValue > oldStage.rawValue {
            lastStageUpCelebration = plant.stage
            return plant.stage
        }
        return nil
    }

    /// 今日达标时调用（由 UI 层根据 WaterStore.isGoalMetToday 驱动）
    func processGoalMet() {
        guard !goalBonusAppliedToday else { return }
        let oldStage = plant.stage
        plant = PlantLifecycle.applyDailyGoalMet(plant)
        markGoalBonusApplied()
        markActiveToday()
        persist()
        triggerSync()

        if plant.stage.rawValue > oldStage.rawValue {
            lastStageUpCelebration = plant.stage
        }
    }

    // MARK: - 每日结算（app 启动 / 跨天时调用）

    /// 检查自上次结算以来断水的天数，应用衰减
    func processOverdueDays() {
        // 自动恢复：暂停超过14天 → 自动解除暂停
        if plant.isPauseExpired {
            resumeCare()
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastActive = lastActiveDay

        guard lastActive < today else {
            // 今天已经活跃过，无需结算
            return
        }

        // 计算中间断水的天数
        let gap = cal.dateComponents([.day], from: lastActive, to: today).day ?? 0
        if gap > 0 {
            // gap 天未达标（每一天都算断水）
            // 暂停养护期间 PlantLifecycle.applyDailyDecay 已跳过，这里不再检查
            plant = PlantLifecycle.applyDailyDecay(plant, consecutiveMissedDays: gap)

            // 健康度归零 → 枯萎重置
            if plant.health <= 0 {
                plant = PlantLifecycle.wilt(plant)
            }
        }
        lastActiveDay = today
        persist()
        triggerSync()
    }

    /// 喝水/打开 app 时标记今天活跃
    func markActiveToday() {
        lastActiveDay = Calendar.current.startOfDay(for: Date())
    }

    // MARK: - 收获

    /// 收获成熟植物，返回 garden item；由 GardenStore 接收
    func harvest() -> GardenItem? {
        guard plant.canHarvest else { return nil }
        let (item, reset) = PlantLifecycle.harvest(plant)
        plant = reset
        persist()
        triggerSync()
        return item
    }

    // MARK: - 种新植物

    func plantNew(speciesID: String, name: String) {
        plant = Plant(name: name, speciesID: speciesID, stage: .seed, health: 70)
        lastActiveDay = Calendar.current.startOfDay(for: Date())
        persist()
        triggerSync()
    }

    func rename(to name: String) {
        plant.name = name
        persist()
        triggerSync()
    }

    // MARK: - 暂停/恢复养护
    
    /// 暂停养护（出差/旅游模式）
    func pauseCare() {
        plant.isPaused = true
        plant.pausedAt = Date()
        persist()
        triggerSync()
    }
    
    /// 恢复养护
    func resumeCare() {
        plant.isPaused = false
        plant.pausedAt = nil
        persist()
        triggerSync()
    }

    // MARK: - 庆祝动画消费

    /// UI 取走庆祝事件后调用，避免重复弹出
    func consumeStageUpCelebration() {
        lastStageUpCelebration = nil
    }

    // MARK: - 私有

    private func persist() {
        storage.save(plant, filename: filename)
    }
    
    /// 触发 iCloud 同步（防抖 3 秒）
    private func triggerSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await cloudSync.syncPlant(plant)
        }
    }

    private func markGoalBonusApplied() {
        UserDefaults.standard.set(
            Calendar.current.startOfDay(for: Date()),
            forKey: goalBonusDateKey
        )
    }

    private func isSameDayAsStoredGoalBonus(_ date: Date) -> Bool {
        guard let stored = UserDefaults.standard.object(forKey: goalBonusDateKey) as? Date else {
            return false
        }
        return Calendar.current.isDate(stored, inSameDayAs: date)
    }

    /// 上次活跃日（跨天结算用）
    private var lastActiveDay: Date {
        get {
            UserDefaults.standard.object(forKey: "bloom.lastActiveDay") as? Date
                ?? Calendar.current.startOfDay(for: Date())
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "bloom.lastActiveDay")
        }
    }

    // MARK: - 云端数据合并
    
    /// 合并云端植物数据（取较新的）
    func mergeWithCloudPlant(_ cloudPlant: Plant) {
        if let cloudLastWatered = cloudPlant.lastWateredAt,
           let localLastWatered = plant.lastWateredAt {
            if cloudLastWatered > localLastWatered {
                plant = cloudPlant
                persist()
            }
        } else if cloudPlant.lastWateredAt != nil {
            plant = cloudPlant
            persist()
        }
    }

    // MARK: - 备份恢复
    
    /// 替换植物数据（用于恢复备份）
    func replacePlant(with newPlant: Plant) {
        plant = newPlant
        persist()
    }
}
