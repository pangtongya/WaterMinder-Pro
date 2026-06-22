// PersistenceManager.swift
// 统一持久化层 —— 所有 store 共用，避免重复代码
//
// 设计：每个数据类型存一个 JSON 文件，防抖保存（1秒内合并多次写入），
// 退到后台时立即落盘。
//
// Phase 1.3 增强：
// - 完整错误处理与日志
// - 数据验证机制
// - 自动备份（每次保存前）
// - 损坏数据恢复
// - 写入重试机制

import Foundation
import UIKit
import os.log

// MARK: - 持久化错误类型

enum PersistenceError: LocalizedError {
    case directoryNotFound
    case fileNotFound(String)
    case readFailed(String, Error)
    case writeFailed(String, Error)
    case decodeFailed(String, Error)
    case encodeFailed(String, Error)
    case dataCorrupted(String)
    case validationFailed(String, String)
    case backupFailed(String, Error)
    case recoveryFailed(String, Error)
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return NSLocalizedString("Unable to access document directory", comment: "")
        case .fileNotFound(let filename):
            return String(format: NSLocalizedString("File not found: %@", comment: ""), filename)
        case .readFailed(let filename, let error):
            return String(format: NSLocalizedString("Read failed (%@): %@", comment: ""), filename, error.localizedDescription)
        case .writeFailed(let filename, let error):
            return String(format: NSLocalizedString("Write failed (%@): %@", comment: ""), filename, error.localizedDescription)
        case .decodeFailed(let filename, let error):
            return String(format: NSLocalizedString("Decode failed (%@): %@", comment: ""), filename, error.localizedDescription)
        case .encodeFailed(let filename, let error):
            return String(format: NSLocalizedString("Encode failed (%@): %@", comment: ""), filename, error.localizedDescription)
        case .dataCorrupted(let filename):
            return String(format: NSLocalizedString("Data corrupted: %@", comment: ""), filename)
        case .validationFailed(let filename, let reason):
            return String(format: NSLocalizedString("Data validation failed (%@): %@", comment: ""), filename, reason)
        case .backupFailed(let filename, let error):
            return String(format: NSLocalizedString("Backup failed (%@): %@", comment: ""), filename, error.localizedDescription)
        case .recoveryFailed(let filename, let error):
            return String(format: NSLocalizedString("Recovery failed (%@): %@", comment: ""), filename, error.localizedDescription)
        }
    }
}

// MARK: - 数据验证协议

/// 数据验证协议 - 所有需要持久化的模型都应实现
protocol Validatable {
    func validate() throws
}

// MARK: - 持久化日志

extension Logger {
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pangtong.bloom", category: "Persistence")
}

