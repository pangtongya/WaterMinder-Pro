import Foundation
import UIKit
import UniformTypeIdentifiers
import CryptoKit
import BackgroundTasks

// MARK: - 备份信息结构

/// 备份文件信息（用于列表展示）
struct BackupInfo: Identifiable {
    let id = UUID()
    let fileName: String
    let date: Date
    let fileSize: Int64
    let isEncrypted: Bool
    let statistics: BackupStatistics?
    let fileURL: URL
}

/// 备份统计信息
struct BackupStatistics: Codable {
    let totalWaterRecords: Int
    let totalGardenItems: Int
    let totalAchievements: Int
    let plantGrowthDays: Int
    let totalWaterMl: Int
    let targetGoalMl: Int
    let currentStreakDays: Int
    let totalHarvestedPlants: Int
}

// MARK: - 备份数据结构

/// 完整的应用数据备份包
struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let waterRecords: [WaterRecord]
    let plant: Plant?
    let gardenItems: [GardenItem]
    let userProfile: UserProfile
    let achievements: [Achievement]
    var checksum: String
    let statistics: BackupStatistics
    let isEncrypted: Bool

    enum CodingKeys: String, CodingKey {
        case version
        case exportDate
        case appVersion
        case waterRecords
        case plant
        case gardenItems
        case userProfile
        case achievements
        case checksum
        case statistics
        case isEncrypted
    }

    init(
        version: String,
        exportDate: Date,
        appVersion: String,
        waterRecords: [WaterRecord],
        plant: Plant?,
        gardenItems: [GardenItem],
        userProfile: UserProfile,
        achievements: [Achievement],
        checksum: String,
        statistics: BackupStatistics,
        isEncrypted: Bool = false
    ) {
        self.version = version
        self.exportDate = exportDate
        self.appVersion = appVersion
        self.waterRecords = waterRecords
        self.plant = plant
        self.gardenItems = gardenItems
        self.userProfile = userProfile
        self.achievements = achievements
        self.checksum = checksum
        self.statistics = statistics
        self.isEncrypted = isEncrypted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        exportDate = try container.decode(Date.self, forKey: .exportDate)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        waterRecords = try container.decode([WaterRecord].self, forKey: .waterRecords)
        plant = try container.decodeIfPresent(Plant.self, forKey: .plant)
        gardenItems = try container.decode([GardenItem].self, forKey: .gardenItems)
        userProfile = try container.decode(UserProfile.self, forKey: .userProfile)
        achievements = try container.decode([Achievement].self, forKey: .achievements)
        checksum = try container.decode(String.self, forKey: .checksum)
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false

        if let stats = try container.decodeIfPresent(BackupStatistics.self, forKey: .statistics) {
            statistics = stats
        } else {
            let totalWaterMl = waterRecords.reduce(0) { $0 + $1.amount }
            let growthDays: Int
            if let p = plant {
                growthDays = Calendar.current.dateComponents([.day], from: p.plantedAt, to: exportDate).day ?? 0
            } else {
                growthDays = 0
            }
            statistics = BackupStatistics(
                totalWaterRecords: waterRecords.count,
                totalGardenItems: gardenItems.count,
                totalAchievements: achievements.count,
                plantGrowthDays: growthDays,
                totalWaterMl: totalWaterMl,
                targetGoalMl: userProfile.dailyGoal,
                currentStreakDays: 0,
                totalHarvestedPlants: gardenItems.count
            )
        }
    }

    /// 使用 SHA256 计算内容校验和
    func computeChecksum() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        var tempData = self
        tempData.checksum = ""

        guard let jsonData = try? encoder.encode(tempData) else {
            return ""
        }

        let hash = SHA256.hash(data: jsonData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 验证校验和是否匹配
    func validateChecksum() -> Bool {
        return computeChecksum() == checksum
    }
}

// MARK: - 备份管理器

/// 数据备份与恢复管理器
/// 功能：
/// 1. 导出完整数据为 JSON 文件
/// 2. 从 JSON 文件导入/恢复数据
/// 3. 支持分享备份文件（Files app、AirDrop、邮件等）
/// 4. 自动备份（每周日凌晨）
/// 5. 备份文件加密
/// 6. 数据迁移支持
@MainActor
final class DataBackupManager: ObservableObject {

