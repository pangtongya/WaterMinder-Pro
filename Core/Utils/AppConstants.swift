import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.pangtong.bloom"
    static let widgetKind = "BloomWidget"
    
    enum UserDefaultsKeys {
        static let isPro = "isPro"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let dailyGoal = "dailyGoal"
        static let lastActiveDate = "bloom.lastActiveDate"
        static let goalBonusAppliedDate = "bloom.goalBonusDate"
        static let lastStageUp = "bloom.lastStageUp"
        static let appInstallDate = "bloom.appInstallDate"
        static let appLaunchCount = "bloom.appLaunchCount"
        static let lastReviewPromptDate = "bloom.lastReviewPromptDate"
        static let hasReviewed = "bloom.hasReviewed"
        static let remindLaterDate = "bloom.remindLaterDate"
        static let neverRemindReview = "bloom.neverRemindReview"
    }
    
    enum WidgetKeys {
        static let todayIntake = "widget.todayIntake"
        static let dailyGoal = "widget.dailyGoal"
        static let plantName = "widget.plantName"
        static let plantHealth = "widget.plantHealth"
        static let plantStageRawValue = "widget.plantStageRawValue"
        static let plantStage = "widget.plantStage"
        static let plantSymbol = "widget.plantSymbol"
        static let isPaused = "widget.isPaused"
        static let lastUpdated = "widget.lastUpdated"
        static let dataDate = "widget.dataDate"
    }
    
    enum NotificationNames {
        static let refreshWidget = Notification.Name("bloom.refreshWidget")
        static let showPaywall = Notification.Name("bloom.showPaywall")
        static let applyOfflineDecay = Notification.Name("bloom.applyOfflineDecay")
    }
    
    enum Limits {
        static let freeGardenMaxPlants = 5
    }
    
    enum Health {
        static let defaultDailyGoal = 2000
        static let minDailyGoal = 500
        static let maxDailyGoal = 10000
    }
    
    enum NotificationIdentifiers {
        static let waterReminder = "waterReminder"
    }

    // MARK: - 衰减常量（PlantEngine 与 BackgroundTaskManager 共享）
    enum Decay {
        /// 每小时衰减的健康度（后台任务和 plantEngine 共享此值）
        static let healthPerHour: Double = 2.0
        /// 植物长期缺水（超过此小时数）视为严重脱水
        static let criticalHoursThreshold: Double = 24
    }

    // MARK: - URL 配置（隐私政策、服务条款等）
    enum URLs {
        static let privacyPolicy = "https://pangtongya.github.io/Bloom-Website/privacy-policy.html"
        static let termsOfService = "https://pangtongya.github.io/Bloom-Website/terms.html"
        static let support = "https://pangtongya.github.io/Bloom-Website/support.html"
        static let website = "https://pangtongya.github.io/Bloom-Website/"
        static let appStore = "https://apps.apple.com/app/id6742091900"
        static let appStoreReview = "https://apps.apple.com/app/id6742091900?action=write-review"
    }
    
    // MARK: - 联系信息
    enum Contact {
        static let supportEmail = "support@bloomapp.com"
        static let twitterHandle = "@bloom_app"
        static let instagramHandle = "@bloom.app"
    }
    
    // MARK: - 评分配置
    enum Review {
        static let minDaysSinceInstall = 7
        static let minLaunchCount = 10
        static let minDaysBetweenPrompts = 30
        static let remindLaterDays = 7
        static let maxPromptsPerYear = 3
    }
}
