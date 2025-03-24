import Foundation
import SwiftUI

/// 事件保护器 - 负责保护事件传递过程，防止事件被中断
/// 
/// 主要功能：
/// 1. 事件队列管理：确保事件按照正确的顺序处理
/// 2. 弹窗互斥锁：确保一个时间点只能有一个弹窗显示
/// 3. 事件过滤：过滤重复的点击事件
/// 4. 事件传递锁定：当一个关键事件正在处理时，暂时锁定其他事件
/// 5. 恢复机制：如果事件处理被中断，提供自动恢复功能
class EventGuardian {
    /// 单例访问
    static let shared = EventGuardian()
    
    /// 事件状态锁
    private let eventLock = NSLock()
    
    /// 当前是否有活跃的警告框
    private var isAlertActive = false
    
    /// 当前是否有活跃的点击事件处理
    private var isEventProcessing = false
    
    /// 最后一次点击事件的时间戳
    private var lastEventTime = Date.distantPast
    
    /// 最小事件间隔（秒）
    private let minimumEventInterval: TimeInterval = 0.3
    
    /// 事件恢复队列
    private let eventRecoveryQueue = DispatchQueue(label: "com.yike.eventRecovery", qos: .userInitiated)
    
    /// 私有初始化方法
    private init() {
        setupEventMonitoring()
    }
    
    /// 设置事件监控
    private func setupEventMonitoring() {
        print("【事件保护】事件守护者已初始化")
        
        // 添加应用状态监控，在应用从后台返回时重置事件状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetEventState),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /// 重置事件状态
    @objc private func resetEventState() {
        eventLock.lock()
        isEventProcessing = false
        isAlertActive = false
        lastEventTime = Date.distantPast
        eventLock.unlock()
        
        print("【事件保护】事件状态已重置")
    }
    
    /// 检查事件是否可以处理
    /// - Returns: 如果事件可以处理，返回true
    func canProcessEvent() -> Bool {
        eventLock.lock()
        defer { eventLock.unlock() }
        
        // 检查是否有其他事件正在处理
        if isEventProcessing {
            print("【事件保护】事件被过滤：有其他事件正在处理")
            return false
        }
        
        // 检查距离上次事件的时间间隔
        let now = Date()
        if now.timeIntervalSince(lastEventTime) < minimumEventInterval {
            print("【事件保护】事件被过滤：事件间隔过短(\(String(format: "%.2f", now.timeIntervalSince(lastEventTime)))秒)")
            return false
        }
        
        // 更新状态
        lastEventTime = now
        isEventProcessing = true
        
        print("【事件保护】事件处理开始")
        return true
    }
    
    /// 标记事件处理完成
    func markEventProcessed() {
        eventLock.lock()
        let wasProcessing = isEventProcessing
        isEventProcessing = false
        eventLock.unlock()
        
        if wasProcessing {
            print("【事件保护】事件处理完成")
        }
    }
    
    /// 注册警告框显示
    func registerAlertPresented() {
        eventLock.lock()
        let wasAlertActive = isAlertActive
        isAlertActive = true
        eventLock.unlock()
        
        // 只有在状态实际变化时才记录
        if !wasAlertActive {
            print("【事件保护】警告框显示已注册")
            // 通知监控服务
            EventMonitoringService.shared.recordAlertPresented()
        }
    }
    
    /// 注册警告框消失
    func registerAlertDismissed() {
        eventLock.lock()
        let wasAlertActive = isAlertActive
        isAlertActive = false
        eventLock.unlock()
        
        // 只有在状态实际变化时才记录
        if wasAlertActive {
            print("【事件保护】警告框消失已注册")
            // 通知监控服务
            EventMonitoringService.shared.recordAlertDismissed()
        }
    }
    
    /// 检查是否可以显示新警告框
    func canPresentAlert() -> Bool {
        eventLock.lock()
        defer { eventLock.unlock() }
        
        if isAlertActive {
            print("【事件保护】警告框显示被阻止：已有活跃警告框")
            return false
        }
        
        return true
    }
    
    /// 检查当前是否有活跃的警告框
    func isAlertCurrentlyActive() -> Bool {
        eventLock.lock()
        defer { eventLock.unlock() }
        
        return isAlertActive
    }
    
    /// 执行带保护的点击操作
    /// - Parameter action: 要执行的操作
    func performProtectedAction(_ action: @escaping () -> Void) {
        // 检查是否可以处理事件
        if !canProcessEvent() {
            return
        }
        
        // 设置自动恢复
        let recoveryTimeout = DispatchWorkItem { [weak self] in
            print("【事件保护】操作超时，自动恢复")
            self?.markEventProcessed()
        }
        
        // 设置超时保护
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0, execute: recoveryTimeout)
        
        // 执行实际操作
        action()
        
        // 在主线程上延迟标记操作完成，避免过早释放锁
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // 取消超时保护
            recoveryTimeout.cancel()
            
            // 标记操作完成
            self?.markEventProcessed()
        }
    }
    
    /// 创建一个包装过的警告框绑定，带有警告框互斥保护
    /// - Parameter binding: 原始警告框绑定
    /// - Returns: 带有互斥保护的警告框绑定
    func protectedAlertBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                // 只返回值，不执行注册操作
                return binding.wrappedValue
            },
            set: { newValue in
                if newValue {
                    // 显示警告框时，检查是否可以显示
                    if self.canPresentAlert() {
                        binding.wrappedValue = true
                        self.registerAlertPresented()
                        print("【事件保护】警告框显示已注册 - 设置值")
                    } else {
                        print("【事件保护】警告框显示被阻止，已有活跃警告框")
                    }
                } else {
                    // 隐藏警告框时，注册警告框消失
                    binding.wrappedValue = false
                    self.registerAlertDismissed()
                }
            }
        )
    }
    
    /// 检查并恢复可能的中断状态
    func checkAndRecoverInterruptedState() {
        // 如果事件处理状态超过5秒，自动重置
        eventLock.lock()
        let now = Date()
        let eventDuration = now.timeIntervalSince(lastEventTime)
        let shouldRecover = isEventProcessing && eventDuration > 5.0
        eventLock.unlock()
        
        if shouldRecover {
            print("【事件保护】检测到事件处理时间过长(\(String(format: "%.2f", eventDuration))秒)，自动恢复")
            resetEventState()
        }
    }
    
    /// 析构函数
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

/// 点击事件过滤修饰符
struct EventFilterModifier: ViewModifier {
    /// 按钮点击间隔（秒）
    let interval: TimeInterval
    
    /// 最后一次点击时间
    @State private var lastClickTime = Date.distantPast
    
    /// 修改视图
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        let now = Date()
                        let timeInterval = now.timeIntervalSince(lastClickTime)
                        
                        if timeInterval < interval {
                            print("【事件保护】点击被过滤：间隔过短(\(String(format: "%.2f", timeInterval))秒)")
                        }
                        
                        lastClickTime = now
                    }
            )
    }
}

/// 视图扩展，添加事件过滤功能
extension View {
    /// 添加事件过滤保护
    /// - Parameter interval: 最短事件间隔
    /// - Returns: 带有事件过滤的视图
    func withEventFilter(interval: TimeInterval = 0.3) -> some View {
        self.modifier(EventFilterModifier(interval: interval))
    }
} 