    static let shared = DataBackupManager()

    @Published var isExporting = false
    @Published var isImporting = false
    @Published var lastBackupDate: Date? {
        didSet {
            UserDefaults.standard.set(lastBackupDate, forKey: "bloom.lastBackupDate")
        }
    }

    @Published var autoBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoBackupEnabled, forKey: "bloom.autoBackupEnabled")
            if autoBackupEnabled {
                scheduleAutoBackup()
            } else {
                cancelAutoBackup()
            }
        }
    }

    @Published var backupEncryptionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backupEncryptionEnabled, forKey: "bloom.backupEncryptionEnabled")
        }
    }

    static let currentVersion = "2.0"
    static let maxBackupCount = 5
    static let autoBackupTaskIdentifier = "com.pangtong.bloom.autoBackup"
    private static let encryptionKeyKeychainKey = "bloom.backupEncryptionKey"

    private init() {
        self.lastBackupDate = UserDefaults.standard.object(forKey: "bloom.lastBackupDate") as? Date
        self.autoBackupEnabled = UserDefaults.standard.bool(forKey: "bloom.autoBackupEnabled")
        self.backupEncryptionEnabled = UserDefaults.standard.bool(forKey: "bloom.backupEncryptionEnabled")

        if autoBackupEnabled {
            scheduleAutoBackup()
        }
    }

    // MARK: - 加密密钥管理

    /// 获取或生成备份加密密钥
    private func getEncryptionKey() throws -> SymmetricKey {
        if let keyData = KeychainManager.shared.load(for: Self.encryptionKeyKeychainKey) {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        let success = KeychainManager.shared.save(keyData, for: Self.encryptionKeyKeychainKey)

        guard success else {
            throw BackupError.encryptionKeySaveFailed
        }

        return newKey
    }

    /// 加密数据
    private func encryptData(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw BackupError.encryptionFailed
        }
        return combined
    }

    /// 解密数据
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }

    // MARK: - 导出功能

    /// 导出完整数据为 JSON 文件
    /// - Returns: 备份文件的 URL
    func exportAllData(
        waterStore: WaterStore,
        plantEngine: PlantEngine,
        gardenStore: GardenStore,
        userStore: UserStore,
        achievementStore: AchievementStore
    ) async throws -> URL {
        isExporting = true
        defer { isExporting = false }

        let totalWaterMl = waterStore.records.reduce(0) { $0 + $1.amount }
        let currentStreak = calculateCurrentStreak(records: waterStore.records, dailyGoal: userStore.dailyGoal)
        let harvestedPlants = gardenStore.items.count

        let statistics = BackupStatistics(
            totalWaterRecords: waterStore.records.count,
            totalGardenItems: gardenStore.items.count,
            totalAchievements: achievementStore.achievements.count,
            plantGrowthDays: Calendar.current.dateComponents(
                [.day],
                from: plantEngine.plant.plantedAt,
                to: Date()
            ).day ?? 0,
            totalWaterMl: totalWaterMl,
            targetGoalMl: userStore.dailyGoal,
            currentStreakDays: currentStreak,
            totalHarvestedPlants: harvestedPlants
        )

        let placeholder = BackupData(
            version: Self.currentVersion,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            waterRecords: waterStore.records,
            plant: plantEngine.plant,
            gardenItems: gardenStore.items,
            userProfile: userStore.profile,
            achievements: achievementStore.achievements,
            checksum: "",
            statistics: statistics,
            isEncrypted: backupEncryptionEnabled
        )

        let computedChecksum = placeholder.computeChecksum()

        let backup = BackupData(
            version: placeholder.version,
            exportDate: placeholder.exportDate,
            appVersion: placeholder.appVersion,
            waterRecords: placeholder.waterRecords,
            plant: placeholder.plant,
            gardenItems: placeholder.gardenItems,
            userProfile: placeholder.userProfile,
            achievements: placeholder.achievements,
            checksum: computedChecksum,
            statistics: placeholder.statistics,
            isEncrypted: placeholder.isEncrypted
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        var jsonData = try encoder.encode(backup)

        if backupEncryptionEnabled {
            jsonData = try encryptData(jsonData)
        }

        let fileName = generateBackupFileName(encrypted: backupEncryptionEnabled)
        let fileURL = getBackupsDirectory().appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)

        lastBackupDate = Date()

        cleanupOldBackups()

        return fileURL
    }

    /// 生成备份文件名（带时间戳）
    private func generateBackupFileName(encrypted: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let suffix = encrypted ? "_encrypted" : ""
        return "Bloom_Backup_\(timestamp)\(suffix).json"
    }

    /// 获取备份文件存储目录
    private func getBackupsDirectory() -> URL {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return fileManager.temporaryDirectory
        }

        let backupsDir = documentsDir.appendingPathComponent("Backups", isDirectory: true)

        if !fileManager.fileExists(atPath: backupsDir.path) {
            try? fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        }

        return backupsDir
    }

    // MARK: - 导入/恢复功能

    /// 从 JSON 文件导入数据
    /// - Parameter fileURL: 备份文件的 URL
    /// - Returns: 解析出的备份数据
    func importBackup(from fileURL: URL) async throws -> BackupData {
        isImporting = true
        defer { isImporting = false }

        var data = try Data(contentsOf: fileURL)

        let isEncrypted = fileURL.lastPathComponent.contains("_encrypted") || isEncryptedBackup(data: data)

        if isEncrypted {
            do {
                data = try decryptData(data)
            } catch {
                throw BackupError.decryptionFailed
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup: BackupData
        do {
            backup = try decoder.decode(BackupData.self, from: data)
        } catch {
            do {
                let v1Backup = try decodeV1Backup(from: data)
                backup = try migrateV1toV2(v1Backup)
            } catch {
                throw BackupError.invalidData
            }
        }

        if !backup.validateChecksum() {
            throw BackupError.corruptedData
        }

        return backup
    }

    /// 检测数据是否为加密备份
    private func isEncryptedBackup(data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        do {
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            return false
        } catch {
            return true
        }
    }

    /// 恢复数据到应用中
    /// - Parameters:
    ///   - backup: 备份数据
    ///   - waterStore: 喝水记录 Store
    ///   - plantEngine: 植物引擎
    ///   - gardenStore: 花园 Store
    ///   - userStore: 用户 Store
    ///   - achievementStore: 成就 Store
    ///   - merge: 是否合并数据（true=合并，false=覆盖）
    func restoreData(
        from backup: BackupData,
        waterStore: WaterStore,
        plantEngine: PlantEngine,
        gardenStore: GardenStore,
        userStore: UserStore,
        achievementStore: AchievementStore,
        merge: Bool = true
    ) {
        if merge {
            waterStore.mergeWithCloudRecords(backup.waterRecords)
        } else {
            waterStore.replaceAllRecords(with: backup.waterRecords)
        }

        if let backupPlant = backup.plant {
            if merge {
                plantEngine.mergeWithCloudPlant(backupPlant)
            } else {
                plantEngine.replacePlant(with: backupPlant)
            }
        }

        if merge {
            gardenStore.mergeWithCloudItems(backup.gardenItems)
        } else {
            gardenStore.replaceAllItems(with: backup.gardenItems)
        }

        if merge {
            achievementStore.mergeWithCloudAchievements(backup.achievements)
        } else {
            achievementStore.replaceAllAchievements(with: backup.achievements)
        }

        userStore.restoreFromBackup(backup.userProfile, merge: merge)
    }

    // MARK: - 分享功能

    /// 分享备份文件
    /// - Parameter fileURL: 备份文件 URL
    /// - Returns: UIActivityViewController
    func createShareActivityViewController(for fileURL: URL, sourceView: UIView?) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let sourceView = sourceView {
            activityVC.popoverPresentationController?.sourceView = sourceView
        }

        return activityVC
    }

    // MARK: - 备份文件管理

    /// 列出所有备份文件
    func listBackups() -> [BackupInfo] {
        let fileManager = FileManager.default
        let backupsDir = getBackupsDirectory()

        guard let contents = try? fileManager.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let backupFiles = contents.filter {
            $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("Bloom_Backup_")
        }

        let sortedFiles = backupFiles.sorted {
            let date0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let date1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return date0 > date1
        }

        return sortedFiles.map { url in
            let isEncrypted = url.lastPathComponent.contains("_encrypted")
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let modificationDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()

            let statistics = loadBackupStatistics(from: url, encrypted: isEncrypted)

            return BackupInfo(
                fileName: url.lastPathComponent,
                date: modificationDate,
                fileSize: Int64(fileSize),
                isEncrypted: isEncrypted,
                statistics: statistics,
                fileURL: url
            )
        }
    }

    /// 加载备份统计信息（仅读取元数据，不解密全部内容）
    private func loadBackupStatistics(from url: URL, encrypted: Bool) -> BackupStatistics? {
        do {
            var data = try Data(contentsOf: url)

            if encrypted {
                data = try decryptData(data)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)
            return backup.statistics
        } catch {
            return nil
        }
    }

    /// 删除指定备份文件
    func deleteBackup(at backupInfo: BackupInfo) throws {
        let fileManager = FileManager.default
        try fileManager.removeItem(at: backupInfo.fileURL)
    }

    /// 获取最新的备份
    func getLatestBackup() -> BackupInfo? {
        let backups = listBackups()
        return backups.first
    }

    /// 获取所有本地备份文件（旧方法，向后兼容）
    func getLocalBackups() -> [URL] {
        return listBackups().map { $0.fileURL }
    }

    /// 删除旧的备份文件（保留最近 N 个）
    func cleanupOldBackups(keepCount: Int = 5) {
        let backups = listBackups()
        if backups.count > keepCount {
            let toDelete = backups.dropFirst(keepCount)
            for backup in toDelete {
                try? deleteBackup(at: backup)
            }
        }
    }

    /// 计算备份文件大小（旧方法，向后兼容）
    func backupFileSize(at url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? UInt64 else {
            return "0 KB"
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    // MARK: - 自动备份功能

    /// 调度自动备份任务
    func scheduleAutoBackup() {
        cancelAutoBackup()

        guard autoBackupEnabled else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.autoBackupTaskIdentifier)
        request.earliestBeginDate = nextSundayMidnight()

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[DataBackup] 自动备份任务已调度，下次执行: \(request.earliestBeginDate?.description ?? "未知")")
            #endif
        } catch {
            #if DEBUG
            print("[DataBackup] 调度自动备份任务失败: \(error)")
            #endif
        }
    }

    /// 取消自动备份任务
    func cancelAutoBackup() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.autoBackupTaskIdentifier)
    }

    /// 计算下一个周日凌晨的日期
    private func nextSundayMidnight() -> Date {
        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1
        components.hour = 2
        components.minute = 0
        components.second = 0

        var nextSunday = calendar.date(from: components) ?? now

        if nextSunday <= now {
            nextSunday = calendar.date(byAdding: .weekOfYear, value: 1, to: nextSunday) ?? now
        }

        return nextSunday
    }

    /// 执行自动备份（由后台任务调用）
    func performAutoBackup() async {
        guard autoBackupEnabled else { return }

        do {
            let _ = try await exportAllData(
                waterStore: WaterStore.shared,
                plantEngine: PlantEngine.shared,
                gardenStore: GardenStore.shared,
                userStore: UserStore.shared,
                achievementStore: AchievementStore.shared
            )
            #if DEBUG
            print("[DataBackup] 自动备份成功")
            #endif
        } catch {
            #if DEBUG
            print("[DataBackup] 自动备份失败: \(error)")
            #endif
        }

        scheduleAutoBackup()
    }

    /// 注册后台任务（需在 App 启动时调用）
    func registerAutoBackupTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.autoBackupTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAutoBackupTask(refreshTask)
        }
    }

    private func handleAutoBackupTask(_ task: BGAppRefreshTask) {
        Task { @MainActor in
            await performAutoBackup()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - 数据迁移

    /// v1 版本备份数据结构
    private struct V1BackupData: Codable {
        let version: String
        let exportDate: Date
        let appVersion: String
        let waterRecords: [WaterRecord]
        let plant: Plant?
        let gardenItems: [GardenItem]
        let userProfile: UserProfile
        let achievements: [Achievement]
        var checksum: String
        let metadata: V1BackupMetadata

        struct V1BackupMetadata: Codable {
            let totalWaterRecords: Int
            let totalGardenItems: Int
            let totalAchievements: Int
            let plantGrowthDays: Int
            let totalWaterMl: Int
            let targetGoalMl: Int
        }
    }

    /// 解码 v1 版本备份
    private func decodeV1Backup(from data: Data) throws -> V1BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(V1BackupData.self, from: data)
    }

    /// 从 v1 迁移到 v2
    private func migrateV1toV2(_ v1Data: V1BackupData) throws -> BackupData {
        let currentStreak = calculateCurrentStreak(
            records: v1Data.waterRecords,
            dailyGoal: v1Data.metadata.targetGoalMl
        )
        let harvestedPlants = v1Data.gardenItems.count

        let statistics = BackupStatistics(
            totalWaterRecords: v1Data.metadata.totalWaterRecords,
            totalGardenItems: v1Data.metadata.totalGardenItems,
            totalAchievements: v1Data.metadata.totalAchievements,
            plantGrowthDays: v1Data.metadata.plantGrowthDays,
            totalWaterMl: v1Data.metadata.totalWaterMl,
            targetGoalMl: v1Data.metadata.targetGoalMl,
            currentStreakDays: currentStreak,
            totalHarvestedPlants: harvestedPlants
        )

        var migrated = BackupData(
            version: Self.currentVersion,
            exportDate: v1Data.exportDate,
            appVersion: v1Data.appVersion,
            waterRecords: v1Data.waterRecords,
            plant: v1Data.plant,
            gardenItems: v1Data.gardenItems,
            userProfile: v1Data.userProfile,
            achievements: v1Data.achievements,
            checksum: "",
            statistics: statistics,
            isEncrypted: false
        )

        migrated.checksum = migrated.computeChecksum()

        return migrated
    }

    // MARK: - 辅助方法

    /// 计算当前连续达标天数
    private func calculateCurrentStreak(records: [WaterRecord], dailyGoal: Int) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayRecords = records.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
            let dayTotal = dayRecords.reduce(0) { $0 + $1.amount }

            if dayTotal >= dailyGoal {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - URL 扩展

extension URL {
    var lastModifiedTimeInterval: TimeInterval {
        (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate?.timeIntervalSince1970 ?? 0
    }
}

// MARK: - 错误类型

enum BackupError: LocalizedError {
    case unsupportedVersion(String)
    case fileNotFound
    case invalidData
    case corruptedData
    case exportFailed(String)
    case importFailed(String)
    case encryptionFailed
    case decryptionFailed
    case encryptionKeySaveFailed
    case migrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return String(format: NSLocalizedString("不支持的备份版本: %@", comment: ""), version)
        case .fileNotFound:
            return NSLocalizedString("备份文件未找到", comment: "")
        case .invalidData:
            return NSLocalizedString("备份数据格式无效", comment: "")
        case .corruptedData:
            return NSLocalizedString("备份文件已损坏（校验和验证失败），文件可能已被篡改或损坏", comment: "")
        case .exportFailed(let message):
            return String(format: NSLocalizedString("导出失败: %@", comment: ""), message)
        case .importFailed(let message):
            return String(format: NSLocalizedString("导入失败: %@", comment: ""), message)
        case .encryptionFailed:
            return NSLocalizedString("备份加密失败，请重试", comment: "")
        case .decryptionFailed:
            return NSLocalizedString("备份解密失败，请检查加密密钥是否正确", comment: "")
        case .encryptionKeySaveFailed:
            return NSLocalizedString("加密密钥保存失败，请检查 Keychain 权限", comment: "")
        case .migrationFailed(let message):
            return String(format: NSLocalizedString("数据迁移失败: %@", comment: ""), message)
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .corruptedData:
            return NSLocalizedString("建议使用其他备份文件进行恢复，或联系技术支持", comment: "")
        case .decryptionFailed:
            return NSLocalizedString("如果您更换了设备，请确保使用同一 Apple ID 登录并启用 iCloud Keychain 同步", comment: "")
        default:
            return nil
        }
    }
}
