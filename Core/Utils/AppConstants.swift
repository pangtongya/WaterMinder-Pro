import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.pangtong.bloom"
    static let widgetKind = "BloomWidget"

    enum UserDefaultsKeys {
        static let isPro = "isPro"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let dailyGoal = "dailyGoal"
        static let reminderEnabled = "reminderEnabled"
        static let reminderIntervalMinutes = "reminderIntervalMinutes"
        static let lastActiveDate = "lastActiveDate"
        static let themeName = "themeName"
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
}
