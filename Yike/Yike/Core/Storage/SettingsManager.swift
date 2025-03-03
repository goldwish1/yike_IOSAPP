import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: UserSettings = UserSettings()
    
    private init() {
        loadSettings()
    }
    
    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
        saveSettings()
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