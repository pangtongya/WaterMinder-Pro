// NotificationManager.swift
// 本地通知管理 —— 用植物情感文案，建立"它需要我"的责任感
//
// Phase 2 增强：
// - 暂停养护期间不发送通知
// - 智能时间控制（夜间免打扰）
// - 自适应频率（根据用户行为调整）
// - 更丰富的文案库

import Foundation
@preconcurrency import UserNotifications

final class NotificationManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    /// 同时排程的提醒条数上限（iOS 单 app 上限 64，我们取合理值）
    private let maxScheduled = 10
    private let idPrefix = "bloom.waterReminder."
    
    // 夜间免打扰时间段（22:00 - 08:00）
    private let quietHourStart = 22
    private let quietHourEnd = 8

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - 授权

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            #if DEBUG
            print("[Notification] 授权失败: \(error)")
            #endif
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            await withCheckedContinuation { cont in
                center.getNotificationSettings { settings in
                    cont.resume(returning: settings.authorizationStatus == .authorized)
                }
            }
        }
    }

    /// 当用户设置中开启了提醒但系统状态为未决定时请求授权
    /// 用户拒绝过则不打扰（避免反复弹窗）
    func requestAuthorizationIfNeeded() async {
        let settings = await withCheckedContinuation { (cont: CheckedContinuation<UNNotificationSettings, Never>) in
            center.getNotificationSettings { cont.resume(returning: $0) }
        }
        if settings.authorizationStatus == .notDetermined {
            let granted = await requestAuthorization()
            #if DEBUG
            print("[Notification] 授权结果: \(granted)")
            #endif
        }
    }

    // MARK: - 喝水提醒（智能排程）

    /// 用日历时间排程（iOS 推荐的可靠方式）
    /// 在 8:00 - 22:00 范围内按 interval 均匀分发，跳过免打扰时段
    /// 每次调用都会先清除旧的排程，确保不会与之前的配置残留冲突
    /// - Parameters:
    ///   - intervalMinutes: 提醒间隔（分钟），最少 15 分钟
    ///   - health: 植物健康度，用于挑选情感文案
    ///   - plantName: 植物名字
    ///   - isPaused: 是否暂停养护（暂停期间不发送）
    func scheduleSmartReminder(intervalMinutes: Int, health: Double, plantName: String, isPaused: Bool = false) async {
        guard !isPaused else {
            cancelReminders()
            return
        }

        guard await isAuthorized else {
            cancelReminders()
            return
        }

        let calendar = Calendar.current
        var next = Date()
        var scheduled = 0

        while scheduled < maxScheduled {
            guard let advanced = calendar.date(byAdding: .minute, value: max(15, intervalMinutes), to: next) else {
                break
            }
            next = advanced
            let hour = calendar.component(.hour, from: next)

            // 跳过免打扰时段（22:00 - 次日 08:00）
            if isInQuietHours(hour) { continue }

            let content = NotificationContent.pick(for: health, plantName: plantName)
            let nc = UNMutableNotificationContent()
            nc.title = content.title
            nc.body = content.body
            nc.sound = .default

            // 使用完整日期组件（year + month + day + hour + minute）
            // 只写 hour:minute 会导致系统匹配"下一次出现该时分"，在跨天时无法保证日期正确
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: next
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(idPrefix)\(scheduled)",
                content: nc,
                trigger: trigger
            )
            try? await center.add(request)
            scheduled += 1
        }
    }
    
    /// 检查是否在免打扰时段
    private func isInQuietHours(_ hour: Int) -> Bool {
        if quietHourStart > quietHourEnd {
            // 跨午夜：22:00 - 08:00
            return hour >= quietHourStart || hour < quietHourEnd
        } else {
            return hour >= quietHourStart && hour < quietHourEnd
        }
    }

    func cancelReminders() {
        // 先取出所有 pending id 再精确删除（避免遗漏）
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.idPrefix) }
            if !ids.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    // MARK: - 即时通知（达标庆祝 / 阶段升级）

    func sendInstant(title: String, body: String) {
        let nc = UNMutableNotificationContent()
        nc.title = title
        nc.body = body
        nc.sound = .default
        let request = UNNotificationRequest(
            identifier: "bloom.instant.\(UUID().uuidString)",
            content: nc,
            trigger: nil
        )
        center.add(request)
    }

    // MARK: - 测试通知

    func sendTest(plantName: String) {
        let msg = NotificationContent.pick(for: 60, plantName: plantName)
        sendInstant(title: msg.title, body: msg.body)
    }

    // MARK: - 重新排程（喝水后可调用，让文案跟上植物状态）

    /// 若已开启提醒，根据最新健康度刷新排程（喝水后可调用，让文案跟上植物状态）
    func refreshIfNeeded(enabled: Bool, intervalMinutes: Int, health: Double, plantName: String, isPaused: Bool = false) async {
        guard enabled else { return }
        await scheduleSmartReminder(
            intervalMinutes: intervalMinutes,
            health: health,
            plantName: plantName,
            isPaused: isPaused
        )
    }
    
    // MARK: - 自适应频率
    
    /// 根据用户行为调整提醒频率
    /// - Parameters:
    ///   - currentInterval: 当前间隔
    ///   - todayRecords: 今日喝水记录
    ///   - goalMet: 是否已达标
    /// - Returns: 建议的新间隔（分钟）
    func suggestAdaptiveInterval(
        currentInterval: Int,
        todayRecords: Int,
        goalMet: Bool
    ) -> Int {
        // 如果已达标，延长间隔（减少打扰）
        if goalMet && todayRecords >= 5 {
            return min(currentInterval + 30, 180) // 最长3小时
        }
        
        // 如果记录很少，缩短间隔（增加提醒）
        if todayRecords < 2 {
            return max(currentInterval - 15, 30) // 最短30分钟
        }
        
        // 保持当前间隔
        return currentInterval
    }
}

// MARK: - Delegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

