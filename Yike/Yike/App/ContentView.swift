import SwiftUI

struct ContentView: View {
    @StateObject private var router = NavigationRouter.shared
    
    enum Tab {
        case home, study, settings
    }
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            // 首页标签
            if #available(iOS 16.0, *) {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(Tab.home)
            } else {
                NavigationView {
                    HomeView()
                }
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(Tab.home)
            }
            
            // 学习标签
            if #available(iOS 16.0, *) {
                NavigationStack(path: $router.path) {
                    StudyView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("学习", systemImage: "book")
                }
                .tag(Tab.study)
            } else {
                NavigationView {
                    StudyView()
                }
                .tabItem {
                    Label("学习", systemImage: "book")
                }
                .tag(Tab.study)
            }
            
            // 设置标签
            if #available(iOS 16.0, *) {
                NavigationStack(path: $router.path) {
                    SettingsView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(Tab.settings)
            } else {
                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(Tab.settings)
            }
        }
        .environmentObject(router)
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView()
        case .study:
            StudyView()
        case .settings:
            SettingsView()
        case .player(let memoryItems, let initialIndex):
            PlayerView(memoryItems: memoryItems, initialIndex: initialIndex)
        case .input:
            InputSelectionView()
        case .preview(let text, let shouldPopToRoot):
            PreviewEditView(text: text, shouldPopToRoot: shouldPopToRoot)
        case .previewEdit(let memoryItem, let shouldPopToRoot):
            PreviewEditView(memoryItem: memoryItem, shouldPopToRoot: shouldPopToRoot)
        case .playSettings:
            PlaySettingsView()
        case .reminderSettings:
            ReminderSettingsView()
        case .pointsCenter:
            PointsCenterView()
        case .pointsHistory:
            PointsHistoryView()
        case .about:
            AboutView()
        case .userAgreementView:
            UserAgreementView()
        case .privacyPolicyView:
            PrivacyPolicyView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager.shared)
    }
} 