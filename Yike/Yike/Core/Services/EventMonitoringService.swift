import Foundation
import SwiftUI

/// 事件监控服务 - 监测和解决可能的事件传递中断问题
///
/// 主要功能：
/// 1. 监控UI事件传递状态
/// 2. 定期检查可能中断的事件状态
/// 3. 自动恢复被中断的事件处理
/// 4. 过滤重叠事件，防止事件处理冲突
/// 5. 监控警告框状态并自动恢复
class EventMonitoringService {
    /// 单例访问
    static let shared = EventMonitoringService()
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// 事件追踪日志
    private var eventLog: [(event: String, timestamp: Date)] = []
    
    /// 是否启动了事件互斥模式
    private var eventMutexEnabled = false
    
    /// 最大的事件日志条数
    private let maxEventLogCount = 50
    
    /// 事件锁
    private let eventLock = NSLock()
    
    /// 警告框显示时间
    private var alertPresentedTime: Date?
    
    /// 最长警告框显示时间（秒）
    private let maxAlertDisplayTime: TimeInterval = 15.0
    
    /// 私有初始化方法
    private init() {
        setupMonitoring()
    }
    
    /// 设置监控
    private func setupMonitoring() {
        // 创建监控定时器，定期检查事件状态
        DispatchQueue.main.async { [weak self] in
            self?.monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkEventStatus()
                self?.checkAlertStatus()
            }
            
            // 确保定时器在各种RunLoop模式下都能运行
            if let timer = self?.monitoringTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
        
        print("【事件监控】事件监控服务已启动")
        
        // 监控应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    /// 应用进入前台
    @objc private func applicationDidBecomeActive() {
        eventLock.lock()
        eventMutexEnabled = false
        eventLock.unlock()
        
        print("【事件监控】应用进入前台，重置事件互斥模式")
        
        // 重置事件守护
        EventGuardian.shared.checkAndRecoverInterruptedState()
    }
    
    /// 应用进入后台
    @objc private func applicationWillResignActive() {
        // 清理事件日志
        eventLock.lock()
        eventLog.removeAll()
        eventLock.unlock()
        
        print("【事件监控】应用进入后台，清理事件日志")
    }
    
    /// 检查事件状态
    private func checkEventStatus() {
        // 检查是否有被中断的事件
        eventLock.lock()
        
        // 清理过期的事件日志（超过10分钟的）
        let now = Date()
        eventLog = eventLog.filter { now.timeIntervalSince($0.timestamp) < 600 }
        
        // 如果日志过多，只保留最近的
        if eventLog.count > maxEventLogCount {
            eventLog.removeFirst(eventLog.count - maxEventLogCount)
        }
        
        eventLock.unlock()
        
        // 调用事件守护的检查方法
        EventGuardian.shared.checkAndRecoverInterruptedState()
    }
    
    /// 检查警告框状态
    private func checkAlertStatus() {
        guard let alertTime = alertPresentedTime else { return }
        
        let now = Date()
        let displayDuration = now.timeIntervalSince(alertTime)
        
        // 如果警告框显示时间过长，自动重置状态
        if displayDuration > maxAlertDisplayTime {
            print("【事件监控】检测到警告框显示时间过长(\(String(format: "%.2f", displayDuration))秒)，自动恢复")
            resetAlertState()
        }
    }
    
    /// 重置警告框状态
    private func resetAlertState() {
        // 重置警告框状态
        EventGuardian.shared.registerAlertDismissed()
        alertPresentedTime = nil
        
        print("【事件监控】警告框状态已重置")
    }
    
    /// 记录警告框显示
    func recordAlertPresented() {
        alertPresentedTime = Date()
        print("【事件监控】记录警告框显示 - 时间: \(alertPresentedTime!)")
    }
    
    /// 记录警告框消失
    func recordAlertDismissed() {
        alertPresentedTime = nil
        print("【事件监控】记录警告框消失")
    }
    
    /// 记录事件
    /// - Parameter eventName: 事件名称
    func logEvent(_ eventName: String) {
        eventLock.lock()
        eventLog.append((event: eventName, timestamp: Date()))
        eventLock.unlock()
    }
    
    /// 启用事件互斥模式
    /// 在此模式下，只有一个事件可以被处理
    func enableEventMutex() {
        eventLock.lock()
        eventMutexEnabled = true
        eventLock.unlock()
        
        print("【事件监控】事件互斥模式已启用")
        
        // 2秒后自动禁用
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.disableEventMutex()
        }
    }
    
    /// 禁用事件互斥模式
    func disableEventMutex() {
        eventLock.lock()
        let wasEnabled = eventMutexEnabled
        eventMutexEnabled = false
        eventLock.unlock()
        
        if wasEnabled {
            print("【事件监控】事件互斥模式已禁用")
        }
    }
    
    /// 检查是否可以处理事件
    /// - Returns: 如果可以处理事件，返回true
    func canProcessEvent() -> Bool {
        eventLock.lock()
        let result = !eventMutexEnabled
        eventLock.unlock()
        
        return result
    }
    
    /// 析构函数
    deinit {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
} 