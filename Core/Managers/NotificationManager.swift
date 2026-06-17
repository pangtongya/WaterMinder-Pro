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
            print("[Notification] 授权失败: \(error)")
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

    // MARK: - 喝水提醒（智能排程）

    /// 设置喝水提醒，文案随植物状态变化
    /// - Parameters:
    ///   - intervalMinutes: 提醒间隔（分钟）
    ///   - health: 植物健康度
    ///   - plantName: 植物名字
    ///   - isPaused: 是否暂停养护
    func scheduleReminder(intervalMinutes: Int, health: Double, plantName: String, isPaused: Bool = false) {
        // 暂停养护期间不发送通知
        guard !isPaused else {
            cancelReminders()
            return
        }
        
        cancelReminders()

        let interval = TimeInterval(max(15, intervalMinutes) * 60) // 最少 15 分钟，防止骚扰
        
        // 计算当前时间到夜间免打扰开始还有多久
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // 如果在免打扰时段，不排程
        guard !isInQuietHours(currentHour) else {
            print("[Notification] 免打扰时段，跳过排程")
            return
        }

        // 排程 maxScheduled 条错峰通知，文案各不相同
        for i in 0..<maxScheduled {
            let content = NotificationContent.pick(for: health, plantName: plantName)
            let nc = UNMutableNotificationContent()
            nc.title = content.title
            nc.body = content.body
            nc.sound = .default
            
            // 智能跳过免打扰时段
            let fireInterval = interval * Double(i + 1)
            let fireDate = now.addingTimeInterval(fireInterval)
            let fireHour = calendar.component(.hour, from: fireDate)
            
            // 如果触发时间在免打扰时段，跳过该条通知
            if isInQuietHours(fireHour) {
                continue
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(idPrefix)\(i)",
                content: nc,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error {
                    print("[Notification] 调度失败 #\(i): \(error)")
                }
            }
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

    /// 若已开启提醒，根据最新健康度刷新排程
    func refreshIfNeeded(enabled: Bool, intervalMinutes: Int, health: Double, plantName: String, isPaused: Bool = false) {
        guard enabled else { return }
        scheduleReminder(
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

