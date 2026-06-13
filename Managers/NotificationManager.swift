// NotificationManager.swift
// 本地通知管理

import Foundation
@preconcurrency import UserNotifications

final class NotificationManager: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    var onSchedulingError: ((String) -> Void)?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("[NotificationManager] Authorization error: \(error)")
            return false
        }
    }
    
    func scheduleWaterReminder(interval: Int) {
        // 取消现有的提醒
        cancelWaterReminders()
        
        // 创建新的提醒
        let content = UNMutableNotificationContent()
        content.title = "💧 该喝水了"
        content.body = "记得补充水分，保持健康！"
        content.sound = .default
        content.badge = 1
        
        // 设置触发时间（每 interval 分钟）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval * 60), repeats: true)
        
        let request = UNNotificationRequest(identifier: "waterReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[NotificationManager] Schedule error: \(error)")
                DispatchQueue.main.async {
                    self.onSchedulingError?("提醒设置失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelWaterReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["waterReminder"])
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💧 WaterMinder 测试"
        content.body = "这是一条测试通知"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[NotificationManager] Test notification error: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getNotificationSettings() async -> UNNotificationSettings {
        await notificationCenter.notificationSettings()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知点击
        print("[NotificationManager] Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}
