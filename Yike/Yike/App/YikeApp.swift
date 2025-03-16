import SwiftUI

@main
struct YikeApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var navigationRouter = NavigationRouter.shared
    
    init() {
        // 请求通知权限
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("通知权限已授予")
                // 初始化通知
                NotificationManager.shared.updateReminderNotifications(settings: SettingsManager.shared.settings)
            } else {
                print("通知权限被拒绝")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(navigationRouter)
        }
    }
} 