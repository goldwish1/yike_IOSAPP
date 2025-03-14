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
        case .about:
            hasher.combine(11)
        case .userAgreementView:
            hasher.combine(12)
        case .privacyPolicyView:
            hasher.combine(13)
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
    @Published var selectedTab: ContentView.Tab = .home
    
    // 各种导航状态
    @Published var navigateToInput = false
    @Published var navigateToPreview = false
    @Published var navigateToEdit = false
    @Published var shouldPopToRoot = false
    
    // 临时存储导航参数
    var previewText: String = ""
    var editingMemoryItem: MemoryItem? = nil
    
    private init() {}
    
    /// 导航到指定路由
    func navigate(to route: AppRoute) {
        if #available(iOS 16.0, *) {
            path.append(route)
        } else {
            // iOS 16以下版本使用传统导航方式
            switch route {
            case .home:
                selectedTab = .home
            case .study:
                selectedTab = .study
            case .settings:
                selectedTab = .settings
            case .input:
                navigateToInput = true
            case .preview(let text, _):
                previewText = text
                navigateToPreview = true
            case .previewEdit(let memoryItem, _):
                editingMemoryItem = memoryItem
                navigateToEdit = true
            default:
                // 其他路由在各视图中处理
                break
            }
        }
    }
    
    /// 返回上一级
    func navigateBack() {
        if #available(iOS 16.0, *) {
            if !path.isEmpty {
                path.removeLast()
            }
        }
    }
    
    /// 返回根视图
    func navigateToRoot() {
        if #available(iOS 16.0, *) {
            path = NavigationPath()
        } else {
            shouldPopToRoot = true
        }
    }
} 