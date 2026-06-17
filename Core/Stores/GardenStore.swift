// GardenStore.swift
// 花园收藏 —— 收获的植物存档，是长期留存和"收集"心理的载体

import Foundation
import SwiftUI

@MainActor
final class GardenStore: ObservableObject {
    @Published private(set) var items: [GardenItem] = []

    private let storage = PersistenceManager.shared
    private let filename = "garden_collection.json"
    private let cloudSync = CloudSyncManager.shared
    
    /// 防抖同步
    private var syncTask: Task<Void, Never>?
    
    // MARK: - 成就系统集成
    
    var achievementStore: AchievementStore?

    init() {
        items = storage.load([GardenItem].self, filename: filename) ?? []
    }

    /// 收获一株植物时调用
    func add(_ item: GardenItem) {
        items.insert(item, at: 0)
        persist()
        triggerSync()
        updateAchievements()
    }

    /// 花园中收集到的品种数
    var uniqueSpeciesCount: Int {
        Set(items.map { $0.speciesID }).count
    }

    /// 花园总数
    var totalCount: Int { items.count }

    /// 某品种是否已收集过
    func hasCollected(speciesID: String) -> Bool {
        items.contains { $0.speciesID == speciesID }
    }

    private func persist() {
        storage.save(items, filename: filename)
    }
    
    /// 触发 iCloud 同步（防抖 3 秒）
    private func triggerSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await cloudSync.syncGardenItems(items)
        }
    }
    
    /// 更新成就进度（在收获后调用）
    private func updateAchievements() {
        guard let achievementStore = achievementStore else { return }
        
        // 更新花园成就（总收获次数）
        achievementStore.updateGardenProgress(totalHarvests: items.count)
    }

    // MARK: - 云端数据合并
    
    /// 合并云端花园数据（去重）
    func mergeWithCloudItems(_ cloudItems: [GardenItem]) {
        let existingIDs = Set(items.map(\.id))
        let newItems = cloudItems.filter { !existingIDs.contains($0.id) }
        if !newItems.isEmpty {
            items.append(contentsOf: newItems)
            items.sort { $0.harvestedAt > $1.harvestedAt }
            persist()
            triggerSync()
        }
    }

    // MARK: - 备份恢复
    
    /// 替换所有花园项（用于恢复备份）
    func replaceAllItems(with newItems: [GardenItem]) {
        items = newItems
        persist()
    }
    // MARK: - Pro 功能限制
    
    /// 免费用户花园数量上限
    static let freeUserGardenLimit = 5
    
    /// 检查是否可以收获新植物
    func canHarvest(isPro: Bool) -> (allowed: Bool, current: Int, limit: Int) {
        let current = items.count
        
        // Pro 用户无限制
        if isPro {
            return (true, current, Int.max)
        }
        
        // 免费用户有限制
        let allowed = current < Self.freeUserGardenLimit
        return (allowed, current, Self.freeUserGardenLimit)
    }
    
    /// 获取花园使用状态描述
    func gardenStatusDescription(isPro: Bool) -> String {
        let status = canHarvest(isPro: isPro)
        
        if isPro {
            return "花园: \(status.current) 株 (无限制)"
        } else {
            return "花园: \(status.current)/\(status.limit) 株"
        }
    }
}
