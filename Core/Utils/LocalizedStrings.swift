//
//  LocalizedStrings.swift
//  Bloom
//
//  Centralized localized string constants.
//  Replace all hard-coded Chinese strings in Views with L.xxx.
//  This file drives both the UI and the Localizable.strings lookup.
//
//  Usage:
//    Text(L.health)
//    Text(String(format: L.plantHasntWatered, arguments: [plantName]))
//

import Foundation

// MARK: - Helper
// A simple wrapper that returns NSLocalizedString(key, comment: key).
// Keeping the API short (L.xxx) to keep views readable.
enum L {
    private static func s(_ key: String) -> String {
        NSLocalizedString(key, comment: key)
    }
}

// MARK: - Garden
extension L {
    static let health                 = s("健康度")
    static let plantHealth            = s("植物健康")
    static let status                 = s("状态")
    static let todayLog               = s("今日记录")
    static let myPlant                = s("我的植物")
    static let currentlyGrowing       = s("正在养护")
    static let carePaused             = s("暂停养护中")
    static let readyToHarvest         = s("可以收获了！")
    static let itGrew                 = s("长大啦！")
    static let keepNurturing          = s("继续守护")
    static let pauseExplanation       = s("暂停期间植物不会枯萎，最长可暂停14天。出差/旅行时非常有用。")
    static let proGardenLimit         = s("免费用户最多保存 5 株植物。升级 Pro 解锁无限花园！")
    static let harvestPlant           = s("收获 %@")
    static let harvestPlantTitle      = s("收获植物")
    static let daysRemaining          = s("剩余 %@ 天")
    static let plantHasntWatered      = s("%@ 还没喝到水")
    static let reachedStage           = s("进入了「%@」阶段")
    static let bloomTagline           = s("用 Bloom 养成喝水好习惯")
    static let gardenFull             = s("花园已满")
    static let myGarden               = s("我的花园")
    static let harvestWall            = s("收获墙")
    static let speciesCollection      = s("品种图鉴")
    static let notCollected           = s("未收集")
    static let daysToHarvest          = s("养护 %d 天")
    static let wiltBannerTitle        = s("植物枯萎了")
    static let wiltBannerBody        = s("坚持喝水就能复活，别放弃！")
}

// MARK: - Statistics
extension L {
    static let waterTrend             = s("喝水趋势")
    static let peakHydrationTime      = s("最佳喝水时间")
    static let weeklyHabits           = s("每周习惯")
    static let achievementProgress    = s("成就进度")
    static let unlocked               = s("已解锁")
    static let advancedStats          = s("高级统计")
    static let deepInsights           = s("深度洞察")
    static let plantGrowthJourney     = s("植物成长历程")
    static let deepDataInsights      = s("深度数据洞察")
    static let deepInsightsExplain   = s("解锁达标率分析、平均完成度、成长历程等深度数据，更科学地养成喝水习惯。")
    // 时间周期（Statistics）
    static let periodWeek            = s("周")
    static let periodMonth          = s("月")
    static let periodQuarter        = s("季")
    static let periodYear           = s("年")
    // 收获
    static let plantMatured         = s("%@ 已成熟！")
    static let congratulations       = s("恭喜！")
    static let reachedStageMsg       = s("你的植物已经成长到 %@ 阶段")
    static let stage               = s("阶段")
    static let daysCared            = s("养护天数")
    static let daysN               = s("%d 天")
    static let harvestAndSave       = s("收获并保存到收藏")
    // 成长进度
    static let maxLevel             = s("已满级")
    static let growthProgress       = s("成长进度")
}

// MARK: - Achievements
extension L {
    static let achievements           = s("成就")
    static let achievementUnlocked    = s("成就解锁！")
    static let amazing                = s("太棒了！")
    // Format
    static let streakDaysAchieved     = s("连续 %d 天达标")
    static let keepGoingForStreak     = s("再坚持 %d 天 → %@ %@")
    static let nextStage              = s("下一阶段：%@")
    // Milestones
    static let milestone3    = s("初露锋芒")
    static let milestone7    = s("坚持一周")
    static let milestone14   = s("两周达人")
    static let milestone21   = s("三周传奇")
    static let milestone30   = s("满月之约")
    static let milestone60   = s("双月坚守")
    static let milestone100  = s("百日不辍")
}

