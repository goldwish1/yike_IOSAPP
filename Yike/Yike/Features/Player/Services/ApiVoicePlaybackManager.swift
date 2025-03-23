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
    
    // 状态锁机制 - 避免状态更新冲突
    private let stateLock = NSLock()
    private var internalIsPlaying: Bool = false
    private var internalIsLoading: Bool = false
    private var internalError: String? = nil
    private var internalProgress: Double = 0.0
    
    // 公开属性使用计算属性包装，确保状态一致性
    @Published private(set) var isPlaying: Bool = false {
        willSet {
            // 在setter中打印变化，帮助调试
            if newValue != isPlaying {
                print("【状态同步】ApiVoicePlaybackManager.isPlaying: \(isPlaying) -> \(newValue)")
            }
        }
    }
    
    @Published private(set) var isLoading: Bool = false {
        willSet {
            if newValue != isLoading {
                print("【状态同步】ApiVoicePlaybackManager.isLoading: \(isLoading) -> \(newValue)")
            }
        }
    }
    
    @Published private(set) var error: String? = nil
    @Published private(set) var progress: Double = 0.0
    
    // 标记是否应该自动重新播放
    private var shouldAutoReplay: Bool = true
    private var intervalTimer: DispatchWorkItem? = nil
    private var cancellables = Set<AnyCancellable>()
    
    // 标记上一次请求信息，用于防止重复请求
    private var lastRequestInfo: (text: String, voice: String, speed: Float)? = nil
    
    // 标记最近状态更新时间，用于防止短时间内重复更新
    private var lastStateUpdateTime: Date = Date.distantPast
    
    private let audioPlayerService = AudioPlayerService.shared
    private let dataManager = DataManager.shared
    private let settingsManager = SettingsManager.shared
    
    private init() {
        setupTimer()
    }
    
    // 设置timer监听器
    private func setupTimer() {
        // 监听AudioPlayerService的状态变化
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main) // 确保在主线程上接收事件
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.stateLock.lock()
                // 只在播放状态下更新进度，避免无意义的状态更新
                if self.internalIsPlaying && self.audioPlayerService.duration > 0 {
                    let newProgress = self.audioPlayerService.currentTime / self.audioPlayerService.duration
                    if abs(newProgress - self.internalProgress) > 0.01 { // 只有变化超过1%才更新
                        self.internalProgress = newProgress
                        // 已确保在主线程，可以直接更新，避免额外的异步派发
                        self.progress = newProgress
                    }
                }
                self.stateLock.unlock()
            }
            .store(in: &cancellables)
    }
    
    /// 安全更新状态 - 内部方法，确保状态一致性
    /// - Parameters:
    ///   - playing: 播放状态
    ///   - loading: 加载状态
    ///   - error: 错误信息
    ///   - progress: 播放进度
    private func safelyUpdateState(playing: Bool? = nil, loading: Bool? = nil, error: String?? = nil, progress: Double? = nil) {
        // 确保总是在主线程上更新状态
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.safelyUpdateState(playing: playing, loading: loading, error: error, progress: progress)
            }
            return
        }
        
        // 状态更新频率限制，防止短时间内重复更新
        let now = Date()
        let minimumInterval: TimeInterval = 0.05 // 最小更新间隔50ms
        
        if now.timeIntervalSince(lastStateUpdateTime) < minimumInterval {
            // 如果距离上次更新时间太近，使用延迟更新
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumInterval) { [weak self] in
                self?.safelyUpdateState(playing: playing, loading: loading, error: error, progress: progress)
            }
            return
        }
        
        lastStateUpdateTime = now
        
        stateLock.lock()
        
        var stateChanged = false
        
        if let newPlaying = playing, newPlaying != internalIsPlaying {
            internalIsPlaying = newPlaying
            stateChanged = true
        }
        
        if let newLoading = loading, newLoading != internalIsLoading {
            internalIsLoading = newLoading
            stateChanged = true
        }
        
        if let newError = error {
            internalError = newError
            stateChanged = true
        }
        
        if let newProgress = progress, newProgress != internalProgress {
            internalProgress = newProgress
            stateChanged = true
        }
        
        // 释放锁再更新UI属性，避免死锁
        stateLock.unlock()
        
        if stateChanged {
            // 已确保在主线程，可以直接更新
            if let newPlaying = playing {
                self.isPlaying = newPlaying
            }
            
            if let newLoading = loading {
                self.isLoading = newLoading
            }
            
            if error != nil {
                self.error = self.internalError
            }
            
            if let newProgress = progress {
                self.progress = newProgress
            }
        }
    }
    
    /// 禁用自动重播功能
    /// 用于在用户明确希望停止播放的场景（如点击"完成学习"按钮时）立即禁用
    func disableAutoReplay() {
        print("【终极方案】disableAutoReplay 被调用")
        
        // 立即设置标志 - 这是最关键的操作
        shouldAutoReplay = false
        
        // 直接取消计时器 - 同步操作，避免可能的新播放循环
        if let timer = intervalTimer {
            timer.cancel()
            intervalTimer = nil
        }
        
        print("【终极方案】disableAutoReplay 完成 - 已禁用自动重播")
    }
    
    /// 播放API语音
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - voice: 语音类型
    ///   - speed: 播放速度
    ///   - completion: 完成回调
    func play(text: String, voice: String, speed: Float, completion: (() -> Void)? = nil) {
        print("【调试】ApiVoicePlaybackManager.play 被调用: text长度=\(text.count), voice=\(voice), speed=\(speed)")
        
        // 检查是否是重复请求
        if let lastRequest = lastRequestInfo, 
           lastRequest.text == text && 
           lastRequest.voice == voice && 
           lastRequest.speed == speed && 
           isPlaying {
            print("【状态同步】检测到重复请求，忽略")
            completion?()
            return
        }
        
        // 记录请求信息
        lastRequestInfo = (text: text, voice: voice, speed: speed)
        
        // 取消之前的间隔计时器
        cancelIntervalTimer()
        
        // 启用自动重播
        shouldAutoReplay = true
        print("【调试】ApiVoicePlaybackManager.play: 设置 shouldAutoReplay=true")
        
        // 设置加载状态为true，确保UI显示加载中
        safelyUpdateState(loading: true, error: nil)
        
        print("【积分日志】开始播放API语音，当前积分: \(dataManager.points)")
        
        // 检查是否已缓存
        let isCached = SiliconFlowTTSService.shared.isCached(text: text, voice: voice, speed: speed)
        print("【积分日志】是否已缓存: \(isCached)")
        
        // 如果未缓存，检查积分是否足够
        if !isCached && dataManager.points < 5 {
            safelyUpdateState(loading: false, error: "积分不足，无法使用在线语音。点击此处前往积分中心充值。")
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
            // 添加线程检查日志
            print("【线程检查】generateSpeech回调执行在: \(Thread.isMainThread ? "主线程" : "后台线程")")
            
            // 确保在主线程处理回调结果
            DispatchQueue.main.async {
                guard let self = self else {
                    print("【调试】ApiVoicePlaybackManager.play回调: self已被释放")
                    return
                }
                
                if let error = error {
                    self.safelyUpdateState(loading: false, error: "加载失败: \(error.localizedDescription)")
                    print("【积分日志】API请求失败，不扣除积分: \(error.localizedDescription)")
                    // 调用完成回调
                    completion?()
                    print("【调试】ApiVoicePlaybackManager.play回调: 出错，已调用完成回调")
                    return
                }
                
                guard let audioURL = audioURL else {
                    self.safelyUpdateState(loading: false, error: "加载失败: 未知错误")
                    print("【积分日志】API请求返回空URL，不扣除积分")
                    // 调用完成回调
                    completion?()
                    print("【调试】ApiVoicePlaybackManager.play回调: URL为空，已调用完成回调")
                    return
                }
                
                // 检查是否在回调过程中应该自动重播已被禁用
                if !self.shouldAutoReplay {
                    print("【调试】ApiVoicePlaybackManager.play回调: 在回调中发现自动重播已被禁用，不继续播放")
                    self.safelyUpdateState(loading: false)
                    // 调用完成回调
                    completion?()
                    return
                }
                
                // 设置播放状态为播放中
                self.safelyUpdateState(playing: true, loading: false)
                
                // 扣除积分（仅在首次生成时扣除，缓存的不扣除）
                if !isCached {
                    print("【积分日志】未使用缓存，需要扣除积分")
                    let success = self.dataManager.deductPoints(5, reason: "使用在线语音")
                    print("【积分日志】积分扣除结果: \(success ? "成功" : "失败")，扣除后积分: \(self.dataManager.points)")
                } else {
                    print("【积分日志】使用缓存，不扣除积分")
                }
                
                // 播放音频
                print("【调试】ApiVoicePlaybackManager.play回调: 开始播放音频 URL=\(audioURL)")
                self.audioPlayerService.play(url: audioURL) {
                    // 在主线程上更新UI状态
                    print("【调试】ApiVoicePlaybackManager.play音频完成回调: 开始处理")
                    print("【线程检查】audioPlayerService.play回调执行在: \(Thread.isMainThread ? "主线程" : "后台线程")")
                    
                    // 确保在主线程处理完成回调
                    DispatchQueue.main.async {
                        // 更新播放状态
                        self.safelyUpdateState(playing: false)
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(intervalSeconds), execute: workItem)
                        } else {
                            // 如果未启用播放间隔，则直接循环播放
                            print("【调试】API音频播放完成，未启用间隔，直接循环播放")
                            self.play(text: text, voice: voice, speed: speed)
                        }
                    }
                }
            }
        }
    }
    
    /// 暂停播放
    func pause() {
        audioPlayerService.pause()
        safelyUpdateState(playing: false)
        // 取消间隔计时器
        cancelIntervalTimer()
    }
    
    /// 恢复播放
    func resume() {
        audioPlayerService.resume()
        safelyUpdateState(playing: true)
    }
    
    /// 停止播放
    /// - Parameter completion: 资源清理完成后的回调
    func stop(completion: (() -> Void)? = nil) {
        print("【终极方案】ApiVoicePlaybackManager.stop 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stop(completion: completion)
            }
            return
        }
        
        // 1. 立即禁用自动重播和更新UI状态 - 这些操作是轻量级的，能立即完成
        print("【终极方案】禁用自动重播和同步更新UI状态")
        shouldAutoReplay = false
        safelyUpdateState(playing: false, loading: false)
        
        // 2. 取消计时器 - 同步轻量级操作
        print("【终极方案】取消间隔计时器")
        cancelIntervalTimer()
        
        // 3. 创建一个信号量，防止回调竞争
        let completionFlag = NSLock()
        completionFlag.lock()
        
        // 4. 标记音频资源开始忙碌，启动监控
        AudioResourceGuardian.shared.markResourceBusy()
        
        // 5. 取消API请求和清理资源 - 可能耗时，在后台线程执行
        print("【终极方案】开始在后台线程取消请求和清理资源")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("【终极方案】ApiVoicePlaybackManager已被释放，直接调用回调")
                AudioResourceGuardian.shared.markResourceIdle()
                DispatchQueue.main.async {
                    completion?()
                    completionFlag.unlock()
                }
                return
            }
            
            // 3.1 取消正在进行的请求
            print("【终极方案】取消所有API请求")
            SiliconFlowTTSService.shared.cancelCurrentRequest()
            
            // 3.2 停止音频播放
            print("【终极方案】停止音频播放")
            self.audioPlayerService.stop {
                print("【终极方案】音频服务停止回调执行")
                
                // 标记音频资源已空闲
                AudioResourceGuardian.shared.markResourceIdle()
            }
            
            // 在主线程上调用完成回调
            DispatchQueue.main.async {
                print("【终极方案】ApiVoicePlaybackManager.stop - 调用完成回调 - 时间: \(Date())")
                completion?()
                completionFlag.unlock()
            }
        }
        
        // 设置完成保护超时
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if completionFlag.try() == false {
                // 如果2秒后锁仍然被持有，说明回调没有执行，强制解锁
                print("【终极方案】ApiVoicePlaybackManager.stop - 回调执行超时保护触发")
                completionFlag.unlock()
                
                // 标记音频资源已空闲
                AudioResourceGuardian.shared.markResourceIdle()
                
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
        
        print("【终极方案】ApiVoicePlaybackManager.stop 方法返回 - UI已更新")
    }
    
    /// 强制清理所有资源
    /// - Parameter completion: 完成回调
    func forceCleanup(completion: (() -> Void)?) {
        print("【方案三】ApiVoicePlaybackManager.forceCleanup 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【方案三】forceCleanup在非主线程调用，转到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.forceCleanup(completion: completion)
            }
            return
        }
        
        // 1. 禁用自动重播
        print("【方案三】禁用自动重播")
        shouldAutoReplay = false
        
        // 2. 取消所有计时器
        print("【方案三】取消所有计时器")
        cancelIntervalTimer()
        
        // 3. 取消所有API请求
        print("【方案三】取消所有API请求")
        SiliconFlowTTSService.shared.cancelCurrentRequest()
        
        // 4. 标记音频资源开始忙碌，启动监控
        AudioResourceGuardian.shared.markResourceBusy()
        
        // 5. 停止音频播放
        print("【方案三】停止音频播放")
        audioPlayerService.stop {
            print("【方案三】音频服务停止回调执行")
            
            // 标记音频资源已空闲
            AudioResourceGuardian.shared.markResourceIdle()
        }
        
        // 6. 移除所有订阅
        print("【方案三】移除所有订阅")
        cancellables.removeAll()
        
        // 7. 重置所有状态
        print("【方案三】重置所有状态")
        safelyUpdateState(playing: false, loading: false, error: nil, progress: 0)
        
        // 重新设置定时器监听
        setupTimer()
        
        // 8. 清除最后请求记录
        lastRequestInfo = nil
        
        // 9. 添加超时保护，确保资源最终会被释放
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            print("【方案三】forceCleanup超时保护触发")
            AudioResourceGuardian.shared.markResourceIdle()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0, execute: timeoutWorkItem)
        
        // 10. 延迟执行回调，但仍在主线程上
        if let completion = completion {
            print("【方案三】安排回调执行 - 延迟0.3秒")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("【方案三】执行回调 - 时间: \(Date())")
                completion()
                print("【方案三】回调执行完成")
                timeoutWorkItem.cancel() // 如果正常执行，取消超时
            }
        } else {
            print("【方案三】没有提供回调")
        }
        
        print("【方案三】forceCleanup方法执行完毕 - 时间: \(Date())")
    }
    
    /// 重新设置订阅关系
    private func setupSubscriptions() {
        // 重新创建Timer订阅
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main) // 确保在主线程上接收事件
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
                safelyUpdateState(loading: true)
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