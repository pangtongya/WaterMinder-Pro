// HealthManager.swift
// 健康App数据管理

import Foundation
import HealthKit

final class HealthManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = HealthManager()
    private let healthStore = HKHealthStore()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    var isAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return false }
        let status = healthStore.authorizationStatus(for: waterType)
        return status == .sharingAuthorized
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[HealthManager] Health data not available")
            return false
        }
        
        guard let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }
        
        let writeTypes: Set<HKSampleType> = [waterType]
        let readTypes: Set<HKObjectType> = [waterType]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            // 修复：返回实际授权状态，而不是 true
            return isAuthorized
        } catch {
            print("[HealthManager] Authorization error: \(error)")
            return false
        }
    }
    
    func saveWaterIntake(_ amount: Double, date: Date = Date()) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthError.invalidType
        }
        
        let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: amount / 1000.0) // 转换为升
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    func fetchTodayWaterIntake() async throws -> Double {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthError.invalidType
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let liters = sum.doubleValue(for: HKUnit.liter())
                continuation.resume(returning: liters * 1000.0) // 转换为毫升
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Error Handling
    
    enum HealthError: Error, LocalizedError {
        case invalidType
        case authorizationFailed
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidType: return "无效的健康数据类型"
            case .authorizationFailed: return "健康数据授权失败"
            case .saveFailed: return "保存健康数据失败"
            }
        }
    }
}
