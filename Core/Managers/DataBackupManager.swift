import Foundation
import UIKit
import UniformTypeIdentifiers

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
    let metadata: BackupMetadata
    
    struct BackupMetadata: Codable {
        let totalWaterRecords: Int
        let totalGardenItems: Int
        let plantGrowthDays: Int
    }
}

// MARK: - 备份管理器

/// 数据备份与恢复管理器
/// 功能：
/// 1. 导出完整数据为 JSON 文件
/// 2. 从 JSON 文件导入/恢复数据
/// 3. 支持分享备份文件（Files app、AirDrop、邮件等）
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
    
    private init() {
        self.lastBackupDate = UserDefaults.standard.object(forKey: "bloom.lastBackupDate") as? Date
    }
    
    // MARK: - 导出功能
    
    /// 导出完整数据为 JSON 文件
    /// - Returns: 备份文件的 URL
    func exportAllData(
        waterStore: WaterStore,
        plantEngine: PlantEngine,
        gardenStore: GardenStore,
        userStore: UserStore
    ) async throws -> URL {
        isExporting = true
        defer { isExporting = false }
        
        // 创建备份数据包
        let backup = BackupData(
            version: "1.0",
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            waterRecords: waterStore.records,
            plant: plantEngine.plant,
            gardenItems: gardenStore.items,
            userProfile: userStore.profile,
            metadata: BackupData.BackupMetadata(
                totalWaterRecords: waterStore.records.count,
                totalGardenItems: gardenStore.items.count,
                plantGrowthDays: Calendar.current.dateComponents(
                    [.day],
                    from: plantEngine.plant.plantedAt,
                    to: Date()
                ).day ?? 0
            )
        )
        
        // 编码为 JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(backup)
        
        // 保存到临时目录
        let fileName = generateBackupFileName()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        
        // 更新最后备份时间
        lastBackupDate = Date()
        
        return fileURL
    }
    
    /// 生成备份文件名（带时间戳）
    private func generateBackupFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "Bloom_Backup_\(timestamp).json"
    }
    
    // MARK: - 导入/恢复功能
    
    /// 从 JSON 文件导入数据
    /// - Parameter fileURL: 备份文件的 URL
    /// - Returns: 解析出的备份数据
    func importBackup(from fileURL: URL) async throws -> BackupData {
        isImporting = true
        defer { isImporting = false }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // 验证备份数据版本
        guard backup.version == "1.0" else {
            throw BackupError.unsupportedVersion(backup.version)
        }
        
        return backup
    }
    
    /// 恢复数据到应用中
    /// - Parameters:
    ///   - backup: 备份数据
    ///   - waterStore: 喝水记录 Store
    ///   - plantEngine: 植物引擎
    ///   - gardenStore: 花园 Store
    ///   - userStore: 用户 Store
    ///   - merge: 是否合并数据（true=合并，false=覆盖）
    func restoreData(
        from backup: BackupData,
        waterStore: WaterStore,
        plantEngine: PlantEngine,
        gardenStore: GardenStore,
        userStore: UserStore,
        merge: Bool = true
    ) {
        // 恢复喝水记录
        if merge {
            waterStore.mergeWithCloudRecords(backup.waterRecords)
        } else {
            waterStore.replaceAllRecords(with: backup.waterRecords)
        }
        
        // 恢复植物数据
        if let backupPlant = backup.plant {
            if merge {
                plantEngine.mergeWithCloudPlant(backupPlant)
            } else {
                plantEngine.replacePlant(with: backupPlant)
            }
        }
        
        // 恢复花园数据
        if merge {
            gardenStore.mergeWithCloudItems(backup.gardenItems)
        } else {
            gardenStore.replaceAllItems(with: backup.gardenItems)
        }
        
        // 恢复用户配置
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
        
        // iPad 支持
        if let sourceView = sourceView {
            activityVC.popoverPresentationController?.sourceView = sourceView
        }
        
        return activityVC
    }
    
    // MARK: - 备份管理
    
    /// 获取所有本地备份文件
    func getLocalBackups() -> [URL] {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        
        guard let contents = try? fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("Bloom_Backup_") }
            .sorted { $0.lastModifiedTimeInterval > $1.lastModifiedTimeInterval }
    }
    
    /// 删除旧的备份文件（保留最近 5 个）
    func cleanupOldBackups(keepCount: Int = 5) {
        let backups = getLocalBackups()
        if backups.count > keepCount {
            let toDelete = backups.dropFirst(keepCount)
            for url in toDelete {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    /// 计算备份文件大小
    func backupFileSize(at url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? UInt64 else {
            return "0 KB"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
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
    case exportFailed(String)
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "不支持的备份版本：\(version)"
        case .fileNotFound:
            return "备份文件未找到"
        case .invalidData:
            return "备份数据格式无效"
        case .exportFailed(let message):
            return "导出失败：\(message)"
        case .importFailed(let message):
            return "导入失败：\(message)"
        }
    }
}
