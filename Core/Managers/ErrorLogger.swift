//
//  ErrorLogger.swift
//  Bloom
//
//  全局错误日志管理器 - 防止崩溃，记录错误，提供降级方案
//

import Foundation
import os.log

final class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let logger = OSLog(subsystem: "com.bloom.app", category: "Error")
    private let maxLogCount = 100
    private var recentErrors: [ErrorRecord] = []
    private let queue = DispatchQueue(label: "com.bloom.errorlogger")
    
    private(set) var lastError: ErrorRecord?
    
    struct ErrorRecord: Identifiable {
        let id = UUID()
        let date: Date
        let message: String
        let file: String
        let function: String
        let line: Int
        let severity: Severity
        
        enum Severity: String {
            case debug = "DEBUG"
            case info = "INFO"
            case warning = "WARNING"
            case error = "ERROR"
            case critical = "CRITICAL"
        }
    }
    
    private init() {}
    
    // MARK: - 公共日志方法
    
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, severity: .debug, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, severity: .info, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, severity: .warning, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fullMessage = error.map { "\(message) - \($0.localizedDescription)" } ?? message
        log(fullMessage, severity: .error, file: file, function: function, line: line)
    }
    
    func critical(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fullMessage = error.map { "\(message) - \($0.localizedDescription)" } ?? message
        log(fullMessage, severity: .critical, file: file, function: function, line: line)
    }
    
    // MARK: - 安全执行包装器
    
    @discardableResult
    func safeExecute<T>(
        _ operation: String,
        defaultValue: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () throws -> T
    ) -> T {
        do {
            return try block()
        } catch {
            self.error("\(operation) 失败", error: error, file: file, function: function, line: line)
            return defaultValue
        }
    }
    
    func safeExecute(
        _ operation: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () throws -> Void
    ) {
        do {
            try block()
        } catch {
            self.error("\(operation) 失败", error: error, file: file, function: function, line: line)
        }
    }
    
    @MainActor
    func safeMainActorExecute(
        _ operation: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: @MainActor @escaping () throws -> Void
    ) {
        Task { @MainActor in
            do {
                try block()
            } catch {
                self.error("\(operation) 失败", error: error, file: file, function: function, line: line)
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func log(
        _ message: String,
        severity: ErrorRecord.Severity,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        let record = ErrorRecord(
            date: Date(),
            message: message,
            file: fileName,
            function: function,
            line: line,
            severity: severity
        )
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if severity == .error || severity == .critical {
                self.lastError = record
            }
            
            self.recentErrors.append(record)
            if self.recentErrors.count > self.maxLogCount {
                self.recentErrors.removeFirst(self.recentErrors.count - self.maxLogCount)
            }
        }
        
        let logMessage = "[\(severity.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        switch severity {
        case .debug:
            os_log(.debug, log: logger, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: logger, "%{public}@", logMessage)
        case .warning:
            os_log(.fault, log: logger, "%{public}@", logMessage)
        case .error, .critical:
            os_log(.error, log: logger, "%{public}@", logMessage)
        }
    }
    
    // MARK: - 获取错误记录
    
    func getRecentErrors() -> [ErrorRecord] {
        queue.sync { recentErrors }
    }
    
    func clearErrors() {
        queue.async { [weak self] in
            self?.recentErrors.removeAll()
            self?.lastError = nil
        }
    }
}
