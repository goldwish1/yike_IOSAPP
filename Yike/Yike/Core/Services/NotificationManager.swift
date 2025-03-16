import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 检查通知权限状态
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // 根据用户设置更新提醒通知
    func updateReminderNotifications(settings: UserSettings) {
        // 如果未启用提醒，则移除所有提醒通知
        if !settings.enableDailyReminder {
            removeAllReminderNotifications()
            return
        }
        
        // 移除现有的提醒通知，然后重新创建
        removeAllReminderNotifications { [weak self] in
            self?.scheduleReminderNotification(settings: settings)
        }
    }
    
    // 移除所有提醒通知
    func removeAllReminderNotifications(completion: (() -> Void)? = nil) {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        completion?()
    }
    
    // 调度提醒通知
    private func scheduleReminderNotification(settings: UserSettings) {
        // 获取用户设置的提醒时间
        let calendar = Calendar.current
        let reminderTime = settings.reminderTime
        
        // 提取小时和分钟
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "记得住"
        content.body = "是时候复习您的学习内容了"
        content.categoryIdentifier = "reminder"
        
        // 根据提醒样式设置声音和震动
        switch settings.reminderStyle {
        case .notificationOnly:
            // 仅通知，不设置声音
            break
        case .notificationAndSound:
            // 通知+声音
            content.sound = UNNotificationSound.default
        case .notificationAndVibration:
            // 通知+震动（在iOS中，震动是通过自定义声音实现的）
            content.sound = UNNotificationSound.defaultCritical
        }
        
        // 创建每日触发器
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        notificationCenter.add(request) { error in
            if let error = error {
                print("添加提醒通知失败: \(error.localizedDescription)")
            } else {
                print("成功添加提醒通知，时间: \(hour):\(minute)")
            }
        }
    }
} 