import SwiftUI

@main
struct YikeApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var navigationRouter = NavigationRouter.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(navigationRouter)
        }
    }
} 