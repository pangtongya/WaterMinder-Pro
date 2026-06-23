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
    
    // MARK: - 同步状态
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case failed(SyncError)
    }
    
    enum SyncProgress: Equatable {
        case downloading
        case merging
        case uploading
    }
    
    enum SyncError: LocalizedError, Equatable {
        case notSignedIn
        case noNetwork
        case insufficientSpace
        case permissionDenied
        case networkError
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return NSLocalizedString("未登录 iCloud 账号", comment: "iCloud not signed in")
            case .noNetwork:
                return NSLocalizedString("等待网络连接", comment: "Waiting for network")
            case .insufficientSpace:
                return NSLocalizedString("iCloud 存储空间不足", comment: "iCloud storage insufficient")
            case .permissionDenied:
                return NSLocalizedString("无 iCloud 同步权限", comment: "iCloud permission denied")
            case .networkError:
                return NSLocalizedString("网络连接异常", comment: "Network error")
            case .unknown(let message):
                return message
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .notSignedIn:
                return NSLocalizedString("请在系统设置中登录 iCloud", comment: "Sign in to iCloud in Settings")
            case .noNetwork:
                return NSLocalizedString("连接网络后将自动同步", comment: "Will auto-sync when network is available")
            case .insufficientSpace:
                return NSLocalizedString("请清理 iCloud 存储空间后重试", comment: "Free up iCloud storage and try again")
            case .permissionDenied:
                return NSLocalizedString("请在系统设置中允许 Bloom 访问 iCloud", comment: "Allow Bloom to access iCloud in Settings")
            case .networkError:
                return NSLocalizedString("请检查网络连接后重试", comment: "Check network connection and try again")
            case .unknown:
                return NSLocalizedString("请稍后重试", comment: "Please try again later")
            }
        }
        
        var canRetry: Bool {
            switch self {
            case .notSignedIn, .permissionDenied, .insufficientSpace:
                return false
            case .noNetwork, .networkError, .unknown:
                return true
            }
        }
        
        var showsSettingsButton: Bool {
            switch self {
            case .notSignedIn, .permissionDenied:
                return true
            default:
                return false
            }
        }
    }
    
    /// 同步是否可用（用户已登录 iCloud）
    @Published private(set) var isSyncAvailable = false
    
    /// 同步状态
    @Published private(set) var syncStatus: SyncStatus = .idle
    
    /// 同步进度步骤
    @Published private(set) var syncProgress: SyncProgress = .downloading
    
    /// 是否正在同步
    @Published private(set) var isSyncing = false
    
    /// 最后一次同步时间
    @Published private(set) var lastSyncDate: Date?
    
    /// 同步错误信息
    @Published private(set) var lastError: SyncError?

    /// 基于现有状态自动计算的 Toast 显示状态
    /// RootView 监听此属性即可，无需订阅多个 @Published
    @Published private(set) var syncToastState: SyncToastState = .idle
    
    /// 网络监视器
    private let networkMonitor = NetworkMonitor.shared
    
    /// 是否有网络连接
    var isNetworkAvailable: Bool {
        networkMonitor.isConnected
    }
    
    private var syncRetryTask: Task<Void, Never>?
    private var pendingSyncBlock: (() async -> Void)?

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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        toastResetTimer?.invalidate()
        syncRetryTask?.cancel()
    }
    
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
        
        // 监听网络状态变化
        Task { [weak self] in
            for await isConnected in NotificationCenter.default
                .notifications(named: .networkStatusChanged)
                .compactMap({ $0.userInfo?["isConnected"] as? Bool }) {
                guard let self = self else { return }
                if isConnected {
                    await self.handleNetworkRestored()
                }
            }
        }
    }
    
    // MARK: - 公共方法
    
    /// 手动触发全量同步
    func syncAll() async {
        guard await isSyncAllowed() else { return }
        guard !isSyncing else { return }
        
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }
        
        do {
            syncProgress = .downloading
            let waterRecords = try await fetchAllRecords(recordType: "WaterRecord") as [WaterRecord]
            let cloudPlants = try await fetchAllRecords(recordType: "Plant") as [Plant]
            let cloudItems = try await fetchAllRecords(recordType: "GardenItem") as [GardenItem]
            let cloudProfiles = try await fetchAllRecords(recordType: "UserProfile") as [UserProfile]
            let cloudAchievements = try await fetchAllRecords(recordType: "Achievement") as [Achievement]
            
            syncProgress = .merging
            try await Task.sleep(nanoseconds: 300_000_000)
            
            syncProgress = .uploading
            
            let waterStore = WaterStore.shared
            let plantEngine = PlantEngine.shared
            let gardenStore = GardenStore.shared
            let userStore = UserStore.shared
            let achievementStore = AchievementStore.shared
            
            let mergedWater = mergeWaterRecords(local: waterStore.records, cloud: waterRecords)
            for record in mergedWater {
                try await saveWaterRecord(record)
            }
            
            let latestPlant = mergePlant(local: plantEngine.plant, cloud: cloudPlants)
            try await savePlant(latestPlant)
            
            let mergedGarden = mergeGardenItems(local: gardenStore.items, cloud: cloudItems)
            for item in mergedGarden {
                try await saveGardenItem(item)
            }
            
            let latestProfile = mergeUserProfile(local: userStore.profile, cloud: cloudProfiles)
            try await saveUserProfile(latestProfile)
            
            let mergedAchievements = mergeAchievements(local: achievementStore.achievements, cloud: cloudAchievements)
            try await saveAchievements(mergedAchievements)
            
            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 全量同步失败: \(error)")
                #endif
            }
        }
        
        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }
    
    /// 重试上次失败的同步
    func retryLastSync() async {
        if case .failed(let error) = syncStatus, error.canRetry {
            await syncAll()
        }
    }
    
    /// 打开系统设置（用于引导用户登录 iCloud 或设置权限）
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 账号状态检查
    
    @objc func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    isSyncAvailable = (status == .available)
                    if status != .available {
                        let error: SyncError = (status == .noAccount || status == .couldNotDetermine) ? .notSignedIn : .permissionDenied
                        lastError = error
                        syncStatus = .failed(error)
                    }
                }
            } catch {
                #if DEBUG
                print("[CloudSync] 账号状态检查失败: \(error)")
                #endif
                await MainActor.run {
                    isSyncAvailable = false
                    lastError = .unknown(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 错误分类
    
    private func classifyError(_ error: Error) -> SyncError {
        let ckError = error as NSError
        
        // 检查网络错误
        if ckError.domain == NSURLErrorDomain {
            switch ckError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDataNotAllowed:
                return .noNetwork
            default:
                return .networkError
            }
        }
        
        // 检查 CloudKit 错误
        if ckError.domain == CKErrorDomain {
            switch ckError.code {
            case CKError.notAuthenticated.rawValue:
                return .notSignedIn
            case CKError.permissionFailure.rawValue:
                return .permissionDenied
            case CKError.zoneBusy.rawValue,
                 CKError.serviceUnavailable.rawValue,
                 CKError.requestRateLimited.rawValue:
                return .networkError
            case CKError.quotaExceeded.rawValue:
                return .insufficientSpace
            default:
                break
            }
        }
        
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - 网络状态处理
    
    private func handleNetworkRestored() async {
        if case .failed(let error) = syncStatus, error == .noNetwork {
            pendingSyncBlock = { [weak self] in
                Task { @MainActor in
                    await self?.syncAll()
                }
            }
            await syncAll()
        }
    }
    
    // MARK: - 数据同步
    
    /// 同步喝水记录
    func syncWaterRecords(_ records: [WaterRecord]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }

        do {
            syncProgress = .downloading
            let cloudRecords: [WaterRecord] = try await fetchAllRecords(recordType: "WaterRecord")
            
            syncProgress = .merging
            let merged = mergeWaterRecords(local: records, cloud: cloudRecords)
            
            syncProgress = .uploading
            for record in merged {
                try await saveWaterRecord(record)
            }

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 同步喝水记录失败: \(error)")
                #endif
            }
        }

        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }
    
    /// 同步植物状态
    func syncPlant(_ plant: Plant) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }

        do {
            syncProgress = .downloading
            let cloudPlants: [Plant] = try await fetchAllRecords(recordType: "Plant")
            
            syncProgress = .merging
            let latest = mergePlant(local: plant, cloud: cloudPlants)
            
            syncProgress = .uploading
            try await savePlant(latest)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 同步植物失败: \(error)")
                #endif
            }
        }

        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }

    /// 同步花园收藏
    func syncGardenItems(_ items: [GardenItem]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }

        do {
            syncProgress = .downloading
            let cloudItems: [GardenItem] = try await fetchAllRecords(recordType: "GardenItem")
            
            syncProgress = .merging
            let merged = mergeGardenItems(local: items, cloud: cloudItems)
            
            syncProgress = .uploading
            for item in merged {
                try await saveGardenItem(item)
            }

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 同步花园失败: \(error)")
                #endif
            }
        }

        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }

    /// 同步用户配置
    func syncUserProfile(_ profile: UserProfile) async {
        guard isSyncAvailable else {
            #if DEBUG
            print("⚠️ [CloudSync] CloudKit 不可用，跳过用户配置同步")
            #endif
            return
        }
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }

        do {
            syncProgress = .downloading
            let cloudProfiles: [UserProfile] = try await fetchAllRecords(recordType: "UserProfile")
            
            syncProgress = .merging
            let latest = mergeUserProfile(local: profile, cloud: cloudProfiles)
            
            syncProgress = .uploading
            try await saveUserProfile(latest)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 同步配置失败: \(error)")
                #endif
            }
        }

        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }

    func syncAchievements(_ achievements: [Achievement]) async {
        guard await isSyncAllowed() else { return }
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
            syncProgress = .downloading
            showSyncToast(.syncing)
        }

        do {
            syncProgress = .downloading
            let cloudAchievements: [Achievement] = try await fetchAllRecords(recordType: "Achievement")
            
            syncProgress = .merging
            let merged = mergeAchievements(local: achievements, cloud: cloudAchievements)
            
            syncProgress = .uploading
            try await saveAchievements(merged)

            await MainActor.run {
                lastSyncDate = Date()
                lastError = nil
                syncStatus = .success
                showSyncToast(.success(Date()))
            }
        } catch {
            let syncError = classifyError(error)
            await MainActor.run {
                lastError = syncError
                syncStatus = .failed(syncError)
                showSyncToast(.failed(syncError.errorDescription ?? error.localizedDescription))
                #if DEBUG
                print("[CloudSync] 同步成就失败: \(error)")
                #endif
            }
        }

        await MainActor.run {
            isSyncing = false
            if case .success = syncStatus {
                syncStatus = .idle
            }
        }
    }
    
    // MARK: - 从云端下载数据
    
    func downloadWaterRecords() async -> [WaterRecord]? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            return try await fetchAllRecords(recordType: "WaterRecord")
        } catch {
            #if DEBUG
            print("[CloudSync] 下载喝水记录失败: \(error)")
            #endif
            return nil
        }
    }
    
    func downloadPlant() async -> Plant? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            let plants: [Plant] = try await fetchAllRecords(recordType: "Plant")
            return plants.first
        } catch {
            #if DEBUG
            print("[CloudSync] 下载植物失败: \(error)")
            #endif
            return nil
        }
    }
    
    func downloadGardenItems() async -> [GardenItem]? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            return try await fetchAllRecords(recordType: "GardenItem")
        } catch {
            #if DEBUG
            print("[CloudSync] 下载花园失败: \(error)")
            #endif
            return nil
        }
    }
    
    func downloadUserProfile() async -> UserProfile? {
        guard await isSyncAllowed() else { return nil }
        
        do {
            let profiles: [UserProfile] = try await fetchAllRecords(recordType: "UserProfile")
            return profiles.first
        } catch {
            #if DEBUG
            print("[CloudSync] 下载配置失败: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - 私有：CloudKit 操作
    
    private func isSyncAllowed() async -> Bool {
        guard isSyncAvailable else {
            await MainActor.run {
                let error: SyncError = .notSignedIn
                lastError = error
                syncStatus = .failed(error)
                showSyncToast(.failed(error.errorDescription ?? ""))
            }
            return false
        }
        guard networkMonitor.isConnected else {
            await MainActor.run {
                let error: SyncError = .noNetwork
                lastError = error
                syncStatus = .failed(error)
                showSyncToast(.failed(error.errorDescription ?? ""))
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
        // hkSampleUUID 作为独立查询字段：便于通过 NSPredicate 在云端精确定位同一条 HealthKit 样本，
        // 解决"不同设备上同一杯水分成两条不同记录"的问题
        if let hkSampleUUID = record.hkSampleUUID {
            ckRecord["hkSampleUUID"] = hkSampleUUID.uuidString as CKRecordValue
        }
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
    
    /// 多设备合并喝水记录：hkSampleUUID 优先 → id 次优先 → createdAt 兜底
    /// 关键修复：从 HealthKit 导入的同一条样本在不同设备上 WaterRecord.id 不同，但 hkSampleUUID 相同，
    /// 必须按 hkSampleUUID 去重，否则用户会看到"同一杯水"被计为两次。
    private func mergeWaterRecords(local: [WaterRecord], cloud: [WaterRecord]) -> [WaterRecord] {
        // 先按 hkSampleUUID 建立索引（来自 HealthKit 的样本可以精确去重）
        var byHKUUID: [UUID: WaterRecord] = [:]
        // 按 id 建立其他记录（非 HealthKit 来源）的索引
        var byID: [UUID: WaterRecord] = [:]

        // 1) 加载云端数据到两张索引
        for record in cloud {
            if let hk = record.hkSampleUUID {
                byHKUUID[hk] = record
            } else {
                byID[record.id] = record
            }
        }

        // 2) 本地记录与云端合并
        for record in local {
            if let hk = record.hkSampleUUID {
                // HealthKit 来源：若云端已有同一样本，保留 createdAt 较新的（避免时间漂移）
                if let existing = byHKUUID[hk] {
                    byHKUUID[hk] = record.createdAt >= existing.createdAt ? record : existing
                } else {
                    byHKUUID[hk] = record
                }
            } else {
                // 非 HealthKit 来源：按 id 去重，保留 createdAt 较新的
                if let existing = byID[record.id] {
                    byID[record.id] = record.createdAt >= existing.createdAt ? record : existing
                } else {
                    byID[record.id] = record
                }
            }
        }

        // 3) 合并两张索引，按 createdAt 倒序
        let all = Array(byHKUUID.values) + Array(byID.values)
        return all.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 多设备合并植物：优先 health 更高 / stage 更成熟者，只在两者相同时才用 lastWateredAt 破局
    /// 避免：B 设备 lastWateredAt 晚但 health 更低，却覆盖掉 A 设备更健康的植物
    func mergePlant(local: Plant, cloud: [Plant]) -> Plant {
        guard let cloudPlant = cloud.first else { return local }

        // 1) stage 优先（成熟度最高的植物赢）
        if local.stage.rawValue != cloudPlant.stage.rawValue {
            return local.stage.rawValue > cloudPlant.stage.rawValue ? local : cloudPlant
        }
        // 2) health 次之（越健康的植物赢）
        if local.health != cloudPlant.health {
            return local.health > cloudPlant.health ? local : cloudPlant
        }
        // 3) lastWateredAt 破局（较晚的更有权威性）
        if let localLast = local.lastWateredAt, let cloudLast = cloudPlant.lastWateredAt {
            return localLast > cloudLast ? local : cloudPlant
        }
        // 4) 暂停养护的合并：只要有一边是暂停，就保持暂停（更保守，避免意外浇水）
        if local.isPaused != cloudPlant.isPaused {
            var winner = local.health >= cloudPlant.health ? local : cloudPlant
            winner.isPaused = local.isPaused || cloudPlant.isPaused
            return winner
        }
        return local
    }

    /// 多设备合并花园记录：按 id 去重，同一条记录保留 harvestedAt 较新的
    /// 避免：本地永远覆盖云端 → 云端的新收获被旧本地数据覆盖
    private func mergeGardenItems(local: [GardenItem], cloud: [GardenItem]) -> [GardenItem] {
        var dict: [UUID: GardenItem] = [:]

        for item in cloud {
            dict[item.id] = item
        }

        for item in local {
            if let existing = dict[item.id] {
                // 同一条记录：保留 harvestedAt 较新的
                dict[item.id] = item.harvestedAt >= existing.harvestedAt ? item : existing
            } else {
                dict[item.id] = item
            }
        }

        return Array(dict.values).sorted { $0.harvestedAt > $1.harvestedAt }
    }

    /// 多设备合并用户资料：Pro 状态只要一边是 true 就保留；其他字段本地优先
    private func mergeUserProfile(local: UserProfile, cloud: [UserProfile]) -> UserProfile {
        guard let cloudProfile = cloud.first else { return local }

        // Pro 状态一经解锁不应被撤销；如果本地或云端任一是 Pro，保留为 Pro
        var merged = local
        merged.isPro = local.isPro || cloudProfile.isPro
        return merged
    }

    /// 多设备合并成就：进度单调递增（永不回退），解锁时间取两者中较早的
    /// 避免：云端进度/解锁状态比本地旧时把用户"已解锁"或"已积累 50%" 的进度回退
    private func mergeAchievements(local: [Achievement], cloud: [Achievement]) -> [Achievement] {
        var merged = local

        for cloudAch in cloud {
            if let index = merged.firstIndex(where: { $0.id == cloudAch.id }) {
                var existing = merged[index]
                // 进度单调递增：取 max(local, cloud)
                existing.progress = max(existing.progress, cloudAch.progress)

                // 解锁状态：只要一方已解锁，就保留为已解锁；unlockedAt 取较早的时间（首次解锁时间）
                switch (existing.unlockedAt, cloudAch.unlockedAt) {
                case (_, nil):
                    break
                case (nil, _):
                    existing.unlockedAt = cloudAch.unlockedAt
                case (.some(let localAt), .some(let cloudAt)):
                    existing.unlockedAt = min(localAt, cloudAt)
                }

                merged[index] = existing
            } else {
                merged.append(cloudAch)
            }
        }

        return merged
    }
    
    /// 保存成就列表到云端
    /// 注意：保存为 JSON data 格式（与其他 saveX 方法一致），以便 fetchAllRecords 能正确解码
    private func saveAchievements(_ achievements: [Achievement]) async throws {
        for achievement in achievements {
            let ckRecord = CKRecord(recordType: "Achievement", recordID: CKRecord.ID(recordName: achievement.id))
            ckRecord["data"] = try JSONEncoder().encode(achievement)
            ckRecord["lastModified"] = Date()
            _ = try await database.save(ckRecord)
        }
    }
}
