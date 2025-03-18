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
        
        isLoading = true
        error = nil
        
        print("【积分日志】开始播放API语音，当前积分: \(dataManager.points)")
        
        // 检查是否已缓存
        let isCached = SiliconFlowTTSService.shared.isCached(text: text, voice: voice, speed: speed)
        print("【积分日志】是否已缓存: \(isCached)")
        
        // 如果未缓存，检查积分是否足够
        if !isCached && dataManager.points < 5 {
            isLoading = false
            error = "积分不足，无法使用在线语音。点击此处前往积分中心充值。"
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
        
        // 禁用自动重播
        shouldAutoReplay = false
        print("【调试】ApiVoicePlaybackManager.stop: 禁用自动重播 shouldAutoReplay=false")
        
        // 先取消间隔计时器，确保没有新的播放循环开始
        cancelIntervalTimer()
        print("【调试】ApiVoicePlaybackManager.stop: 已取消间隔计时器")
        
        // 停止音频播放
        print("【调试】ApiVoicePlaybackManager.stop: 即将调用audioPlayerService.stop()")
        audioPlayerService.stop()
        print("【调试】ApiVoicePlaybackManager.stop: 已调用audioPlayerService.stop()")
        
        // 重置所有状态
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0.0
        print("【调试】ApiVoicePlaybackManager.stop: 已重置所有状态")
        
        // 延迟一小段时间确保所有异步操作都被取消
        DispatchQueue.main.async {
            print("【调试】ApiVoicePlaybackManager.stop: 异步再次取消计时器")
            self.cancelIntervalTimer() // 再次确保计时器被取消
        }
        
        print("【调试】ApiVoicePlaybackManager.stop: 完成")
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
                play(text: text, voice: voice, speed: speed)
            }
        }
    }
    
    /// 取消间隔计时器
    private func cancelIntervalTimer() {
        if intervalTimer != nil {
            print("【调试】ApiVoicePlaybackManager.cancelIntervalTimer: 取消API音频间隔计时器")
            intervalTimer?.cancel()
            intervalTimer = nil
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