// AchievementStore.swift
// 成就管理 Store —— 追踪进度、解锁成就

import Foundation
import SwiftUI

@MainActor
final class AchievementStore: ObservableObject {
    @Published private(set) var achievements: [Achievement] = []
    @Published var newlyUnlocked: Achievement? // 用于显示解锁动画
    
    private let storage = PersistenceManager.shared
    private let filename = "achievements.json"
    private let cloudSync = CloudSyncManager.shared
    
    private var syncTask: Task<Void, Never>?
    
    init() {
        loadAchievements()
    }
    
    // MARK: - 加载成就
    
    private func loadAchievements() {
        if let saved = storage.load([Achievement].self, filename: filename) {
            achievements = saved
        } else {
            // 首次初始化所有成就
            achievements = AchievementLibrary.allAchievements()
            persist()
        }
    }
    
    // MARK: - 更新进度
    
    /// 更新喝水相关成就进度
    func updateHydrationProgress(totalRecords: Int, totalAmount: Int) {
        let achievementIds = [
            "hydration_first", "hydration_10", "hydration_50",
            "hydration_100", "hydration_500", "hydration_1000"
        ]
        
        for id in achievementIds {
            updateProgress(id: id, newProgress: totalRecords)
        }
        
        // 更新里程碑（总水量）
        let milestoneIds = ["milestone_10000ml", "milestone_50000ml", "milestone_100000ml"]
        for id in milestoneIds {
            updateProgress(id: id, newProgress: totalAmount)
        }
    }
    
    /// 更新连续天数成就进度
    func updateStreakProgress(currentStreak: Int) {
        let streakIds = ["streak_3", "streak_7", "streak_14", "streak_30", "streak_60", "streak_100"]
        
        for id in streakIds {
            updateProgress(id: id, newProgress: currentStreak)
        }
    }
    
    /// 更新花园成就进度
    func updateGardenProgress(totalHarvests: Int, uniqueSpecies: Int) {
        let harvestIds = ["garden_first_harvest", "garden_5_harvests", "garden_10_harvests",
                        "garden_25_harvests", "garden_50_harvests"]

        for id in harvestIds {
            updateProgress(id: id, newProgress: totalHarvests)
        }

        // 品种收集成就
        let speciesIds = ["garden_5_species", "garden_10_species", "garden_all_species"]
        for id in speciesIds {
            updateProgress(id: id, newProgress: uniqueSpecies)
        }
    }
    
    /// 更新社交成就进度
    func updateSocialProgress(totalShares: Int) {
        let socialIds = ["social_first_share", "social_10_shares"]
        
        for id in socialIds {
            updateProgress(id: id, newProgress: totalShares)
        }
    }
    
    // MARK: - 进度更新核心逻辑
    /// 关键策略：进度只增不减（取更大值），避免删除记录导致成就被撤销
    private func updateProgress(id: String, newProgress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        var achievement = achievements[index]
        
        // 如果已解锁，绝对不再更新（用户的成就永远保留，哪怕记录被删除也不撤销）
        guard !achievement.isUnlocked else { return }
        
        // 取现有进度与新进度的较大值——保证成就进度"只增不减"
        // 例：用户累计喝了100次水 → 获得 hydration_100 → 删除50条记录 → 仍保留100
        let actualProgress = max(achievement.progress, newProgress)
        guard actualProgress != achievement.progress else {
            return  // 进度没变，无需保存
        }
        achievement.progress = actualProgress
        
        // 检查是否达成
        if actualProgress >= achievement.requirement {
            achievement.unlockedAt = Date()
            newlyUnlocked = achievement
            
            // 触发通知（延迟 3s 以提供更慢消失）
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    newlyUnlocked = nil
                }
            }
        }
        
        achievements[index] = achievement
        persist()
    }
    
    // MARK: - 查询
    
    /// 获取某个分类的成就
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
    
    /// 已解锁的成就数量
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    /// 总成就数量
    var totalCount: Int {
        achievements.count
    }
    
    /// 解锁百分比
    var unlockPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount) * 100
    }

    // MARK: - 云同步/备份恢复

    /// 合并云端/备份成就数据（以本地为准，合并新解锁和更高进度）
    func mergeWithCloudAchievements(_ cloudAchievements: [Achievement]) {
        var updated = false
        for cloudAchievement in cloudAchievements {
            guard let localIndex = achievements.firstIndex(where: { $0.id == cloudAchievement.id }) else {
                // 本地没有这个成就 → 直接添加
                achievements.append(cloudAchievement)
                updated = true
                continue
            }
            var local = achievements[localIndex]
            // 如果云端已解锁且本地没有，使用云端解锁时间
            if cloudAchievement.isUnlocked && !local.isUnlocked {
                local.unlockedAt = cloudAchievement.unlockedAt
                local.progress = cloudAchievement.requirement
                achievements[localIndex] = local
                updated = true
            } else {
                // 取更高的进度
                if cloudAchievement.progress > local.progress {
                    local.progress = cloudAchievement.progress
                    achievements[localIndex] = local
                    updated = true
                }
                // 取更早的解锁时间（保留最早解锁记录）
                if let localUnlocked = local.unlockedAt,
                   let cloudUnlocked = cloudAchievement.unlockedAt,
                   cloudUnlocked < localUnlocked {
                    local.unlockedAt = cloudUnlocked
                    achievements[localIndex] = local
                    updated = true
                }
            }
        }
        if updated {
            persist()
        }
    }

    /// 用备份/云端成就替换所有本地成就
    func replaceAllAchievements(with newAchievements: [Achievement]) {
        // 如果备份是空的，则保留默认库，避免数据丢失
        guard !newAchievements.isEmpty else { return }
        achievements = newAchievements
        persist()
    }
    
    // MARK: - 持久化
    
    private func persist() {
        storage.save(achievements, filename: filename)
        triggerSync()
    }
    
    private func triggerSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await cloudSync.syncAchievements(achievements)
        }
    }
}
