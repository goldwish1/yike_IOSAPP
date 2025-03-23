import SwiftUI
import AVFoundation
import Combine

/// LocalVoicePlaybackManager 负责管理本地语音播放
///
/// 主要功能：
/// - 封装SpeechManager的调用
/// - 处理本地语音播放的状态管理
/// - 提供简化的播放控制接口
class LocalVoicePlaybackManager: ObservableObject {
    static let shared = LocalVoicePlaybackManager()
    
    private let speechManager = SpeechManager.shared
    
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 监听SpeechManager的状态变化
        speechManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        speechManager.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &cancellables)
        
        speechManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
        
        speechManager.$totalTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.totalTime = time
            }
            .store(in: &cancellables)
    }
    
    /// 准备播放文本
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - speed: 播放速度
    ///   - intervalSeconds: 句子间隔时间
    func prepare(text: String, speed: Float, intervalSeconds: Int) {
        speechManager.prepare(text: text, speed: speed, intervalSeconds: intervalSeconds)
    }
    
    /// 开始播放
    func play() {
        speechManager.play()
    }
    
    /// 暂停播放
    func pause() {
        speechManager.pause()
    }
    
    /// 停止播放
    func stop() {
        speechManager.stop()
    }
    
    /// 播放上一句
    func previous() {
        speechManager.previous()
    }
    
    /// 播放下一句
    func next() {
        speechManager.next()
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        speechManager.setSpeed(speed)
    }
    
    /// 重置播放状态
    func reset() {
        speechManager.reset()
    }
    
    /// 切换播放/暂停状态
    /// - Parameters:
    ///   - text: 要播放的文本（如果尚未准备）
    ///   - speed: 播放速度
    ///   - intervalSeconds: 句子间隔时间
    func togglePlayPause(text: String, speed: Float, intervalSeconds: Int) {
        if isPlaying {
            pause()
        } else {
            if progress == 0 {
                prepare(text: text, speed: speed, intervalSeconds: intervalSeconds)
            }
            play()
        }
    }
    
    /// 强制清理所有资源和状态
    /// 用于确保在关键时刻（如弹窗显示前和确认按钮点击时）所有播放相关资源被彻底清理
    func forceCleanup() {
        print("【调试】LocalVoicePlaybackManager.forceCleanup 被调用 - 时间: \(Date())")
        
        // 停止播放
        stop()
        
        // 移除所有订阅
        cancellables.removeAll()
        
        // 创建新的订阅监听SpeechManager的状态变化
        setupSubscriptions()
        
        // 强制更新所有状态
        isPlaying = false
        progress = 0.0
        currentTime = "00:00"
        totalTime = "00:00"
        
        print("【调试】LocalVoicePlaybackManager.forceCleanup 完成 - 时间: \(Date())")
    }
    
    /// 重新设置订阅关系
    private func setupSubscriptions() {
        speechManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        speechManager.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &cancellables)
        
        speechManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
        
        speechManager.$totalTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.totalTime = time
            }
            .store(in: &cancellables)
    }
} 