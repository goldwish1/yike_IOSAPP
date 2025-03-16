import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: UserSettings = UserSettings()
    
    private init() {
        loadSettings()
    }
    
    func updateSettings(_ newSettings: UserSettings) {
        let oldSettings = settings
        settings = newSettings
        saveSettings()
        
        // 检查提醒设置是否有变化
        if oldSettings.enableDailyReminder != newSettings.enableDailyReminder ||
           oldSettings.reminderTime != newSettings.reminderTime ||
           oldSettings.reminderStyle != newSettings.reminderStyle {
            // 更新提醒通知
            NotificationManager.shared.updateReminderNotifications(settings: newSettings)
        }
    }
    
    private func saveSettings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "userSettings"),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
    }
} 