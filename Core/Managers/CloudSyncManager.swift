// CloudSyncManager.swift
// iCloud 同步管理器 —— 使用 CloudKit 同步所有用户数据
//
// 设计原则：
// - 本地优先：所有读写先操作本地，后台静默同步
// - Pro 用户才启用同步（但技术上不限制，免费用户也能用）
// - 冲突解决：以最新修改时间为准（lastModified）
// - 所有数据同步：WaterRecord + Plant + Garden + UserProfile

import Foundation
import CloudKit
import SwiftUI

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    /// 同步是否可用（用户已登录 iCloud）
    @Published private(set) var isSyncAvailable = false
    
    /// 是否正在同步
    @Published private(set) var isSyncing = false
    
    /// 最后一次同步时间
    @Published private(set) var lastSyncDate: Date?
    
    /// 同步错误信息
    @Published private(set) var lastError: String?

    /// 基于现有状态自动计算的 Toast 显示状态
    /// RootView 监听此属性即可，无需订阅多个 @Published
    @Published private(set) var syncToastState: SyncToastState = .idle

    /// Toast 自动消失计时器（防止 syncToastState 一直停留在 success/failed）
    private var toastResetTimer: Timer?

    /// 重置 Toast 状态为 idle（在 Toast 视图关闭后调用）
    func resetToastState() {
        syncToastState = .idle
    }

    private func showSyncToast(_ state: SyncToastState) {
        toastResetTimer?.invalidate()
        syncToastState = state

        // 成功状态：4 秒后自动回到 idle（3 秒 toast 显示 + 0.35 秒动画 + 0.65 秒缓冲）
        if case .success = state {
            toastResetTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.syncToastState = .idle
                }
            }
        }
        // 失败状态：不自动消失，等用户手动点关闭
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let containerName = "iCloud.com.pangtong.bloom"
    
    /// 用户是否有权使用同步（Pro 用户）
    var isProProvider: () -> Bool = { false }
    
    private init() {
        container = CKContainer(identifier: containerName)
        database = container.privateCloudDatabase
        
        // 监听 iCloud 账号状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAccountStatus),
            name: NSNotification.Name.CKAccountChanged,
            object: nil
        )
        
        Task {
            checkAccountStatus()
        }
    }
    
    // MARK: - 账号状态检查
    
    @objc func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    isSyncAvailable = (status == .available)
                }
            } catch {
                print("[CloudSync] 账号状态检查失败: \(error)")
                await MainActor.run {
                    isSyncAvailable = false
                }
            }
        }
    }
    
    // MARK: - 数据同步
    
    /// 同步喝水记录
    func syncWaterRecords(_ records: [WaterRecord]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            showSyncToast(.syncing)
        }

        do {
            let cloudRecords: [WaterRecord] = try await fetchAllRecords(recordType: "WaterRecord")
            let merged = mergeWaterRecords(local: records, cloud: cloudRecords)

            for record in merged {
                try await saveWaterRecord(record)
            }

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                showSyncToast(.success(Date()))
            }
        } catch {
            await MainActor.run {
                lastError = "同步失败: \(error.localizedDescription)"
                showSyncToast(.failed(error.localizedDescription))
                print("[CloudSync] 同步喝水记录失败: \(error)")
            }
        }

        await MainActor.run { isSyncing = false }
    }
    
    /// 同步植物状态
    func syncPlant(_ plant: Plant) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            showSyncToast(.syncing)
        }

        do {
            let cloudPlants: [Plant] = try await fetchAllRecords(recordType: "Plant")
            let latest = mergePlant(local: plant, cloud: cloudPlants)
            try await savePlant(latest)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                showSyncToast(.success(Date()))
            }
        } catch {
            await MainActor.run {
                lastError = "同步植物失败: \(error.localizedDescription)"
                showSyncToast(.failed(error.localizedDescription))
                print("[CloudSync] 同步植物失败: \(error)")
            }
        }

        await MainActor.run { isSyncing = false }
    }

    /// 同步花园收藏
    func syncGardenItems(_ items: [GardenItem]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            showSyncToast(.syncing)
        }

        do {
            let cloudItems: [GardenItem] = try await fetchAllRecords(recordType: "GardenItem")
            let merged = mergeGardenItems(local: items, cloud: cloudItems)

            for item in merged {
                try await saveGardenItem(item)
            }

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                showSyncToast(.success(Date()))
            }
        } catch {
            await MainActor.run {
                lastError = "同步花园失败: \(error.localizedDescription)"
                showSyncToast(.failed(error.localizedDescription))
                print("[CloudSync] 同步花园失败: \(error)")
            }
        }

        await MainActor.run { isSyncing = false }
    }

    /// 同步用户配置
    func syncUserProfile(_ profile: UserProfile) async {
        guard isSyncAvailable else {
            print("⚠️ [CloudSync] CloudKit 不可用，跳过用户配置同步")
            return
        }
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            showSyncToast(.syncing)
        }

        do {
            let cloudProfiles: [UserProfile] = try await fetchAllRecords(recordType: "UserProfile")
            let latest = mergeUserProfile(local: profile, cloud: cloudProfiles)
            try await saveUserProfile(latest)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                showSyncToast(.success(Date()))
            }
        } catch {
            await MainActor.run {
                lastError = "同步配置失败: \(error.localizedDescription)"
                showSyncToast(.failed(error.localizedDescription))
                print("[CloudSync] 同步配置失败: \(error)")
            }
        }

        await MainActor.run { isSyncing = false }
    }

    func syncAchievements(_ achievements: [Achievement]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            showSyncToast(.syncing)
        }

        do {
            let cloudAchievements: [Achievement] = try await fetchAllRecords(recordType: "Achievement")
            let merged = mergeAchievements(local: achievements, cloud: cloudAchievements)
            try await saveAchievements(merged)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                showSyncToast(.success(Date()))
            }
        } catch {
            await MainActor.run {
                lastError = "同步成就失败: \(error.localizedDescription)"
                showSyncToast(.failed(error.localizedDescription))
                print("[CloudSync] 同步成就失败: \(error)")
            }
        }

        await MainActor.run { isSyncing = false }
    }
    
    // MARK: - 从云端下载数据
    
    func downloadWaterRecords() async -> [WaterRecord]? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            return try await fetchAllRecords(recordType: "WaterRecord")
        } catch {
            print("[CloudSync] 下载喝水记录失败: \(error)")
            return nil
        }
    }
    
    func downloadPlant() async -> Plant? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            let plants: [Plant] = try await fetchAllRecords(recordType: "Plant")
            return plants.first
        } catch {
            print("[CloudSync] 下载植物失败: \(error)")
            return nil
        }
    }
    
    func downloadGardenItems() async -> [GardenItem]? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            return try await fetchAllRecords(recordType: "GardenItem")
        } catch {
            print("[CloudSync] 下载花园失败: \(error)")
            return nil
        }
    }
    
    func downloadUserProfile() async -> UserProfile? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            let profiles: [UserProfile] = try await fetchAllRecords(recordType: "UserProfile")
            return profiles.first
        } catch {
            print("[CloudSync] 下载配置失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 私有：CloudKit 操作
    
    private func isSyncAllowed() async -> Bool {
        guard isSyncAvailable else {
            await MainActor.run {
                lastError = "iCloud 不可用，请检查设置"
            }
            return false
        }
        return true
    }
    
    /// 获取所有指定类型的记录
    private func fetchAllRecords<T: Codable>(recordType: String) async throws -> [T] {
        var results: [T] = []
        var cursor: CKQueryOperation.Cursor?
        
        repeat {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let (matches, returnedCursor) = try await database.records(matching: query)
            cursor = returnedCursor
            
            for (_, result) in matches {
                if case .success(let record) = result {
                    if let data = record["data"] as? Data,
                       let decoded = try? JSONDecoder().decode(T.self, from: data) {
                        results.append(decoded)
                    }
                }
            }
        } while cursor != nil
        
        return results
    }
    
    private func saveWaterRecord(_ record: WaterRecord) async throws {
        let ckRecord = CKRecord(recordType: "WaterRecord", recordID: CKRecord.ID(recordName: record.id.uuidString))
        ckRecord["data"] = try JSONEncoder().encode(record)
        ckRecord["lastModified"] = Date()
        ckRecord["sortKey"] = record.createdAt.timeIntervalSince1970
        _ = try await database.save(ckRecord)
    }
    
    private func savePlant(_ plant: Plant) async throws {
        let ckRecord = CKRecord(recordType: "Plant", recordID: CKRecord.ID(recordName: "current_plant"))
        ckRecord["data"] = try JSONEncoder().encode(plant)
        ckRecord["lastModified"] = Date()
        _ = try await database.save(ckRecord)
    }
    
    private func saveGardenItem(_ item: GardenItem) async throws {
        let ckRecord = CKRecord(recordType: "GardenItem", recordID: CKRecord.ID(recordName: item.id.uuidString))
        ckRecord["data"] = try JSONEncoder().encode(item)
        ckRecord["lastModified"] = Date()
        ckRecord["sortKey"] = item.harvestedAt.timeIntervalSince1970
        _ = try await database.save(ckRecord)
    }
    
    private func saveUserProfile(_ profile: UserProfile) async throws {
        let ckRecord = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: "user_profile"))
        ckRecord["data"] = try JSONEncoder().encode(profile)
        ckRecord["lastModified"] = Date()
        _ = try await database.save(ckRecord)
    }
    
    // MARK: - 数据合并策略
    
    private func mergeWaterRecords(local: [WaterRecord], cloud: [WaterRecord]) -> [WaterRecord] {
        var dict: [UUID: WaterRecord] = [:]
        
        for record in cloud {
            dict[record.id] = record
        }
        
        for record in local {
            if let existing = dict[record.id] {
                if record.createdAt > existing.createdAt {
                    dict[record.id] = record
                }
            } else {
                dict[record.id] = record
            }
        }
        
        return Array(dict.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    private func mergePlant(local: Plant, cloud: [Plant]) -> Plant {
        guard let cloudPlant = cloud.first else { return local }
        
        if let localLastWatered = local.lastWateredAt,
           let cloudLastWatered = cloudPlant.lastWateredAt {
            return localLastWatered > cloudLastWatered ? local : cloudPlant
        }
        
        return local
    }
    
    private func mergeGardenItems(local: [GardenItem], cloud: [GardenItem]) -> [GardenItem] {
        var dict: [UUID: GardenItem] = [:]
        
        for item in cloud {
            dict[item.id] = item
        }
        
        for item in local {
            dict[item.id] = item
        }
        
        return Array(dict.values).sorted { $0.harvestedAt > $1.harvestedAt }
    }
    
    private func mergeUserProfile(local: UserProfile, cloud: [UserProfile]) -> UserProfile {
        guard let cloudProfile = cloud.first else { return local }
        
        if cloudProfile.isPro && !local.isPro {
            return cloudProfile
        }
        
        return local
    }
    
    private func mergeAchievements(local: [Achievement], cloud: [Achievement]) -> [Achievement] {
        var merged = local
        
        for cloudAch in cloud {
            if let index = merged.firstIndex(where: { $0.id == cloudAch.id }) {
                // Merge: keep the one with later unlock date or higher progress
                if cloudAch.isUnlocked && !merged[index].isUnlocked {
                    merged[index] = cloudAch
                } else if cloudAch.progress > merged[index].progress {
                    merged[index].progress = cloudAch.progress
                }
            } else {
                // New achievement from cloud
                merged.append(cloudAch)
            }
        }
        
        return merged
    }
    
    private func saveAchievements(_ achievements: [Achievement]) async throws {
        let records: [CKRecord] = achievements.map { achievement in
            let record = CKRecord(recordType: "Achievement", recordID: CKRecord.ID(recordName: achievement.id))
            record["title"] = achievement.title
            record["description"] = achievement.description
            record["icon"] = achievement.icon
            record["category"] = achievement.category.rawValue
            record["requirement"] = achievement.requirement
            record["progress"] = achievement.progress
            record["unlockedAt"] = achievement.unlockedAt as NSDate?
            return record
        }

        _ = try await database.modifyRecords(saving: records, deleting: [])
    }
}
