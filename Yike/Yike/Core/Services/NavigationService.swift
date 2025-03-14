import SwiftUI

/// 导航服务类，提供在不同iOS版本上一致的导航体验
/// 用于帮助从NavigationView平滑过渡到NavigationStack
class NavigationService {
    static let shared = NavigationService()
    
    private init() {}
    
    /// 检查当前设备是否支持NavigationStack (iOS 16+)
    var supportsNavigationStack: Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }
}

/// 通用导航容器视图，根据iOS版本自动选择NavigationStack或NavigationView
struct AdaptiveNavigationContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }
}

/// 用于在iOS 16以下版本模拟navigationDestination的视图修饰符
struct LegacyNavigationLink<Destination: View>: ViewModifier {
    let destination: Destination
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if #available(iOS 16.0, *) {
                EmptyView()
            } else {
                NavigationLink(
                    destination: destination,
                    isActive: $isActive
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
}

extension View {
    /// 兼容iOS 16以下版本的导航目标设置
    /// - Parameters:
    ///   - isPresented: 是否显示目标视图的绑定
    ///   - destination: 目标视图构建器
    /// - Returns: 修改后的视图
    func adaptiveNavigationDestination<Destination: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        if #available(iOS 16.0, *) {
            return self.navigationDestination(isPresented: isPresented) {
                destination()
            }
        } else {
            return self.modifier(LegacyNavigationLink(
                destination: destination(),
                isActive: isPresented
            ))
        }
    }
}

/// 用于在iOS 16以下版本模拟navigationDestination(for:)的视图修饰符
struct LegacyTypedNavigationLink<Value: Hashable, Destination: View>: ViewModifier {
    let value: Value?
    let selection: Binding<Value?>
    let destination: (Value) -> Destination
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let value = value {
                if #available(iOS 16.0, *) {
                    EmptyView()
                } else {
                    NavigationLink(
                        destination: destination(value),
                        isActive: Binding(
                            get: { selection.wrappedValue == value },
                            set: { if $0 { selection.wrappedValue = value } else { selection.wrappedValue = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        }
    }
}

extension View {
    /// 兼容iOS 16以下版本的类型化导航链接
    /// - Parameters:
    ///   - value: 导航值
    ///   - selection: 当前选择的导航值绑定
    ///   - destination: 目标视图构建器
    /// - Returns: 修改后的视图
    func adaptiveNavigationLink<Value: Hashable, Destination: View>(
        value: Value?,
        selection: Binding<Value?>,
        @ViewBuilder destination: @escaping (Value) -> Destination
    ) -> some View {
        if #available(iOS 16.0, *) {
            return self.background(
                NavigationLink(value: value) {
                    EmptyView()
                }
                .hidden()
            )
            .navigationDestination(for: Value.self) { value in
                destination(value)
            }
        } else {
            return self.modifier(LegacyTypedNavigationLink(
                value: value,
                selection: selection,
                destination: destination
            ))
        }
    }
} 