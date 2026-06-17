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
    func updateGardenProgress(totalHarvests: Int) {
        let gardenIds = ["garden_first_harvest", "garden_5_harvests", "garden_10_harvests",
                        "garden_25_harvests", "garden_50_harvests"]
        
        for id in gardenIds {
            updateProgress(id: id, newProgress: totalHarvests)
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
    
    private func updateProgress(id: String, newProgress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        var achievement = achievements[index]
        
        // 如果已解锁，不更新
        guard !achievement.isUnlocked else { return }
        
        // 更新进度
        achievement.progress = newProgress
        
        // 检查是否达成
        if newProgress >= achievement.requirement {
            achievement.unlockedAt = Date()
            newlyUnlocked = achievement
            
            // 触发通知
            Task {
                try? await Task.sleep(for: .seconds(2))
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
