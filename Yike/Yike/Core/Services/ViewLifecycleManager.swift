import Foundation
import SwiftUI
import Combine

/// 视图生命周期管理器
/// 
/// 负责管理视图的生命周期状态，确保资源释放和UI操作的分离
/// 主要功能:
/// 1. 提供视图生命周期状态管理
/// 2. 确保dismiss操作能安全执行
/// 3. 处理资源释放与UI操作分离
class ViewLifecycleManager: ObservableObject {
    /// 单例访问
    static let shared = ViewLifecycleManager()
    
    /// 生命周期状态
    enum LifecycleState {
        case active          // 视图活跃
        case deactivating    // 视图正在准备退出
        case releasing       // 正在释放资源
        case dismissed       // 视图已退出
        case error           // 出现错误
    }
    
    /// 当前状态
    @Published private(set) var state: LifecycleState = .active
    
    /// 状态锁
    private let stateLock = NSLock()
    
    /// 页面ID与状态映射
    private var pageStates: [String: LifecycleState] = [:]
    
    /// 页面资源释放完成标记
    private var pageResourceReleased: [String: Bool] = [:]
    
    /// 超时计时器
    private var timeoutTimers: [String: DispatchWorkItem] = [:]
    
    /// 私有初始化
    private init() {
        print("【生命周期管理】ViewLifecycleManager初始化")
    }
    
    /// 注册页面
    /// - Parameter pageId: 页面唯一标识
    func registerPage(pageId: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        pageStates[pageId] = .active
        pageResourceReleased[pageId] = false
        
        print("【生命周期管理】注册页面: \(pageId), 状态: 活跃")
    }
    
