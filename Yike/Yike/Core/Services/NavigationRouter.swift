import SwiftUI
import Combine

/// 应用内导航路由类型
enum AppRoute: Hashable {
    case home
    case study
    case settings
    case player(memoryItems: [MemoryItem], initialIndex: Int)
    case input
    case preview(text: String, shouldPopToRoot: Binding<Bool>)
    case previewEdit(memoryItem: MemoryItem, shouldPopToRoot: Binding<Bool>)
    case playSettings
    case reminderSettings
    case pointsCenter
    case pointsHistory
    case pointsRecharge
    case about
    case userAgreementView
    case privacyPolicyView
    
    // 实现Hashable协议
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine(0)
        case .study:
            hasher.combine(1)
        case .settings:
            hasher.combine(2)
        case .player(let memoryItems, let initialIndex):
            hasher.combine(3)
            hasher.combine(memoryItems.map { $0.id })
            hasher.combine(initialIndex)
        case .input:
            hasher.combine(4)
        case .preview(let text, _):
            hasher.combine(5)
            hasher.combine(text)
        case .previewEdit(let memoryItem, _):
            hasher.combine(6)
            hasher.combine(memoryItem.id)
        case .playSettings:
            hasher.combine(7)
        case .reminderSettings:
            hasher.combine(8)
        case .pointsCenter:
            hasher.combine(9)
        case .pointsHistory:
            hasher.combine(10)
        case .pointsRecharge:
            hasher.combine(11)
        case .about:
            hasher.combine(12)
        case .userAgreementView:
            hasher.combine(13)
        case .privacyPolicyView:
            hasher.combine(14)
        }
    }
    
    // 实现Equatable协议
    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home),
             (.study, .study),
             (.settings, .settings),
             (.input, .input),
             (.playSettings, .playSettings),
             (.reminderSettings, .reminderSettings),
             (.pointsCenter, .pointsCenter),
             (.pointsHistory, .pointsHistory),
             (.pointsRecharge, .pointsRecharge),
             (.about, .about),
             (.userAgreementView, .userAgreementView),
             (.privacyPolicyView, .privacyPolicyView):
            return true
        case (.player(let items1, let index1), .player(let items2, let index2)):
            return items1.map({ $0.id }) == items2.map({ $0.id }) && index1 == index2
        case (.preview(let text1, _), .preview(let text2, _)):
            return text1 == text2
        case (.previewEdit(let item1, _), .previewEdit(let item2, _)):
            return item1.id == item2.id
        default:
            return false
        }
    }
}

/// 导航路由管理器，负责管理应用内导航状态
class NavigationRouter: ObservableObject {
    static let shared = NavigationRouter()
    
    // 当前导航路径
    @Published var path = NavigationPath()
    
    // 当前选中的标签页
    @Published var selectedTab: ContentView.Tab = .home {
        didSet {
            // 当标签切换时，自动清空导航路径
            if oldValue != selectedTab {
                path = NavigationPath()
            }
        }
    }
    
    private init() {}
    
    /// 导航到指定路由
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    /// 返回上一级
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// 返回根视图
    func navigateToRoot() {
        path = NavigationPath()
    }
} 