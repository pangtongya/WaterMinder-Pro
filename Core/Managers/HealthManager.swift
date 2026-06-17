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

    // MARK: - 写入喝水记录

    func saveWater(_ amountML: Int, date: Date = Date()) async throws {
        guard let type = waterType, let store else { return }
        let quantity = HKQuantity(unit: .liter(), doubleValue: Double(amountML) / 1000.0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }
}