    /// 开始退出页面
    /// - Parameters:
    ///   - pageId: 页面唯一标识
    ///   - completion: 完成回调
    func beginDismiss(pageId: String, completion: @escaping () -> Void) {
        stateLock.lock()
        
        // 检查页面是否已注册
        guard pageStates[pageId] != nil else {
            stateLock.unlock()
            print("【生命周期管理】无法退出未注册的页面: \(pageId)")
            return
        }
        
        // 更新状态
        pageStates[pageId] = .deactivating
        stateLock.unlock()
        
        print("【生命周期管理】页面开始退出: \(pageId)")
        
        // 设置超时保护，确保最终会调用dismiss
        let timeoutItem = DispatchWorkItem { [weak self] in
            print("【生命周期管理】页面退出超时保护触发: \(pageId)")
            self?.forceDismiss(pageId: pageId, completion: completion)
        }
        
        stateLock.lock()
        timeoutTimers[pageId] = timeoutItem
        stateLock.unlock()
        
        // 2秒超时保护
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timeoutItem)
    }
    
    /// 标记资源释放开始
    /// - Parameter pageId: 页面唯一标识
    func beginResourceRelease(pageId: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        // 检查页面是否已注册
        guard pageStates[pageId] != nil else {
            print("【生命周期管理】无法处理未注册页面的资源释放: \(pageId)")
            return
        }
        
        // 更新状态
        pageStates[pageId] = .releasing
        
        print("【生命周期管理】页面开始资源释放: \(pageId)")
    }
    
    /// 标记资源释放完成
    /// - Parameters:
    ///   - pageId: 页面唯一标识
    ///   - completion: 完成回调
    func resourceReleaseCompleted(pageId: String, completion: @escaping () -> Void) {
        stateLock.lock()
        
        // 检查页面是否已注册
        guard let state = pageStates[pageId] else {
            stateLock.unlock()
            print("【生命周期管理】无法处理未注册页面的资源释放完成: \(pageId)")
            return
        }
        
        // 标记资源已释放
        pageResourceReleased[pageId] = true
        
        // 如果页面正在退出或释放资源，继续dismiss流程
        if state == .deactivating || state == .releasing {
            stateLock.unlock()
            completeDismiss(pageId: pageId, completion: completion)
        } else {
            stateLock.unlock()
            print("【生命周期管理】页面资源已释放但不处于退出状态: \(pageId), 当前状态: \(state)")
        }
    }
    
    /// 强制dismiss页面
    /// - Parameters:
    ///   - pageId: 页面唯一标识
    ///   - completion: 完成回调
    func forceDismiss(pageId: String, completion: @escaping () -> Void) {
        stateLock.lock()
        
        // 检查页面是否已注册
        guard pageStates[pageId] != nil else {
            stateLock.unlock()
            print("【生命周期管理】无法强制退出未注册的页面: \(pageId)")
            return
        }
        
        // 更新状态
        pageStates[pageId] = .dismissed
        
        // 取消超时计时器
        if let timer = timeoutTimers[pageId] {
            timer.cancel()
            timeoutTimers[pageId] = nil
        }
        
        stateLock.unlock()
        
        print("【生命周期管理】强制退出页面: \(pageId)")
        
        // 确保在主线程执行UI操作
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
        
        // 延迟清理页面状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.cleanupPageState(pageId: pageId)
        }
    }
    
    /// 完成页面退出
    /// - Parameters:
    ///   - pageId: 页面唯一标识
    ///   - completion: 完成回调
    func completeDismiss(pageId: String, completion: @escaping () -> Void) {
        stateLock.lock()
        
        // 检查页面是否已注册
        guard pageStates[pageId] != nil else {
            stateLock.unlock()
            print("【生命周期管理】无法完成未注册页面的退出: \(pageId)")
            return
        }
        
        // 更新状态
        pageStates[pageId] = .dismissed
        
        // 取消超时计时器
        if let timer = timeoutTimers[pageId] {
            timer.cancel()
            timeoutTimers[pageId] = nil
        }
        
        stateLock.unlock()
        
        print("【生命周期管理】完成页面退出: \(pageId)")
        
        // 确保在主线程执行UI操作
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
        
        // 延迟清理页面状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.cleanupPageState(pageId: pageId)
        }
    }
    
    /// 清理页面状态
    /// - Parameter pageId: 页面唯一标识
    private func cleanupPageState(pageId: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        pageStates.removeValue(forKey: pageId)
        pageResourceReleased.removeValue(forKey: pageId)
        
        print("【生命周期管理】清理页面状态: \(pageId)")
    }
    
    /// 获取当前页面状态
    /// - Parameter pageId: 页面唯一标识
    /// - Returns: 页面状态，如果未注册则返回nil
    func getPageState(pageId: String) -> LifecycleState? {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return pageStates[pageId]
    }
    
    /// 检查页面是否已注册
    /// - Parameter pageId: 页面唯一标识
    /// - Returns: 是否已注册
    func isPageRegistered(pageId: String) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return pageStates[pageId] != nil
    }
    
    /// 检查资源是否已释放
    /// - Parameter pageId: 页面唯一标识
    /// - Returns: 资源是否已释放
    func isResourceReleased(pageId: String) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return pageResourceReleased[pageId] == true
    }
}

/// SwiftUI视图生命周期修饰符
struct ManagedLifecycleModifier: ViewModifier {
    /// 页面唯一标识
    let pageId: String
    
    /// 生命周期管理器
    @ObservedObject private var lifecycleManager = ViewLifecycleManager.shared
    
    /// dismiss环境变量
    @Environment(\.dismiss) private var dismiss
    
    /// 视图出现时
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 注册页面
                lifecycleManager.registerPage(pageId: pageId)
            }
            .onDisappear {
                // 页面消失时不做特殊处理，因为可能是由其他视图覆盖导致的
                // 真正的退出逻辑在专门的方法中处理
                print("【生命周期管理】页面消失: \(pageId)")
            }
    }
}

/// 视图扩展，添加生命周期管理
extension View {
    /// 添加生命周期管理
    /// - Parameter id: 页面唯一标识
    /// - Returns: 添加了生命周期管理的视图
    func withManagedLifecycle(id: String) -> some View {
        self.modifier(ManagedLifecycleModifier(pageId: id))
    }
} 