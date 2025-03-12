import Foundation
import AVFoundation
import MediaPlayer

/// 音频播放器服务
class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    // 单例模式
    static let shared = AudioPlayerService()
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 播放状态
    private(set) var isPlaying = false
    
    // 播放完成回调
    private var completionHandler: (() -> Void)?
    
    // 后台任务标识符
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            // 设置为播放类别，并添加mixWithOthers和duckOthers选项
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("音频会话设置成功")
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 设置远程控制中心
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放/暂停命令
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.resume()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    /// 开始后台任务
    private func beginBackgroundTask() {
        // 如果已经有一个后台任务在运行，先结束它
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // 开始一个新的后台任务
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let self = self else { return }
            // 如果后台任务即将结束，确保我们清理资源
            if self.backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }
        }
    }
    
    /// 结束后台任务
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    /// 播放音频文件
    /// - Parameters:
    ///   - url: 音频文件URL
    ///   - completion: 播放完成回调
    func play(url: URL, completion: (() -> Void)? = nil) {
        // 停止当前播放
        stop()
        
        // 确保音频会话处于活跃状态
        do {
            if !AVAudioSession.sharedInstance().isOtherAudioPlaying {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            }
        } catch {
            print("激活音频会话失败: \(error.localizedDescription)")
        }
        
        // 开始后台任务
        beginBackgroundTask()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            completionHandler = completion
            
            // 设置锁屏/控制中心信息
            setupNowPlaying(title: "忆刻", artist: "正在播放")
            
            print("开始播放音频: \(url.path)")
        } catch {
            print("播放音频失败: \(error.localizedDescription)")
            completion?()
            endBackgroundTask()
        }
    }
    
    /// 设置正在播放信息
    private func setupNowPlaying(title: String, artist: String) {
        // 获取MPNowPlayingInfoCenter单例
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        // 创建包含音乐信息的字典
        var nowPlayingInfo = [String: Any]()
        
        // 设置标题和艺术家
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        
        // 设置播放时间和持续时间
        if let player = audioPlayer {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        }
        
        // 更新信息中心
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    /// 暂停播放
    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
        isPlaying = false
        
        // 更新锁屏/控制中心信息
        if let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            var updatedInfo = nowPlayingInfo
            updatedInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
        }
        
        print("暂停播放音频")
    }
    
    /// 继续播放
    func resume() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        
        // 确保音频会话处于活跃状态
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("激活音频会话失败: \(error.localizedDescription)")
        }
        
        // 开始后台任务
        beginBackgroundTask()
        
        player.play()
        isPlaying = true
        
        // 更新锁屏/控制中心信息
        if let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            var updatedInfo = nowPlayingInfo
            updatedInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
        }
        
        print("继续播放音频")
    }
    
    /// 停止播放
    func stop() {
        guard let player = audioPlayer else { return }
        player.stop()
        audioPlayer = nil
        isPlaying = false
        // 停止播放时不调用完成回调，因为这不是自然播放完成
        completionHandler = nil
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 结束后台任务
        endBackgroundTask()
        
        print("停止播放音频")
    }
    
    /// 设置音量
    /// - Parameter volume: 音量值 (0.0 - 1.0)
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
    
    /// 获取当前播放时间
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// 获取音频总时长
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    /// 设置播放时间
    /// - Parameter time: 目标时间
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = max(0, min(time, duration))
        
        // 更新锁屏/控制中心信息
        if let player = audioPlayer, let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            var updatedInfo = nowPlayingInfo
            updatedInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("音频播放完成")
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 结束后台任务
        endBackgroundTask()
        
        completionHandler?()
        completionHandler = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        print("音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 结束后台任务
        endBackgroundTask()
        
        completionHandler?()
        completionHandler = nil
    }
} 