// MARK: - 持久化管理器

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let fm = FileManager.default
    private var pendingSaves: [String: DispatchWorkItem] = [:]
    private let maxRetryCount = 3
    private let maxBackupCount = 10
    
    // 备份目录
    private var backupDirectory: URL? {
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = docs.appendingPathComponent("backups")
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flushAll),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(flushAll),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        Logger.persistence.info("PersistenceManager initialized")
    }

    // MARK: - 读取

    /// 读取数据（带错误处理和恢复机制）
    func load<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        guard let url = url(for: filename) else {
            Logger.persistence.error("Failed to get URL for \(filename)")
            return nil
        }
        
        // 文件不存在
        guard fm.fileExists(atPath: url.path) else {
            Logger.persistence.debug("File not found: \(filename)")
            return nil
        }
        
        // 尝试读取
        do {
            let data = try Data(contentsOf: url)
            
            // 空文件检查
            guard !data.isEmpty else {
                Logger.persistence.warning("Empty file detected: \(filename)")
                return try recoverFromBackup(type, filename: filename)
            }
            
            // 尝试解码
            do {
                let decoded = try JSONDecoder().decode(type, from: data)
                Logger.persistence.debug("Successfully loaded \(filename)")
                return decoded
            } catch {
                Logger.persistence.error("Decode failed for \(filename): \(error)")
                return try recoverFromBackup(type, filename: filename)
            }
        } catch {
            Logger.persistence.error("Read failed for \(filename): \(error)")
            return try? recoverFromBackup(type, filename: filename)
        }
    }
    
    /// 从备份恢复数据
    private func recoverFromBackup<T: Decodable>(_ type: T.Type, filename: String) throws -> T? {
        Logger.persistence.info("Attempting to recover \(filename) from backup")
        
        guard let backupDir = backupDirectory else {
            throw PersistenceError.recoveryFailed(filename, PersistenceError.directoryNotFound)
        }
        
        // 查找最新的备份文件
        let contents = try fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
        let backups = contents.filter { url in
            let name = url.lastPathComponent
            return name.hasPrefix(filename.replacingOccurrences(of: ".json", with: "")) && name.contains("_")
        }.sorted { url1, url2 in
            let date1 = try? fm.attributesOfItem(atPath: url1.path)[.modificationDate] as? Date
            let date2 = try? fm.attributesOfItem(atPath: url2.path)[.modificationDate] as? Date
            return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
        }
        
        guard let latestBackup = backups.first else {
            Logger.persistence.warning("No backup found for \(filename)")
            return nil
        }
        
        // 尝试从备份加载
        do {
            let data = try Data(contentsOf: latestBackup)
            let decoded = try JSONDecoder().decode(type, from: data)
            Logger.persistence.info("Successfully recovered \(filename) from backup")
            
            // 恢复主文件
            if let fileURL = url(for: filename) {
                try? data.write(to: fileURL, options: .atomic)
            } else {
                Logger.persistence.error("Failed to get URL for \(filename)")
            }
            
            return decoded
        } catch {
            Logger.persistence.error("Backup recovery failed for \(filename): \(error)")
            throw PersistenceError.recoveryFailed(filename, error)
        }
    }

    // MARK: - 写入（防抖 + 自动备份 + 重试）

    /// 保存数据（带自动备份和重试机制）
    func save<T: Encodable>(_ value: T, filename: String) {
        guard let url = url(for: filename) else {
            Logger.persistence.error("Failed to get URL for \(filename)")
            return
        }

        // 取消上一次待写
        pendingSaves[filename]?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            do {
                // 编码
                let data = try JSONEncoder().encode(value)
                
                // 数据验证（如果实现了 Validatable 协议）
                if let validatable = value as? Validatable {
                    do {
                        try validatable.validate()
                    } catch {
                        Logger.persistence.warning("Validation failed for \(filename), skipping save: \(error)")
                        self.pendingSaves[filename] = nil
                        return
                    }
                }
                
                // 自动备份（保存前）
                try? self.createBackup(for: filename, data: data)
                
                // 带重试的写入
                try self.writeWithRetry(data, to: url, filename: filename)
                
                Logger.persistence.debug("Successfully saved \(filename)")
            } catch {
                Logger.persistence.error("Save failed for \(filename): \(error)")
            }
            
            self.pendingSaves[filename] = nil
        }
        pendingSaves[filename] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    /// 带重试的写入
    private func writeWithRetry(_ data: Data, to url: URL, filename: String, retryCount: Int = 0) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            if retryCount < maxRetryCount {
                Logger.persistence.warning("Write attempt \(retryCount + 1) failed for \(filename), retrying...")
                Thread.sleep(forTimeInterval: 0.1 * Double(retryCount + 1))
                try writeWithRetry(data, to: url, filename: filename, retryCount: retryCount + 1)
            } else {
                throw PersistenceError.writeFailed(filename, error)
            }
        }
    }
    
    /// 创建备份
    private func createBackup(for filename: String, data: Data) throws {
        guard let backupDir = backupDirectory else {
            throw PersistenceError.backupFailed(filename, PersistenceError.directoryNotFound)
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupFilename = filename.replacingOccurrences(of: ".json", with: "_\(timestamp).json")
        let backupURL = backupDir.appendingPathComponent(backupFilename)
        
        do {
            try data.write(to: backupURL, options: .atomic)
            Logger.persistence.debug("Backup created: \(backupFilename)")
            
            // 清理旧备份
            cleanupOldBackups(for: filename)
        } catch {
            Logger.persistence.warning("Failed to create backup for \(filename): \(error)")
            // 备份失败不影响主流程
        }
    }
    
    /// 清理旧备份
    private func cleanupOldBackups(for filename: String) {
        guard let backupDir = backupDirectory else { return }
        
        let baseName = filename.replacingOccurrences(of: ".json", with: "")
        do {
            let contents = try fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
            let backups = contents.filter { url in
                url.lastPathComponent.hasPrefix(baseName + "_")
            }.sorted { url1, url2 in
                let date1 = try? fm.attributesOfItem(atPath: url1.path)[.modificationDate] as? Date
                let date2 = try? fm.attributesOfItem(atPath: url2.path)[.modificationDate] as? Date
                return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
            }
            
            if backups.count > maxBackupCount {
                let toDelete = backups.dropFirst(maxBackupCount)
                for url in toDelete {
                    try? fm.removeItem(at: url)
                }
                Logger.persistence.debug("Cleaned up \(toDelete.count) old backups for \(filename)")
            }
        } catch {
            Logger.persistence.warning("Failed to cleanup backups for \(filename): \(error)")
        }
    }

    // MARK: - 退后台立即落盘

    @objc private func flushAll() {
        Logger.persistence.info("Flushing all pending saves")
        for (filename, item) in pendingSaves {
            item.cancel()
            item.perform()
            Logger.persistence.debug("Flushed \(filename)")
        }
        pendingSaves.removeAll()
    }

    // MARK: - 工具方法

    /// 获取所有已保存的文件
    func getSavedFiles() -> [String] {
        guard let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        do {
            let contents = try fm.contentsOfDirectory(atPath: dir.path)
            return contents.filter { $0.hasSuffix(".json") }
        } catch {
            Logger.persistence.error("Failed to list files: \(error)")
            return []
        }
    }
    
    /// 获取存储大小（字节）
    func getStorageSize() -> Int64 {
        var totalSize: Int64 = 0
        
        // 主文件
        if let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let contents = try fm.contentsOfDirectory(atPath: dir.path)
                for filename in contents where filename.hasSuffix(".json") {
                    let url = dir.appendingPathComponent(filename)
                    let attributes = try fm.attributesOfItem(atPath: url.path)
                    totalSize += Int64(attributes[.size] as? UInt64 ?? 0)
                }
            } catch {
                Logger.persistence.error("Failed to calculate storage size: \(error)")
            }
        }
        
        // 备份文件
        if let backupDir = backupDirectory {
            do {
                let contents = try fm.contentsOfDirectory(atPath: backupDir.path)
                for filename in contents where filename.hasSuffix(".json") {
                    let url = backupDir.appendingPathComponent(filename)
                    let attributes = try fm.attributesOfItem(atPath: url.path)
                    totalSize += Int64(attributes[.size] as? UInt64 ?? 0)
                }
            } catch {
                Logger.persistence.error("Failed to calculate backup size: \(error)")
            }
        }
        
        return totalSize
    }
    
    /// 清理所有数据（用于测试或重置）
    func clearAll() {
        // 清理主文件
        if let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let contents = try fm.contentsOfDirectory(atPath: dir.path)
                for filename in contents where filename.hasSuffix(".json") {
                    let url = dir.appendingPathComponent(filename)
                    try fm.removeItem(at: url)
                }
            } catch {
                Logger.persistence.error("Failed to clear files: \(error)")
            }
        }
        
        // 清理备份
        if let backupDir = backupDirectory {
            try? fm.removeItem(at: backupDir)
        }
        
        pendingSaves.forEach { $0.value.cancel() }
        pendingSaves.removeAll()
        
        Logger.persistence.warning("All data cleared")
    }

    // MARK: - 文件 URL

    private func url(for filename: String) -> URL? {
        guard let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.persistence.error("Document directory not found")
            return nil
        }
        return dir.appendingPathComponent(filename)
    }
}

// MARK: - 默认验证实现

extension Validatable {
    func validate() throws {
        // 默认不做验证，子类可以覆盖
    }
}
