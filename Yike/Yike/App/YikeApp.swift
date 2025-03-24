import SwiftUI

@main
struct YikeApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var navigationRouter = NavigationRouter.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        // 初始化事件保护系统
        // 事件保护器 - 确保事件传递不被中断
        _ = EventGuardian.shared
        // 事件监控服务 - 监测和解决可能的事件传递中断问题  
        _ = EventMonitoringService.shared
        // 设置全局触摸事件捕获
        UIApplication.setupGlobalTouchEventCapture()
        
        // 初始化视图生命周期管理器
        _ = ViewLifecycleManager.shared
        // 初始化全局资源监视器
        _ = GlobalResourceMonitor.shared
        
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
                .environmentObject(networkMonitor)
        }
    }
} 