// UserProfile.swift
// 用户配置 —— 目标、提醒、主题、Pro 状态

import Foundation

struct UserProfile: Codable {
    var hasCompletedOnboarding: Bool = false
    var dailyGoal: Int = 2000          // 毫升
    var reminderEnabled: Bool = false
    var reminderInterval: Int = 60     // 分钟
    var theme: AppTheme = .system
    var selectedThemeID: String = "classic"  // 主题 ID
    var isPro: Bool = false            // Pro 解锁状态
    var hasMigratedLegacyData: Bool = false

    // Pro 相关交易凭证（StoreKit 用，阶段6 填充）
    var proPurchaseDate: Date? = nil
    var proProductID: String? = nil
}

// MARK: - AppTheme

enum AppTheme: String, CaseIterable, Codable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - 数据验证

extension UserProfile: Validatable {
    func validate() throws {
        // 每日目标必须在合理范围内（500ml - 10000ml）
        guard dailyGoal >= 500 && dailyGoal <= 10000 else {
            throw PersistenceError.validationFailed(
                "UserProfile",
                "Invalid daily goal: \(dailyGoal)ml (must be 500-10000ml)"
            )
        }
        
        // 提醒间隔必须在合理范围内（15 - 240 分钟）
        guard reminderInterval >= 15 && reminderInterval <= 240 else {
            throw PersistenceError.validationFailed(
                "UserProfile",
                "Invalid reminder interval: \(reminderInterval)min (must be 15-240min)"
            )
        }
    }
}
