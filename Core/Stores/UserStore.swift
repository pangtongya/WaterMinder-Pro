// UserStore.swift
// 用户配置 store —— 目标、提醒、主题、Pro 状态

import Foundation
import SwiftUI

@MainActor
final class UserStore: ObservableObject {
    @Published private(set) var profile: UserProfile {
        didSet { persist() }
    }

    private let storage = PersistenceManager.shared
    private let filename = "user_profile.json"
    private let cloudSync = CloudSyncManager.shared
    
    /// 防抖同步
    private var syncTask: Task<Void, Never>?

    init() {
        profile = storage.load(UserProfile.self, filename: filename) ?? UserProfile()
    }

    // MARK: - 便捷访问

    var hasCompletedOnboarding: Bool { profile.hasCompletedOnboarding }
    var dailyGoal: Int { profile.dailyGoal }
    var reminderEnabled: Bool { profile.reminderEnabled }
    var reminderInterval: Int { profile.reminderInterval }
    var theme: AppTheme { profile.theme }
    var isPro: Bool { profile.isPro }

    var colorScheme: ColorScheme? {
        switch profile.theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    // MARK: - 修改入口

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        triggerSync()
    }

    func setDailyGoal(_ goal: Int) {
        profile.dailyGoal = max(500, min(10000, goal))
        triggerSync()
    }

    func setReminder(enabled: Bool) {
        profile.reminderEnabled = enabled
        triggerSync()
    }

    func setReminderInterval(_ interval: Int) {
        profile.reminderInterval = interval
        triggerSync()
    }

    func setTheme(_ theme: AppTheme) {
        profile.theme = theme
        triggerSync()
    }
    
    /// 更新主题 ID（新主题系统）
    func updateThemeID(_ themeID: String) {
        profile.selectedThemeID = themeID
        triggerSync()
    }

    func unlockPro(productID: String) {
        profile.isPro = true
        profile.proProductID = productID
        profile.proPurchaseDate = Date()
        triggerSync()
    }

    /// 重置（设置页用，不删喝水记录和植物）
    func resetSettings() {
        profile = UserProfile(hasCompletedOnboarding: true)
        triggerSync()
    }

    private func persist() {
        storage.save(profile, filename: filename)
    }
    
    /// 触发 iCloud 同步（防抖 3 秒）
    private func triggerSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await cloudSync.syncUserProfile(profile)
        }
    }

    // MARK: - 备份恢复
    
    /// 从备份恢复用户配置
    func restoreFromBackup(_ backupProfile: UserProfile, merge: Bool) {
        if merge {
            // 合并策略：只更新非默认值
            if backupProfile.hasCompletedOnboarding && !profile.hasCompletedOnboarding {
                completeOnboarding()
            }
            if backupProfile.dailyGoal != profile.dailyGoal {
                setDailyGoal(backupProfile.dailyGoal)
            }
            if backupProfile.reminderEnabled != profile.reminderEnabled {
                setReminder(enabled: backupProfile.reminderEnabled)
            }
            if backupProfile.reminderInterval != profile.reminderInterval {
                setReminderInterval(backupProfile.reminderInterval)
            }
            if backupProfile.theme != profile.theme {
                setTheme(backupProfile.theme)
            }
        } else {
            // 覆盖模式
            if backupProfile.hasCompletedOnboarding {
                completeOnboarding()
            }
            setDailyGoal(backupProfile.dailyGoal)
            setReminder(enabled: backupProfile.reminderEnabled)
            setReminderInterval(backupProfile.reminderInterval)
            setTheme(backupProfile.theme)
        }
    }
}
