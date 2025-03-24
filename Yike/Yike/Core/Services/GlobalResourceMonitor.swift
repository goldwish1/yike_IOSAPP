import Foundation
import SwiftUI
import AVFoundation
import Combine

/// 全局资源监视器
/// 
/// 负责监控系统级别的资源使用状态，在必要时进行强制资源清理
/// 主要功能:
/// 1. 监控播放资源使用情况
/// 2. 定期检查可能泄漏的资源
/// 3. 提供全局资源状态报告
/// 4. 在应用状态变化时主动清理资源
class GlobalResourceMonitor: ObservableObject {
    /// 单例访问
    static let shared = GlobalResourceMonitor()
    
    /// 监控状态
    enum MonitorState {
        case idle        // 空闲
        case monitoring  // 监控中
        case cleaning    // 清理中
        case error       // 错误
    }
    
    /// 资源类型
    enum ResourceType: String {
        case audio       // 音频资源
        case network     // 网络资源
        case storage     // 存储资源
        case system      // 系统资源
    }
    
    /// 当前状态
    @Published private(set) var state: MonitorState = .idle
    
    /// 资源使用状态
    private var resourceStatus: [ResourceType: Bool] = [:]
    
    /// 状态锁
    private let statusLock = NSLock()
    
    /// 监控计时器
    private var monitorTimer: Timer?
    
    /// 活跃页面ID数组
    private var activePages: Set<String> = []
    
    /// 发布者
    private var cancellables = Set<AnyCancellable>()
    
    /// 最后一次清理时间
    private var lastCleanupTime = Date.distantPast
    
    /// 私有初始化
    private init() {
        setupMonitoring()
        setupNotifications()
        
        // 初始化资源状态
        resourceStatus[.audio] = false
        resourceStatus[.network] = false
        resourceStatus[.storage] = false
        resourceStatus[.system] = false
        
        print("【资源监视】GlobalResourceMonitor初始化完成")
    }
    
    /// 设置监控
    private func setupMonitoring() {
        // 创建定时器，每3秒检查一次资源状态
        DispatchQueue.main.async { [weak self] in
            self?.monitorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.checkResourceStatus()
            }
            
            // 确保定时器在各种RunLoop模式下都能运行
            if let timer = self?.monitorTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
        
        state = .monitoring
        print("【资源监视】启动资源监控")
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        // 应用进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // 应用进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 低内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// 应用即将进入后台
    @objc private func applicationWillResignActive() {
        // 应用进入后台时，强制清理所有资源
        print("【资源监视】应用即将进入后台，执行资源清理")
        forceCleanupAllResources()
    }
    
    /// 应用进入前台
    @objc private func applicationDidBecomeActive() {
        // 应用进入前台时，检查资源状态
        print("【资源监视】应用进入前台，检查资源状态")
        checkResourceStatus()
    }
    
    /// 收到内存警告
    @objc private func didReceiveMemoryWarning() {
        // 收到内存警告时，强制清理资源
        print("【资源监视】收到内存警告，执行资源清理")
        forceCleanupAllResources()
    }
    
    /// 检查资源状态
    private func checkResourceStatus() {
        statusLock.lock()
        let currentState = state
        statusLock.unlock()
        
        // 如果当前正在清理，跳过检查
        if currentState == .cleaning {
            return
        }
        
        // 检查各类资源状态
        
        // 1. 检查音频资源
        let audioActive = AudioResourceGuardian.shared.isResourceBusy()
        
        statusLock.lock()
        resourceStatus[.audio] = audioActive
        statusLock.unlock()
        
        // 2. 如果发现长时间占用资源，执行强制清理
        // 音频资源持续占用超过30秒且没有活跃页面，则强制清理
        if audioActive && Date().timeIntervalSince(lastCleanupTime) > 30 && activePages.isEmpty {
            print("【资源监视】检测到音频资源长时间占用，执行强制清理")
            cleanupAudioResources()
        }
        
        print("【资源监视】资源状态检查完成: 音频资源活跃: \(audioActive)")
    }
    
    /// 注册页面
    /// - Parameter pageId: 页面唯一标识
    func registerPage(pageId: String) {
        statusLock.lock()
        activePages.insert(pageId)
        statusLock.unlock()
        
        print("【资源监视】注册页面: \(pageId), 当前活跃页面数: \(activePages.count)")
    }
    
    /// 注销页面
    /// - Parameter pageId: 页面唯一标识
    func unregisterPage(pageId: String) {
        statusLock.lock()
        activePages.remove(pageId)
        let pageCount = activePages.count
        statusLock.unlock()
        
        print("【资源监视】注销页面: \(pageId), 当前活跃页面数: \(pageCount)")
        
        // 如果没有活跃页面，执行资源检查
        if pageCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.checkResourceStatus()
            }
        }
    }
    
    /// 强制清理所有资源
    func forceCleanupAllResources() {
        statusLock.lock()
        let currentState = state
        statusLock.unlock()
        
        // 如果当前正在清理，跳过
        if currentState == .cleaning {
            return
        }
        
        statusLock.lock()
        state = .cleaning
        statusLock.unlock()
        
        print("【资源监视】开始强制清理所有资源")
        
        // 清理音频资源
        cleanupAudioResources()
        
        // 更新最后清理时间
        lastCleanupTime = Date()
        
        statusLock.lock()
        state = .monitoring
        statusLock.unlock()
        
        print("【资源监视】强制清理所有资源完成")
    }
    
    /// 清理音频资源
    private func cleanupAudioResources() {
        print("【资源监视】清理音频资源")
        
        // 立即禁用自动重播
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 停止API语音播放
        ApiVoicePlaybackManager.shared.forceCleanup {
            print("【资源监视】API语音资源清理完成")
        }
        
        // 取消API请求
        SiliconFlowTTSService.shared.cancelCurrentRequest()
        
        print("【资源监视】音频资源清理指令已发出")
    }
    
    /// 获取资源状态
    /// - Parameter type: 资源类型
    /// - Returns: 是否活跃
    func isResourceActive(_ type: ResourceType) -> Bool {
        statusLock.lock()
        defer { statusLock.unlock() }
        
        return resourceStatus[type] ?? false
    }
    
    /// 资源是否全部空闲
    /// - Returns: 是否全部空闲
    func areAllResourcesIdle() -> Bool {
        statusLock.lock()
        defer { statusLock.unlock() }
        
        for (_, active) in resourceStatus {
            if active {
                return false
            }
        }
        
        return true
    }
    
    /// 析构函数
    deinit {
        monitorTimer?.invalidate()
        monitorTimer = nil
        
        cancellables.removeAll()
        
        NotificationCenter.default.removeObserver(self)
    }
} 