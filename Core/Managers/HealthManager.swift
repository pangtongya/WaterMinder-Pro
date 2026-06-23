// HealthManager.swift
// 健康App数据同步 —— 喝水记录写入健康App
//
// 隐私合规说明：
// - 仅请求饮水量数据（dietaryWater），遵循数据最小化原则
// - 所有 HealthKit 操作均由用户主动触发
// - 写入数据时添加元数据，标明来源为 Bloom App
// - Info.plist 中需配置 NSHealthShareUsageDescription（读取）和 NSHealthUpdateUsageDescription（写入）

import Foundation
import HealthKit

final class HealthManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = HealthManager()

    /// 延迟创建 HKHealthStore，避免在不支持健康数据的设备上初始化崩溃
    private lazy var store: HKHealthStore? = {
        HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }()

    private override init() {
        super.init()
    }

    private var waterType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .dietaryWater)
    }

    // MARK: - 权限模式

    /// HealthKit 权限模式
    enum PermissionMode: String, Codable {
        case writeOnly   // 仅写入
        case readOnly    // 仅读取
        case readWrite   // 读写
    }

    /// 用户选择的权限模式（存储在 UserDefaults）
    private let permissionModeKey = "healthKitPermissionMode"
    private let writeEnabledKey = "healthKitWriteEnabled"
    private let readEnabledKey = "healthKitReadEnabled"

    /// 用户选择的权限模式
    var permissionMode: PermissionMode {
        get {
            guard let raw = storage.string(forKey: permissionModeKey),
                  let mode = PermissionMode(rawValue: raw) else {
                return .readWrite
            }
            return mode
        }
        set {
            storage.set(newValue.rawValue, forKey: permissionModeKey)
            switch newValue {
            case .writeOnly:
                storage.set(true, forKey: writeEnabledKey)
                storage.set(false, forKey: readEnabledKey)
            case .readOnly:
                storage.set(false, forKey: writeEnabledKey)
                storage.set(true, forKey: readEnabledKey)
            case .readWrite:
                storage.set(true, forKey: writeEnabledKey)
                storage.set(true, forKey: readEnabledKey)
            }
            objectWillChange.send()
        }
    }

    /// 写入健康 App 开关
    var writeEnabled: Bool {
        get { storage.bool(forKey: writeEnabledKey) }
        set {
            storage.set(newValue, forKey: writeEnabledKey)
            objectWillChange.send()
        }
    }

    /// 从健康 App 读取开关
    var readEnabled: Bool {
        get { storage.bool(forKey: readEnabledKey) }
        set {
            storage.set(newValue, forKey: readEnabledKey)
            objectWillChange.send()
        }
    }

    private let storage = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard

    // MARK: - 授权状态

    /// 整体授权状态（用于 UI 展示）
    enum AuthorizationStatus {
        case notDetermined  // 未决定
        case authorized     // 已授权
        case denied         // 已拒绝
        case unavailable    // 设备不支持

        var localizedDescription: String {
            switch self {
            case .notDetermined:
                return NSLocalizedString("未决定", comment: "HealthKit authorization not determined")
            case .authorized:
                return NSLocalizedString("已授权", comment: "HealthKit authorization granted")
            case .denied:
                return NSLocalizedString("已拒绝", comment: "HealthKit authorization denied")
            case .unavailable:
                return NSLocalizedString("不支持", comment: "HealthKit not available on device")
            }
        }
    }

    /// 当前授权状态
    var authorizationStatus: AuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType else {
            return .unavailable
        }
        let status = store?.authorizationStatus(for: type) ?? .notDetermined
        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingAuthorized:
            return .authorized
        case .sharingDenied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }

    /// 是否已授权写入
    var isWriteAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType else { return false }
        return store?.authorizationStatus(for: type) == .sharingAuthorized
    }

    /// 是否已授权读取
    var isReadAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType else { return false }
        return store?.authorizationStatus(for: type) == .sharingAuthorized
    }

    /// 兼容旧接口：是否已授权
    var isAuthorized: Bool {
        isWriteAuthorized || isReadAuthorized
    }

    // MARK: - 权限请求

    /// 请求 HealthKit 权限
    /// - Parameter mode: 请求的权限模式
    /// - Returns: 是否授权成功
    func requestAuthorization(mode: PermissionMode = .readWrite) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType,
              let store else {
            return false
        }

        let writeTypes: Set<HKSampleType>? = mode == .readOnly ? nil : [type]
        let readTypes: Set<HKObjectType>? = mode == .writeOnly ? nil : [type]

        return await withCheckedContinuation { cont in
            store.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error {
                    #if DEBUG
                    print("[Health] 授权失败: \(error)")
                    #endif
                }
                if success {
                    self.permissionMode = mode
                }
                cont.resume(returning: success)
            }
        }
    }

    /// 兼容旧接口：请求授权
    func requestAuthorization() async -> Bool {
        await requestAuthorization(mode: .readWrite)
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType else { return false }
        let status = store?.authorizationStatus(for: type) ?? .notDetermined
        if status == .notDetermined {
            return await requestAuthorization()
        }
        return status == .sharingAuthorized
    }

    // MARK: - 写入喝水记录

    /// 写入一条喝水记录到 Health App，并返回样本 UUID，以便后续反向同步删除
    /// 写入时添加元数据，标明数据来自 Bloom App
    @discardableResult
    func saveWater(_ amountML: Int, date: Date = Date()) async throws -> UUID {
        guard let type = waterType, let store else {
            throw HealthError.unavailable
        }
        guard writeEnabled else {
            throw HealthError.writeDisabled
        }
        guard isWriteAuthorized else {
            throw HealthError.notAuthorized
        }

        let quantity = HKQuantity(unit: .liter(), doubleValue: Double(amountML) / 1000.0)

        // 添加元数据，标明数据来源和同步标识
        let metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: "com.pangtong.bloom.water",
            HKMetadataKeySyncVersion: 1,
            "BloomSourceApp": "Bloom",
            "BloomSourceVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]

        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: metadata
        )

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UUID, Error>) in
            store.save(sample) { _, error in
                if let error {
                    cont.resume(throwing: self.convertError(error))
                } else {
                    cont.resume(returning: sample.uuid)
                }
            }
        }
    }

    // MARK: - 错误类型

    /// HealthKit 错误类型，用于区分不同错误场景
    enum HealthError: LocalizedError {
        case unavailable        // 设备不支持 HealthKit
        case notAuthorized      // 未授权
        case writeDisabled      // 写入功能被用户关闭
        case readDisabled       // 读取功能被用户关闭
        case dataUnavailable    // 数据不可用
        case unknown(Error)     // 未知错误

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return NSLocalizedString("当前设备不支持健康 App", comment: "HealthKit not available")
            case .notAuthorized:
                return NSLocalizedString("尚未授权访问健康数据", comment: "HealthKit not authorized")
            case .writeDisabled:
                return NSLocalizedString("写入健康 App 功能已关闭", comment: "HealthKit write disabled")
            case .readDisabled:
                return NSLocalizedString("从健康 App 读取功能已关闭", comment: "HealthKit read disabled")
            case .dataUnavailable:
                return NSLocalizedString("健康数据不可用", comment: "Health data unavailable")
            case .unknown(let error):
                return String(format: NSLocalizedString("健康数据同步失败：%@", comment: "Health sync failed"),
                              error.localizedDescription)
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .unavailable:
                return nil
            case .notAuthorized:
                return NSLocalizedString("请在系统设置中允许 Bloom 访问健康数据", comment: "Go to settings to authorize HealthKit")
            case .writeDisabled, .readDisabled:
                return NSLocalizedString("可在设置中开启健康 App 同步", comment: "Enable Health sync in settings")
            case .dataUnavailable:
                return nil
            case .unknown:
                return NSLocalizedString("请稍后重试或联系支持", comment: "Try again later or contact support")
            }
        }
    }

    /// 将 NSError 转换为 HealthError
    private func convertError(_ error: Error) -> HealthError {
        let nsError = error as NSError
        if nsError.domain == HKErrorDomain {
            if !isAuthorized {
                return .notAuthorized
            }
            return .unknown(error)
        }
        return .unknown(error)
    }

    /// 从 HealthKit 删除一条喝水样本（当用户在 App 内删除记录时反向同步）
    func deleteWater(sampleUUID: UUID) async {
        guard let type = waterType, let store else { return }
        guard writeEnabled, isWriteAuthorized else { return }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let predicate = HKQuery.predicateForObjects(with: [sampleUUID])
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                if let samples = samples, !samples.isEmpty {
                    store.delete(samples) { _, _ in
                        cont.resume()
                    }
                } else {
                    cont.resume()
                }
            }
            store.execute(query)
        }
    }

    // MARK: - 删除所有 Bloom 写入的数据

    /// 删除所有由 Bloom 写入健康 App 的数据
    /// - Returns: 删除的样本数量
    @discardableResult
    func deleteAllBloomData() async throws -> Int {
        guard let type = waterType, let store else {
            throw HealthError.unavailable
        }
        guard isWriteAuthorized else {
            throw HealthError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
            // 查询所有带有 Bloom 来源标识的样本
            let predicate = HKQuery.predicateForObjects(
                withMetadataKey: "BloomSourceApp",
                operatorType: .equalTo,
                value: "Bloom"
            )

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: self.convertError(error))
                    return
                }
                guard let samples = samples, !samples.isEmpty else {
                    cont.resume(returning: 0)
                    return
                }
                store.delete(samples) { success, error in
                    if let error {
                        cont.resume(throwing: self.convertError(error))
                    } else {
                        cont.resume(returning: success ? samples.count : 0)
                    }
                }
            }
            store.execute(query)
        }
    }

    /// 获取 Bloom 写入的样本数量
    func getBloomDataCount() async throws -> Int {
        guard let type = waterType, let store else {
            throw HealthError.unavailable
        }
        guard isReadAuthorized else {
            throw HealthError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
            let predicate = HKQuery.predicateForObjects(
                withMetadataKey: "BloomSourceApp",
                operatorType: .equalTo,
                value: "Bloom"
            )

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: self.convertError(error))
                } else {
                    cont.resume(returning: samples?.count ?? 0)
                }
            }
            store.execute(query)
        }
    }

    // MARK: - 读取喝水记录（用于双向同步）

    /// 从 Health App 读取指定时间范围内的喝水记录
    /// - Parameters:
    ///   - from: 起始时间（不含）
    ///   - to: 结束时间（含）
    /// - Returns: HKQuantitySample 数组，按时间倒序
    func fetchWaterRecords(from start: Date, to end: Date) async throws -> [HKQuantitySample] {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType,
              let store else {
            throw HealthError.unavailable
        }
        guard readEnabled else {
            throw HealthError.readDisabled
        }
        guard isReadAuthorized else {
            throw HealthError.notAuthorized
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: self.convertError(error))
                } else {
                    cont.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            store.execute(query)
        }
    }

    /// 调试日志：仅 DEBUG 模式输出
    private func logDebug(_ message: String) {
        #if DEBUG
        print("[Health] \(message)")
        #endif
    }
}
