import Foundation
import AVFoundation
import MediaPlayer

/// 音频播放器服务
/// 
/// 主要功能说明：
/// 1. 基础播放控制
///    - play(url:completion:) - 播放音频文件
///    - pause() - 暂停播放
///    - resume() - 继续播放
///    - stop() - 停止播放
/// 
/// 2. 播放控制
///    - setVolume(_:) - 设置音量大小
///    - seek(to:) - 跳转到指定时间点
///    - currentTime - 获取当前播放时间
///    - duration - 获取音频总时长
/// 
/// 3. 后台播放支持
///    - beginBackgroundTask() - 开始后台播放任务
///    - endBackgroundTask() - 结束后台播放任务
/// 
/// 4. 系统集成
///    - setupAudioSession() - 设置音频会话
///    - setupRemoteCommandCenter() - 设置锁屏控制中心
///    - setupNowPlaying(title:artist:) - 设置锁屏显示信息
/// 
/// 5. 错误处理
///    - audioPlayerDidFinishPlaying(_:successfully:) - 处理播放完成
///    - audioPlayerDecodeErrorDidOccur(_:error:) - 处理播放错误
///
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
        
        // 注册结束后台任务的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
        
        // 停止播放并清理资源
        stop()
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
            
            print("音频会话设置成功")
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
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
                resume()
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
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // 播放命令
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.resume()
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
                self.resume()
            }
            return .success
        }
        
        // 启用播放位置滑块
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            self.seek(to: event.positionTime)
            return .success
        }
        
        print("远程控制中心设置成功")
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
            setupNowPlaying(title: "记得住", artist: "正在播放")
            
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
        
        // 添加专辑封面图片，使用我们准备的600×600高分辨率图片
        if let image = UIImage(named: "Image") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            print("成功设置锁屏封面图片，尺寸：\(image.size.width)×\(image.size.height)")
        } else {
            print("警告：无法加载锁屏封面图片'Image'")
            // 尝试使用应用图标作为备选
            if let iconName = Bundle.main.infoDictionary?["CFBundleIconName"] as? String,
               let image = UIImage(named: iconName) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                print("使用应用图标作为锁屏封面备选图片")
            }
        }
        
        // 设置播放时间和持续时间
        if let player = audioPlayer {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        }
        
        // 更新信息中心
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        // 开始定期更新播放信息
        startUpdatingNowPlayingInfo()
    }
    
    // 播放信息更新计时器
    private var nowPlayingInfoUpdateTimer: Timer?
    
    /// 开始定期更新播放信息
    private func startUpdatingNowPlayingInfo() {
        // 先停止现有计时器
        stopUpdatingNowPlayingInfo()
        
        // 创建新计时器，每秒更新一次
        nowPlayingInfoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    /// 停止更新播放信息
    private func stopUpdatingNowPlayingInfo() {
        nowPlayingInfoUpdateTimer?.invalidate()
        nowPlayingInfoUpdateTimer = nil
    }
    
    /// 更新正在播放的信息
    private func updateNowPlayingInfo() {
        guard isPlaying, let player = audioPlayer, let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }
        
        var updatedInfo = nowPlayingInfo
        updatedInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        updatedInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
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
        print("【调试】AudioPlayerService.stop 被调用")
        guard let player = audioPlayer else { 
            print("【调试】AudioPlayerService.stop: audioPlayer为nil，无需停止")
            return 
        }
        player.stop()
        print("【调试】AudioPlayerService.stop: 已调用player.stop()")
        audioPlayer = nil
        isPlaying = false
        // 停止播放时不调用完成回调，因为这不是自然播放完成
        let hadCompletionHandler = completionHandler != nil
        print("【调试】AudioPlayerService.stop: 是否有完成回调: \(hadCompletionHandler)")
        completionHandler = nil
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 停止更新播放信息
        stopUpdatingNowPlayingInfo()
        
        // 结束后台任务
        endBackgroundTask()
        
        print("【调试】AudioPlayerService.stop: 停止播放音频完成")
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
    
    /// 音频播放完成时的回调方法
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 开始处理")
        // 检查播放器是否还是当前的播放器
        if player !== audioPlayer {
            print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 播放器已更换，可能新的播放已经开始")
            return
        }
        
        // 更新播放状态
        isPlaying = false
        print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 音频播放完成，设置isPlaying=false")
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 停止更新播放信息
        stopUpdatingNowPlayingInfo()
        
        // 结束后台任务
        endBackgroundTask()
        
        // 保存回调的引用以便清空后也能调用
        let completion = completionHandler
        
        // 清空回调引用
        completionHandler = nil
        
        // 执行完成回调
        if let completion = completion {
            print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 执行完成回调")
            completion()
        } else {
            print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 没有完成回调")
        }
        
        print("【调试】AudioPlayerService.audioPlayerDidFinishPlaying: 处理完成")
    }
    
    /// 音频解码错误的回调方法
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("【调试】AudioPlayerService.audioPlayerDecodeErrorDidOccur: 开始处理")
        // 更新播放状态
        isPlaying = false
        print("【调试】音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        
        // 清除锁屏/控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 停止更新播放信息
        stopUpdatingNowPlayingInfo()
        
        // 结束后台任务
        endBackgroundTask()
        
        // 保存回调的引用以便清空后也能调用
        let completion = completionHandler
        
        // 清空回调引用
        completionHandler = nil
        
        // 执行完成回调
        if let completion = completion {
            print("【调试】AudioPlayerService.audioPlayerDecodeErrorDidOccur: 执行完成回调")
            completion()
        } else {
            print("【调试】AudioPlayerService.audioPlayerDecodeErrorDidOccur: 没有完成回调")
        }
        
        print("【调试】AudioPlayerService.audioPlayerDecodeErrorDidOccur: 处理完成")
    }
    
    /// 应用程序即将终止
    @objc private func applicationWillTerminate() {
        stop()
    }
} 