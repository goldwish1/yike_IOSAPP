import SwiftUI
import AVFoundation
import Combine

/// ApiVoicePlaybackManager 负责管理API语音播放
///
/// 主要功能：
/// - 处理API语音的请求和播放
/// - 管理播放状态和进度
/// - 处理积分检查和错误处理
/// - 管理播放间隔和循环播放
class ApiVoicePlaybackManager: ObservableObject {
    static let shared = ApiVoicePlaybackManager()
    
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var progress: Double = 0.0
    
    // 标记是否应该自动重新播放
    private var shouldAutoReplay: Bool = true
    private var intervalTimer: DispatchWorkItem? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private let audioPlayerService = AudioPlayerService.shared
    private let dataManager = DataManager.shared
    private let settingsManager = SettingsManager.shared
    
    private init() {
        // 监听AudioPlayerService的状态变化
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.audioPlayerService.duration > 0 {
                    self.progress = self.audioPlayerService.currentTime / self.audioPlayerService.duration
                }
            }
            .store(in: &cancellables)
    }
    
    /// 禁用自动重播功能
    /// 用于在用户明确希望停止播放的场景（如点击"完成学习"按钮时）立即禁用
    func disableAutoReplay() {
        print("【最终方案】ApiVoicePlaybackManager.disableAutoReplay 被调用 - 时间: \(Date()), 线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【最终方案】disableAutoReplay 在非主线程调用，立即切换到主线程")
            DispatchQueue.main.sync { [weak self] in
                self?.disableAutoReplay()
            }
            return
        }
        
        // 使用同步操作，最可靠的方式执行：
        
        // 1. 立即禁用自动重播标志
        let oldValue = shouldAutoReplay
        shouldAutoReplay = false
        print("【最终方案】shouldAutoReplay: \(oldValue) -> false")
        
        // 2. 立即取消所有计时器
        cancelIntervalTimer()
        
        // 3. 立即取消所有API请求
        print("【最终方案】取消所有API请求")
        SiliconFlowTTSService.shared.cancelCurrentRequest()
        
        // 4. 立即停止播放器
        print("【最终方案】停止音频播放")
        audioPlayerService.stop()
        
        // 5. 重置所有状态
        let wasPlaying = isPlaying
        let wasLoading = isLoading
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0
        print("【最终方案】重置状态: isPlaying: \(wasPlaying) -> false, isLoading: \(wasLoading) -> false")
        
        print("【最终方案】disableAutoReplay 完成 - 时间: \(Date())")
    }
    
    /// 播放API语音
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - voice: 语音类型
    ///   - speed: 播放速度
    ///   - completion: 完成回调
    func play(text: String, voice: String, speed: Float, completion: (() -> Void)? = nil) {
        print("【调试】ApiVoicePlaybackManager.play 被调用: text长度=\(text.count), voice=\(voice), speed=\(speed)")
        
        // 取消之前的间隔计时器
        cancelIntervalTimer()
        
        // 启用自动重播
        shouldAutoReplay = true
        print("【调试】ApiVoicePlaybackManager.play: 设置 shouldAutoReplay=true")
        
        // 设置加载状态为true，确保UI显示加载中
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        print("【积分日志】开始播放API语音，当前积分: \(dataManager.points)")
        
        // 检查是否已缓存
        let isCached = SiliconFlowTTSService.shared.isCached(text: text, voice: voice, speed: speed)
        print("【积分日志】是否已缓存: \(isCached)")
        
        // 如果未缓存，检查积分是否足够
        if !isCached && dataManager.points < 5 {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = "积分不足，无法使用在线语音。点击此处前往积分中心充值。"
            }
            print("【积分日志】积分不足，无法使用在线语音")
            return
        }
        
        // 调用API生成语音
        print("【调试】ApiVoicePlaybackManager.play: 开始调用TTS服务生成语音")
        SiliconFlowTTSService.shared.generateSpeech(
            text: text,
            voice: voice,
            speed: speed
        ) { [weak self] audioURL, error in
            guard let self = self else {
                print("【调试】ApiVoicePlaybackManager.play回调: self已被释放")
                return
            }
            
            DispatchQueue.main.async {
                print("【调试】ApiVoicePlaybackManager.play回调: 主线程回调开始处理")
                self.isLoading = false
                
                if let error = error {
                    self.error = "加载失败: \(error.localizedDescription)"
                    print("【积分日志】API请求失败，不扣除积分: \(error.localizedDescription)")
                    // 调用完成回调
                    completion?()
                    print("【调试】ApiVoicePlaybackManager.play回调: 出错，已调用完成回调")
                    return
                }
                
                guard let audioURL = audioURL else {
                    self.error = "加载失败: 未知错误"
                    print("【积分日志】API请求返回空URL，不扣除积分")
                    // 调用完成回调
                    completion?()
                    print("【调试】ApiVoicePlaybackManager.play回调: URL为空，已调用完成回调")
                    return
                }
                
                // 检查是否在回调过程中应该自动重播已被禁用
                if !self.shouldAutoReplay {
                    print("【调试】ApiVoicePlaybackManager.play回调: 在回调中发现自动重播已被禁用，不继续播放")
                    // 调用完成回调
                    completion?()
                    return
                }
                
                // 播放音频
                print("【调试】ApiVoicePlaybackManager.play回调: 开始播放音频 URL=\(audioURL)")
                self.audioPlayerService.play(url: audioURL) {
                    // 在主线程上更新UI状态
                    DispatchQueue.main.async {
                        print("【调试】ApiVoicePlaybackManager.play音频完成回调: 开始处理")
                        
                        // 更新播放状态
                        self.isPlaying = false
                        print("【调试】ApiVoicePlaybackManager.play音频完成回调: 设置isPlaying=false")
                        
                        // 调用完成回调
                        if let completion = completion {
                            print("【调试】ApiVoicePlaybackManager.play音频完成回调: 调用外部完成回调")
                            completion()
                        }
                        
                        // 先检查是否应该自动重播
                        if !self.shouldAutoReplay {
                            print("【调试】自动重播已禁用，不再继续播放")
                            return
                        }
                        
                        // 检查是否启用了播放间隔
                        if self.settingsManager.settings.enablePlaybackInterval {
                            // 获取间隔时间
                            let intervalSeconds = self.settingsManager.settings.playbackInterval
                            print("【调试】API音频播放完成，启动间隔计时器: \(intervalSeconds)秒")
                            
                            // 创建一个新的计时器任务
                            let workItem = DispatchWorkItem { [weak self] in
                                guard let self = self else {
                                    print("【调试】间隔计时器回调: self已被释放")
                                    return
                                }
                                
                                // 再次检查是否应该自动重播
                                if self.shouldAutoReplay {
                                    print("【调试】间隔结束，开始下一次播放")
                                    self.play(text: text, voice: voice, speed: speed)
                                } else {
                                    print("【调试】间隔结束，但自动重播已禁用，不再继续播放")
                                }
                            }
                            
                            // 保存计时器任务的引用，以便稍后可以取消它
                            self.intervalTimer = workItem
                            
                            // 安排计时器任务在指定的间隔时间后执行
                            print("【调试】安排\(intervalSeconds)秒后执行的间隔计时器")
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(intervalSeconds), execute: workItem)
                        } else {
                            // 如果未启用播放间隔，则直接循环播放
                            print("【调试】API音频播放完成，未启用间隔，直接循环播放")
                            self.play(text: text, voice: voice, speed: speed)
                        }
                    }
                }
                
                self.isPlaying = true
                print("【调试】ApiVoicePlaybackManager.play回调: 设置isPlaying=true")
                
                // 扣除积分（仅在首次生成时扣除，缓存的不扣除）
                if !isCached {
                    print("【积分日志】未使用缓存，需要扣除积分")
                    let success = self.dataManager.deductPoints(5, reason: "使用在线语音")
                    print("【积分日志】积分扣除结果: \(success ? "成功" : "失败")，扣除后积分: \(self.dataManager.points)")
                } else {
                    print("【积分日志】使用缓存，不扣除积分")
                }
            }
        }
    }
    
    /// 暂停播放
    func pause() {
        audioPlayerService.pause()
        isPlaying = false
        // 取消间隔计时器
        cancelIntervalTimer()
    }
    
    /// 恢复播放
    func resume() {
        audioPlayerService.resume()
        isPlaying = true
    }
    
    /// 停止播放
    func stop() {
        print("【调试】ApiVoicePlaybackManager.stop 被调用")
        print("【调试详细】ApiVoicePlaybackManager.stop: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 线程=\(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 禁用自动重播
        let previousAutoReplay = shouldAutoReplay
        shouldAutoReplay = false
        print("【调试详细】ApiVoicePlaybackManager.stop: 禁用自动重播 shouldAutoReplay: \(previousAutoReplay) -> false")
        
        // 先取消间隔计时器，确保没有新的播放循环开始
        let hadTimer = intervalTimer != nil
        cancelIntervalTimer()
        print("【调试详细】ApiVoicePlaybackManager.stop: 已取消间隔计时器 (hadTimer: \(hadTimer))")
        
        // 取消正在进行的语音生成请求
        print("【调试详细】ApiVoicePlaybackManager.stop: 即将取消正在进行的API请求 - 时间: \(Date())")
        SiliconFlowTTSService.shared.cancelCurrentRequest()
        print("【调试详细】ApiVoicePlaybackManager.stop: 已取消正在进行的API请求 - 时间: \(Date())")
        
        // 停止音频播放
        print("【调试详细】ApiVoicePlaybackManager.stop: 即将调用audioPlayerService.stop() - 时间: \(Date())")
        audioPlayerService.stop()
        print("【调试详细】ApiVoicePlaybackManager.stop: 已调用audioPlayerService.stop() - 时间: \(Date())")
        
        // 在主线程上安全地重置所有状态
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("【调试详细】ApiVoicePlaybackManager.stop: 主线程同步更新状态 - 时间: \(Date())")
            
            let oldPlayingState = self.isPlaying
            let oldLoadingState = self.isLoading
            self.isPlaying = false
            self.isLoading = false
            self.error = nil
            self.progress = 0.0
            print("【调试详细】ApiVoicePlaybackManager.stop: 已重置所有状态 isPlaying: \(oldPlayingState) -> false, isLoading: \(oldLoadingState) -> false")
        }
        
        // 延迟一小段时间确保所有异步操作都被取消
        print("【调试详细】ApiVoicePlaybackManager.stop: 准备异步再次取消计时器 - 时间: \(Date())")
        DispatchQueue.main.async {
            print("【调试详细】ApiVoicePlaybackManager.stop: 异步操作开始 - 线程=\(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
            print("【调试详细】ApiVoicePlaybackManager.stop: 异步操作中当前状态 - isPlaying=\(self.isPlaying), isLoading=\(self.isLoading)")
            self.cancelIntervalTimer() // 再次确保计时器被取消
            print("【调试详细】ApiVoicePlaybackManager.stop: 异步操作完成 - 时间: \(Date())")
        }
        
        print("【调试详细】ApiVoicePlaybackManager.stop: 方法执行完毕 - 时间: \(Date())")
    }
    
    /// 强制清理所有资源和状态
    /// 用于确保在关键时刻（如弹窗显示前和确认按钮点击时）所有播放相关资源被彻底清理
    func forceCleanup(completion: (() -> Void)? = nil) {
        print("【调试】ApiVoicePlaybackManager.forceCleanup 被调用 - 时间: \(Date())")
        
        // 立即设置重要标志阻止任何新的播放
        shouldAutoReplay = false
        
        // 使用原子变量跟踪清理状态，防止多次回调
        let cleanupCompleted = Atomic(false)
        
        // 设置超时保护机制，确保回调一定会被执行
        let timeoutSeconds = 1.0 // 快速超时
        let timeoutWorkItem = DispatchWorkItem {
            if !cleanupCompleted.value {
                cleanupCompleted.value = true
                print("【调试】ApiVoicePlaybackManager.forceCleanup 超时触发回调 - 时间: \(Date())")
                completion?()
            }
        }
        
        // 安排超时处理
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWorkItem)
        
        // 取消间隔计时器
        cancelIntervalTimer()
        
        // 取消API请求
        SiliconFlowTTSService.shared.cancelCurrentRequest()
        
        // 停止音频播放
        audioPlayerService.stop()
        
        // 移除所有订阅
        cancellables.removeAll()
        
        // 创建新的订阅监听AudioPlayerService的状态变化
        setupSubscriptions()
        
        // 强制更新所有状态
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0.0
        
        // 短延迟后尝试执行正常回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            // 如果已经超时或对象已被释放，不执行回调
            guard let _ = self, !cleanupCompleted.value else { return }
            
            // 取消超时工作项
            timeoutWorkItem.cancel()
            
            // 设置清理完成标志
            cleanupCompleted.value = true
            
            print("【调试】ApiVoicePlaybackManager.forceCleanup 正常完成并执行回调 - 时间: \(Date())")
            completion?()
        }
        
        print("【调试】ApiVoicePlaybackManager.forceCleanup 完成 - 时间: \(Date())")
    }
    
    /// 原子变量辅助类，用于线程安全地跟踪状态
    private class Atomic<T> {
        private let queue = DispatchQueue(label: "com.yike.atomic")
        private var _value: T
        
        init(_ value: T) {
            self._value = value
        }
        
        var value: T {
            get {
                return queue.sync { _value }
            }
            set {
                queue.sync { _value = newValue }
            }
        }
    }
    
    /// 重新设置订阅关系
    private func setupSubscriptions() {
        // 重新创建Timer订阅
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.audioPlayerService.duration > 0 {
                    self.progress = self.audioPlayerService.currentTime / self.audioPlayerService.duration
                }
            }
            .store(in: &cancellables)
    }
    
    /// 切换播放/暂停状态
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - voice: 语音类型
    ///   - speed: 播放速度
    func togglePlayPause(text: String, voice: String, speed: Float) {
        if isLoading {
            print("【调试】ApiVoicePlaybackManager.togglePlayPause: 正在加载中，忽略操作")
            return
        }
        
        if isPlaying {
            print("【调试】ApiVoicePlaybackManager.togglePlayPause: 当前正在播放，执行暂停")
            pause()
        } else {
            // 启用自动重播
            shouldAutoReplay = true
            print("【调试】ApiVoicePlaybackManager.togglePlayPause: 启用自动重播 shouldAutoReplay=true")
            
            if audioPlayerService.duration > 0 {
                print("【调试】ApiVoicePlaybackManager.togglePlayPause: 有现有音频，执行恢复播放")
                resume()
            } else {
                print("【调试】ApiVoicePlaybackManager.togglePlayPause: 没有现有音频，执行新的播放")
                // 设置加载状态
                DispatchQueue.main.async {
                    self.isLoading = true
                    print("【调试】ApiVoicePlaybackManager.togglePlayPause: 设置isLoading=true")
                }
                play(text: text, voice: voice, speed: speed)
            }
        }
    }
    
    /// 取消间隔计时器
    private func cancelIntervalTimer() {
        if intervalTimer != nil {
            print("【调试详细】ApiVoicePlaybackManager.cancelIntervalTimer: 取消计时器开始 - 时间: \(Date())")
            intervalTimer?.cancel()
            intervalTimer = nil
            print("【调试详细】ApiVoicePlaybackManager.cancelIntervalTimer: 取消计时器完成 - 时间: \(Date())")
        } else {
            print("【调试详细】ApiVoicePlaybackManager.cancelIntervalTimer: 计时器已为nil，无需取消 - 时间: \(Date())")
        }
    }
    
    /// 获取当前播放时间
    var currentTime: TimeInterval {
        return audioPlayerService.currentTime
    }
    
    /// 获取总播放时间
    var duration: TimeInterval {
        return audioPlayerService.duration
    }
    
    /// 格式化时间为 MM:SS 格式
    /// - Parameter time: 时间（秒）
    /// - Returns: 格式化后的时间字符串
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 