// ReviewManager.swift
// 应用评分管理 —— 智能触发评分提示，促进用户口碑传播
//
// 功能：
// - 单例模式，使用 StoreKit 的 requestReview
// - 智能触发条件（安装天数、打开次数、目标达成、收获植物等）
// - 稍后再说 / 不再提示 选项
// - 所有计数持久化到 UserDefaults

import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - 公开属性
    
    /// 是否可以请求评分（基于所有条件判断）
    var canRequestReview: Bool {
        guard !defaults.bool(forKey: AppConstants.UserDefaultsKeys.neverRemindReview) else {
            return false
        }
        guard !defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasReviewed) else {
            return false
        }
        guard daysSinceInstall >= AppConstants.Review.minDaysSinceInstall else {
            return false
        }
        guard launchCount >= AppConstants.Review.minLaunchCount else {
            return false
        }
        if let lastPrompt = lastReviewPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents(
                [.day],
                from: lastPrompt,
                to: Date()
            ).day ?? 0
            guard daysSinceLastPrompt >= AppConstants.Review.minDaysBetweenPrompts else {
                return false
            }
        }
        if let remindLater = remindLaterDate {
            let daysSinceRemindLater = Calendar.current.dateComponents(
                [.day],
                from: remindLater,
                to: Date()
            ).day ?? 0
            guard daysSinceRemindLater >= AppConstants.Review.remindLaterDays else {
                return false
            }
        }
        return true
    }
    
    /// App 安装天数
    var daysSinceInstall: Int {
        guard let installDate = appInstallDate else {
            return 0
        }
        return Calendar.current.dateComponents(
            [.day],
            from: installDate,
            to: Date()
        ).day ?? 0
    }
    
    /// App 打开次数
    var launchCount: Int {
        defaults.integer(forKey: AppConstants.UserDefaultsKeys.appLaunchCount)
    }
    
    /// 上次提示评分的日期
    var lastReviewPromptDate: Date? {
        defaults.object(forKey: AppConstants.UserDefaultsKeys.lastReviewPromptDate) as? Date
    }
    
    /// 稍后再说的日期
    var remindLaterDate: Date? {
        defaults.object(forKey: AppConstants.UserDefaultsKeys.remindLaterDate) as? Date
    }
    
    /// App 安装日期
    var appInstallDate: Date? {
        if let date = defaults.object(forKey: AppConstants.UserDefaultsKeys.appInstallDate) as? Date {
            return date
        }
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let attributes = try? FileManager.default.attributesOfItem(atPath: documentsPath.path),
           let creationDate = attributes[.creationDate] as? Date {
            defaults.set(creationDate, forKey: AppConstants.UserDefaultsKeys.appInstallDate)
            return creationDate
        }
        return nil
    }
    
    // MARK: - App 生命周期追踪
    
    /// 记录 App 启动（每次启动时调用）
    func trackAppLaunch() {
        let currentCount = defaults.integer(forKey: AppConstants.UserDefaultsKeys.appLaunchCount)
        defaults.set(currentCount + 1, forKey: AppConstants.UserDefaultsKeys.appLaunchCount)
        
        if defaults.object(forKey: AppConstants.UserDefaultsKeys.appInstallDate) == nil {
            _ = appInstallDate
        }
    }
    
    // MARK: - 智能触发评分
    
    /// 尝试请求评分（在适当时机调用）
    /// - Parameters:
    ///   - waterStore: WaterStore 实例，用于判断今日目标是否达成
    ///   - gardenStore: GardenStore 实例，用于判断是否收获过植物
    /// - Returns: 是否实际触发了评分请求
    @discardableResult
    func tryRequestReview(waterStore: WaterStore, gardenStore: GardenStore) -> Bool {
        guard canRequestReview else {
            return false
        }
        guard waterStore.isGoalMetToday else {
            return false
        }
        guard gardenStore.totalCount >= 1 else {
            return false
        }
        
        requestReview()
        return true
    }
    
    /// 在收获植物后尝试请求评分
    func tryRequestReviewAfterHarvest(waterStore: WaterStore, gardenStore: GardenStore) {
        _ = tryRequestReview(waterStore: waterStore, gardenStore: gardenStore)
    }
    
    /// 在达成连续 7 天目标后尝试请求评分
    func tryRequestReviewAfterStreak(waterStore: WaterStore, gardenStore: GardenStore) {
        guard waterStore.currentStreak >= 7 else {
            return
        }
        _ = tryRequestReview(waterStore: waterStore, gardenStore: gardenStore)
    }
    
    /// 在 App 打开时尝试请求评分（状态良好时）
    func tryRequestReviewOnLaunch(waterStore: WaterStore, gardenStore: GardenStore) {
        _ = tryRequestReview(waterStore: waterStore, gardenStore: gardenStore)
    }
    
    // MARK: - 评分操作
    
    /// 请求评分（使用 StoreKit）
    func requestReview() {
        defaults.set(Date(), forKey: AppConstants.UserDefaultsKeys.lastReviewPromptDate)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    /// 跳转到 App Store 评分页面（手动评分）
    func openAppStoreForReview() {
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasReviewed)
        
        if let url = URL(string: AppConstants.URLs.appStoreReview) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 稍后再说（延迟 7 天）
    func remindLater() {
        defaults.set(Date(), forKey: AppConstants.UserDefaultsKeys.remindLaterDate)
    }
    
    /// 不再提示
    func neverRemind() {
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.neverRemindReview)
    }
    
    /// 标记用户已评分
    func markAsReviewed() {
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasReviewed)
    }
}
