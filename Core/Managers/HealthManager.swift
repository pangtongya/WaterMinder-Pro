// HealthManager.swift
// 健康App数据同步 —— 喝水记录写入健康App

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

    // MARK: - 授权

    var isAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType else { return false }
        return store?.authorizationStatus(for: type) == .sharingAuthorized
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = waterType,
              let store else { return false }
        do {
            try await store.requestAuthorization(toShare: [type], read: [type])
            return isAuthorized
        } catch {
            print("[Health] 授权失败: \(error)")
            return false
        }
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

    func saveWater(_ amountML: Int, date: Date = Date()) async throws {
        guard let type = waterType, let store else { return }
        let quantity = HKQuantity(unit: .liter(), doubleValue: Double(amountML) / 1000.0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
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
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            store.execute(query)
        }
    }
}
