import SwiftUI
import AVFoundation
import Combine
import MediaPlayer

/// LocalVoicePlaybackManager 负责管理本地语音播放
///
/// 主要功能：
/// - 封装SpeechManager的调用
/// - 处理本地语音播放的状态管理
/// - 提供简化的播放控制接口
class LocalVoicePlaybackManager: ObservableObject {
    static let shared = LocalVoicePlaybackManager()
    
    private let speechManager = SpeechManager.shared
    
    @Published var isPlaying: Bool = false {
        didSet {
            updateNowPlayingInfo()
        }
    }
    @Published var progress: Double = 0.0 {
        didSet {
            updateNowPlayingInfo()
        }
    }
    @Published var currentTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
        
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
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            // 设置为播放类别，并添加适当的选项
            try AVAudioSession.sharedInstance().setCategory(
                .playback,  // 使用playback类别以支持后台播放
                mode: .default,
                options: [.allowBluetooth, .duckOthers] // 允许蓝牙输出并降低其他音频音量
            )
            
            // 设置音频会话为活跃状态
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            // 注册音频中断通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            print("本地语音播放器音频会话设置成功")
        } catch {
            print("本地语音播放器设置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理音频会话中断
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 中断开始时暂停播放
            if isPlaying {
                pause()
            }
        case .ended:
            // 中断结束时，如果有选项并且可以恢复，则恢复播放
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }
    
    /// 设置远程控制中心
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 清除之前可能存在的处理程序
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        
        // 播放命令
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        // 暂停命令
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        // 切换播放/暂停命令
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
    }
    
    /// 更新正在播放的信息
    private func updateNowPlayingInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()
        
        // 设置标题
        nowPlayingInfo[MPMediaItemPropertyTitle] = "语音朗读"
        nowPlayingInfo[MPMediaItemPropertyArtist] = isPlaying ? "正在播放" : "已暂停"
        
        // 设置播放状态
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // 添加专辑封面图片
        if let image = UIImage(named: "Image") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // 更新进度信息
        let timeComponents = totalTime.split(separator: ":")
        if timeComponents.count == 2,
           let minutes = Int(timeComponents[0]),
           let seconds = Int(timeComponents[1]) {
            let totalSeconds = TimeInterval(minutes * 60 + seconds)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalSeconds
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = totalSeconds * progress
        }
        
        // 更新信息中心
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
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
        // 清除锁屏控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    /// 播放上一句
    func previous() {
        speechManager.previous()
        updateNowPlayingInfo()
    }
    
    /// 播放下一句
    func next() {
        speechManager.next()
        updateNowPlayingInfo()
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        speechManager.setSpeed(speed)
        updateNowPlayingInfo()
    }
    
    /// 重置播放状态
    func reset() {
        speechManager.reset()
        // 清除锁屏控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
        updateNowPlayingInfo()
    }
    
    /// 强制清理所有资源和状态
    /// 用于确保在关键时刻（如弹窗显示前和确认按钮点击时）所有播放相关资源被彻底清理
    func forceCleanup(completion: (() -> Void)? = nil) {
        print("【调试】LocalVoicePlaybackManager.forceCleanup 被调用 - 时间: \(Date())")
        
        // 添加线程安全的完成标志
        class AtomicFlag {
            private let queue = DispatchQueue(label: "com.yike.atomicFlag")
            private var _value: Bool = false
            
            var value: Bool {
                get { queue.sync { _value } }
                set { queue.sync { _value = newValue } }
            }
        }
        
        let callbackExecuted = AtomicFlag()
        
        // 设置超时保护，确保回调一定会被执行
        let timeoutSeconds = 1.0
        let timeoutWorkItem = DispatchWorkItem {
            if !callbackExecuted.value {
                callbackExecuted.value = true
                print("【调试】LocalVoicePlaybackManager.forceCleanup 超时触发回调 - 时间: \(Date())")
                completion?()
            }
        }
        
        // 安排超时处理
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWorkItem)
        
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
        
        // 清除锁屏控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 短延迟后尝试执行正常回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // 如果已经超时或对象已被释放，不执行回调
            guard let _ = self, !callbackExecuted.value else { return }
            
            // 取消超时工作项
            timeoutWorkItem.cancel()
            
            // 设置回调已执行标志
            callbackExecuted.value = true
            
            print("【调试】LocalVoicePlaybackManager.forceCleanup 正常完成并执行回调 - 时间: \(Date())")
            completion?()
        }
        
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