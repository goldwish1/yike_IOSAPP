import UIKit
import SwiftUI

/// UIApplication的事件捕获扩展
extension UIApplication {
    /// 设置全局触摸事件捕获
    static func setupGlobalTouchEventCapture() {
        // 在主线程上执行
        DispatchQueue.main.async {
            // 移除先前可能存在的捕获视图
            removeExistingCaptureView()
            
            // 获取应用的主窗口（iOS 15适配）
            let window = getKeyWindow()
            if let window = window {
                // 创建隐形的事件捕获视图
                let eventCaptureView = TouchEventCaptureView(frame: window.bounds)
                eventCaptureView.tag = 999999
                eventCaptureView.isUserInteractionEnabled = true // 改为可交互，但不阻止事件传递
                
                // 添加到窗口的最上层
                window.addSubview(eventCaptureView)
                
                // 确保视图始终位于顶层
                window.bringSubviewToFront(eventCaptureView)
                
                print("【事件保护】全局触摸事件捕获已设置")
            }
        }
    }
    
    /// 移除已存在的捕获视图
    private static func removeExistingCaptureView() {
        // 获取应用的主窗口（iOS 15适配）
        if let window = getKeyWindow() {
            // 查找并移除已存在的捕获视图
            if let existingView = window.viewWithTag(999999) {
                existingView.removeFromSuperview()
                print("【事件保护】已移除旧的触摸事件捕获视图")
            }
        }
    }
    
    /// 获取主窗口（兼容iOS 15+和旧版iOS）
    private static func getKeyWindow() -> UIWindow? {
        // iOS 15及以上版本使用UIWindowScene.windows
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first(where: { $0.isKeyWindow })
        } else {
            // iOS 15以下版本使用旧方法
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
    }
}

/// 触摸事件捕获视图
class TouchEventCaptureView: UIView {
    /// 上次触摸事件时间
    private var lastTouchTime = Date.distantPast
    
    /// 触摸事件超过此间隔才会通过
    private let minTouchInterval: TimeInterval = 0.3
    
    /// 上次触摸位置
    private var lastTouchLocation: CGPoint?
    
    /// 位置容差（像素）
    private let locationTolerance: CGFloat = 10.0
    
    /// 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    /// 接口初始化
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    /// 设置视图
    private func setupView() {
        // 设置为完全透明
        backgroundColor = .clear
        alpha = 0.0
        isOpaque = false
        
        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 设置为不阻止事件传递
        isUserInteractionEnabled = true
    }
    
    /// 应用激活时重置状态
    @objc private func applicationDidBecomeActive() {
        lastTouchTime = Date.distantPast
        lastTouchLocation = nil
    }
    
    /// 开始触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // 获取触摸位置
        let location = touch.location(in: self)
        
        // 处理触摸事件
        handleTouchEvent(at: location)
        
        // 向下传递事件
        super.touchesBegan(touches, with: event)
    }
    
    /// 处理触摸事件
    private func handleTouchEvent(at location: CGPoint) {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastTouchTime)
        
        // 检查是否是重复触摸（相同位置）
        let isRepeatedTouchAtSameLocation = isRepeatedTouch(at: location)
        
        // 记录事件
        EventMonitoringService.shared.logEvent("TouchEvent")
        
        // 如果触摸过于频繁，或者是相同位置的重复触摸，启用事件互斥
        if timeInterval < minTouchInterval || isRepeatedTouchAtSameLocation {
            print("【事件保护】检测到频繁触摸事件，间隔: \(String(format: "%.2f", timeInterval))秒, 重复位置: \(isRepeatedTouchAtSameLocation)")
            EventMonitoringService.shared.enableEventMutex()
        }
        
        // 检查当前是否有警告框显示
        if isAlertCurrentlyActive() {
            // 如果存在警告框且触摸过于频繁，增加额外保护
            if timeInterval < minTouchInterval * 2 {
                print("【事件保护】警告框显示期间检测到频繁触摸，增加额外保护")
                EventMonitoringService.shared.enableEventMutex()
            }
        }
        
        // 更新上次触摸时间和位置
        lastTouchTime = now
        lastTouchLocation = location
    }
    
    /// 检查是否是相同位置的重复触摸
    private func isRepeatedTouch(at location: CGPoint) -> Bool {
        guard let lastLocation = lastTouchLocation else {
            return false
        }
        
        // 计算距离
        let distance = hypot(location.x - lastLocation.x, location.y - lastLocation.y)
        return distance < locationTolerance
    }
    
    /// 检查当前是否有警告框显示
    private func isAlertCurrentlyActive() -> Bool {
        // 从EventGuardian获取警告框状态
        return EventGuardian.shared.isAlertCurrentlyActive()
    }
    
    /// 禁止事件拦截，允许所有事件通过
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 监控点击，但不拦截
        let result = super.hitTest(point, with: event)
        if result == self {
            return nil // 返回nil表示不拦截事件
        }
        return result
    }
    
    /// 析构函数
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 