// MARK: - Settings
extension L {
    static let settings               = s("设置")
    static let dailyGoal              = s("每日目标")
    static let recommended2000        = s("建议成人每日饮水 2000ml")
    static let everyXMinutes          = s("每 %d 分钟")
    static let reminders              = s("提醒")
    static let reminderExplain        = s("开启后，植物口渴时会提醒你来浇水")
    static let connectHealth          = s("连接健康 App")
    static let healthApp              = s("健康 App")
    static let themeColor             = s("主题颜色")
    static let appearance             = s("外观")
    static let themeAppearance        = s("主题外观")
    static let chooseTheme            = s("选择你喜欢的主题外观")
    static let iCloudSync             = s("iCloud 同步")
    static let notSignedIn            = s("未登录")
    static let iCloudSyncExplain      = s("自动同步到 iCloud，多设备数据保持一致")
    static let dataBackup             = s("数据备份")
    static let exportBackup           = s("导出数据备份")
    static let restoreFromBackup      = s("从备份恢复")
    static let lastBackup             = s("上次备份")
    static let exportExplain          = s("导出 JSON 文件可保存到 Files App，用于数据备份或迁移")
    static let bloomProUnlocked       = s("Bloom Pro 已解锁")
    static let upgradeBloomPro        = s("升级 Bloom Pro")
    static let unlockMoreSpecies      = s("解锁更多品种")
    static let version                = s("版本")
    static let about                  = s("关于")
    static let plantName              = s("植物名字")
    static let species                = s("品种")
    static let pauseCare              = s("暂停养护")
    static let resumeCare             = s("恢复养护")
    static let businessTravel         = s("出差/旅行")
    static let goToSettings           = s("去设置")
    static let restore                = s("恢复")
    static let restorePurchases       = s("恢复购买")
    static let restoreSuccessful      = s("恢复成功")
    static let restoreFailed          = s("恢复失败")
    static let noPurchasesFound       = s("未找到已购买的记录")
    static let dataRestored           = s("数据已成功恢复")
    static let allowHealth            = s("请在系统设置中允许 Bloom 访问健康数据")
    static let allowNotifications     = s("请在系统设置中允许 Bloom 发送通知")
    static let healthPermission       = s("健康权限")
    static let notificationPermission = s("通知权限")
    static let confirmResumeCare      = s("确定要恢复养护吗？植物将重新开始生长。")
    static let proThankYou            = s("感谢您的支持！Pro 权益已解锁。")
    static let ok                    = s("好的")
}

// MARK: - Paywall
extension L {
    static let unlockBloomPro         = s("解锁 Bloom Pro")
    static let waterLog               = s("喝水记录")
    static let unlockMoreLives        = s("解锁更多生命")
    static let buildBeautifulGarden   = s("养出更美的花园，收集全部品种")
    static let upgradeToPro           = s("升级 Pro")
    static let unlimitedSpecies       = s("无限植物品种")
    static let all7PlantsDreamGarden  = s("解锁全部7种植物，打造梦幻花园")
    static let autoRenewExplain       = s("订阅自动续期，可随时在系统设置中取消")
    static let bestValue              = s("最划算")
    static let close                  = s("关闭")
    static let loading               = s("正在加载...")
    // Paywall feature descriptions
    static let advancedStatistics      = s("高级统计")
    static let advancedStatisticsDesc = s("完整的数据分析和可视化报告")
    static let customThemes          = s("自定义主题")
    static let customThemesDesc      = s("解锁所有 Pro 主题和外观")
    static let proThemes            = s("Pro 主题")
    static let harvested            = s("已收获")
    static let species             = s("品种")
    static let total               = s("总计")
    static let unlimitedPlants       = s("无限植物")
    static let unlimitedPlantsDesc   = s("解锁全部 7 种植物，打造梦幻花园")
    static let multiDeviceSync       = s("多设备同步")
    static let multiDeviceSyncDesc   = s("CloudKit 数据同步和备份")
    static let lifetimePurchase      = s("终身购买")
    static let proYearly            = s("Pro 年订阅")
    static let oneTimePurchase      = s("一次性购买，永久解锁")
    static let unlimitedCareAllYear  = s("全年无限养护")
    static let savePercent          = s("省 %d%% 相比订阅")
    static let popular             = s("人气之选")
    static let termsOfService        = s("服务条款")
    static let privacyPolicy         = s("隐私政策")
}

// MARK: - Dev / IAP
extension L {
    static let sandboxMode            = s("⚠️ 沙盒测试模式")
    static let devMode                = s("🧪 开发模式")
    static let configureIAPFirst      = s("请在 App Store Connect 配置商品后测试")
    static let addEnvVar              = s("或在 Scheme 中添加 BLOOM_DEV_MODE=1 环境变量")
    static let noIAPConfigured        = s("暂未配置内购商品")
}

// MARK: - Onboarding
extension L {
    static let keepPlantAlive         = s("养活一株植物")
    static let justByDrinking         = s("只需要你好好喝水")
    static let growsWithEverySip      = s("你每喝一口水，它就长大一点")
    static let meetYourPlant          = s("认识一下你的植物")
    static let giveItAName            = s("给它起个名字")
    static let dailyWaterGoal         = s("每日喝水目标")
    static let mlPerDay2000           = s("ml / 天 · 建议成人每日 2000ml")
    static let letPlantTellYou        = s("让 %@ 在渴的时候")
    static let canTellYou             = s("能告诉你")
    static let notificationExplain    = s("开启通知，它口渴时会提醒你来浇水。\n不开启也可以，但你可能会忘了它。")
    static let notNow                 = s("暂不开启")
}
