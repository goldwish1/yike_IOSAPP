import Foundation
import AVFoundation

/// 音频资源守护者
/// 
/// 主要功能：
/// 1. 监控音频资源使用状态
/// 2. 检测并解决潜在的死锁情况
/// 3. 提供资源使用状态的标记接口
/// 4. 在资源卡住时提供强制释放机制
class AudioResourceGuardian {
    /// 单例访问
    static let shared = AudioResourceGuardian()
    
    /// 资源当前是否处于忙碌状态
    private var isResourceBusy = false
    
    /// 资源状态锁
    private let guardianLock = NSLock()
    
    /// 监控定时器
    private var watchdogTimer: Timer?
    
    /// 资源忙碌开始时间
    private var busyStartTime = Date()
    
    /// 初始化并设置监控
    private init() {
        setupWatchdog()
    }
    
    /// 设置资源监控定时器
    private func setupWatchdog() {
        // 在主线程上创建定时器，确保UI响应
        DispatchQueue.main.async { [weak self] in
            self?.watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkResourceStatus()
            }
            // 将定时器添加到主运行循环，确保在应用各种状态下都能正常运行
            if let timer = self?.watchdogTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }
    
    /// 检查资源状态，检测潜在死锁
    private func checkResourceStatus() {
        guardianLock.lock()
        defer { guardianLock.unlock() }
        
        if isResourceBusy {
            let elapsedTime = Date().timeIntervalSince(busyStartTime)
            
            // 1秒后开始打印警告日志
            if elapsedTime > 1.0 && elapsedTime <= 5.0 {
                let warningInterval = Int(elapsedTime)
                if warningInterval % 1 == 0 { // 每秒打印一次
                    print("【资源守护】警告：音频资源忙碌已持续 \(warningInterval) 秒")
                }
            }
            
            // 资源忙碌超过5秒，可能存在死锁，强制释放
            if elapsedTime > 5.0 {
                print("【资源守护】检测到可能的死锁，强制释放音频资源")
                forceReleaseResources()
            }
        }
    }
    
    /// 标记资源开始忙碌
    func markResourceBusy() {
        guardianLock.lock()
        isResourceBusy = true
        busyStartTime = Date()
        print("【资源守护】标记音频资源开始忙碌 - 时间: \(busyStartTime)")
        guardianLock.unlock()
    }
    
    /// 标记资源不再忙碌
    func markResourceIdle() {
        guardianLock.lock()
        defer { guardianLock.unlock() }
        
        if isResourceBusy {
            isResourceBusy = false
            let elapsedTime = Date().timeIntervalSince(busyStartTime)
            print("【资源守护】标记音频资源已空闲 - 忙碌持续时间: \(String(format: "%.3f", elapsedTime))秒")
        }
    }
    
    /// 强制释放资源，解决死锁
    private func forceReleaseResources() {
        // 先重置状态
        isResourceBusy = false
        
        // 重置AVAudioSession - 这是解决AVAudioPlayer死锁的有效方法
        do {
            // 先停用音频会话
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("【资源守护】已停用音频会话")
            
            // 短暂延迟后重新激活
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    print("【资源守护】已重新激活音频会话")
                } catch {
                    print("【资源守护】重新激活音频会话失败: \(error)")
                }
            }
        } catch {
            print("【资源守护】停用音频会话失败: \(error)")
            
            // 如果常规方法失败，使用更激进的方式
            forceClearAudioResources()
        }
    }
    
    /// 更激进的资源清理方法 - 仅在常规方法失败时使用
    private func forceClearAudioResources() {
        print("【资源守护】执行强制资源清理")
        
        // 发送通知让所有持有音频资源的对象释放资源
        NotificationCenter.default.post(
            name: Notification.Name("AudioResourceGuardian.ForceReleaseResources"),
            object: nil
        )
        
        // 尝试强制重置音频状态
        let audioSession = AVAudioSession.sharedInstance()
        
        // 循环尝试不同的类别设置，以打破可能的状态锁定
        for category in [
            AVAudioSession.Category.ambient,
            .playback,
            .playAndRecord,
            .soloAmbient
        ] {
            do {
                try audioSession.setCategory(category)
                try audioSession.setActive(false)
                try audioSession.setActive(true)
                print("【资源守护】成功使用类别 \(category) 重置音频会话")
                break
            } catch {
                print("【资源守护】使用类别 \(category) 重置失败: \(error)")
                continue
            }
        }
    }
    
    /// 析构函数 - 清理资源
    deinit {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
        print("【资源守护】AudioResourceGuardian被释放")
    }
} 