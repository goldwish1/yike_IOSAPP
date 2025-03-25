import SwiftUI
import AVFoundation
import Combine
import MediaPlayer
import UIKit

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
            // 确保在播放状态变化时更新锁屏信息
            DispatchQueue.main.async {
                self.updateNowPlayingInfo(forceUpdate: true)
                self.checkRemoteCommandCenter()
            }
        }
    }
    @Published var progress: Double = 0.0 {
        didSet {
            // 只在进度有较大变化时更新锁屏信息，避免频繁更新
            if abs(oldValue - progress) > 0.01 {
                updateNowPlayingInfo()
            }
        }
    }
    @Published var currentTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    
    private var cancellables = Set<AnyCancellable>()
    private var statusMonitorTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // 记录最后一次更新NowPlayingInfo的时间
    private var lastInfoUpdateTime: Date = Date()
    
    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
        setupApplicationStateObservers()
        
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
                // 时间更新时可能需要更新锁屏信息
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)
        
        speechManager.$totalTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.totalTime = time
                // 总时间更新时更新锁屏信息
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)
        
        // 启动播放状态监控定时器
        startPlaybackStatusMonitor()
    }
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,  // 使用 spokenAudio 模式更适合语音播放
                options: [.allowBluetooth, .duckOthers, .allowAirPlay, .mixWithOthers]
            )
            
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            // 添加音频会话中断监听
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            // 添加音频会话路由变化监听
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            
            print("本地语音播放器音频会话设置成功 - 增强版")
        } catch {
            print("本地语音播放器设置音频会话失败: \(error.localizedDescription)") // 保留错误日志
        }
    }
    
    /// 设置应用状态变化观察者
    private func setupApplicationStateObservers() {
        // 添加应用状态变化监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        print("应用状态变化观察者设置成功")
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
            print("音频会话中断开始")
            if isPlaying {
                pause()
            }
        case .ended:
            // 中断结束时，如果有选项并且可以恢复，则恢复播放
            print("音频会话中断结束")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }
    
    /// 处理音频路由变化
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("音频路由变化: \(reason.rawValue)")
        
        // 如果是旧输出不可用（如拔出耳机），暂停播放
        if reason == .oldDeviceUnavailable {
            if isPlaying {
                pause()
            }
        }
        
        // 无论什么原因导致路由变化，都更新远程控制中心
        updateNowPlayingInfo(forceUpdate: true)
        checkRemoteCommandCenter()
    }
    
    /// 处理应用进入后台
    @objc private func handleAppDidEnterBackground() {
        print("应用进入后台 - 开始后台任务并刷新远程控制中心")
        
        // 开始后台任务以确保有足够的时间更新NowPlayingInfo和设置远程控制
        startBackgroundTask()
        
        // 强制刷新控制中心
        updateNowPlayingInfo(forceUpdate: true)
        checkRemoteCommandCenter()
        
        // 确保在后台也能接收远程控制命令
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("后台激活音频会话失败: \(error.localizedDescription)")
        }
        
        // 如果正在播放，启动高频更新定时器
        if isPlaying {
            startHighFrequencyUpdateTimer()
        }
    }
    
    /// 处理应用即将进入前台
    @objc private func handleAppWillEnterForeground() {
        print("应用即将进入前台 - 更新播放状态")
        updateNowPlayingInfo(forceUpdate: true)
        
        // 结束后台任务
        endBackgroundTask()
        
        // 停止高频更新定时器
        stopHighFrequencyUpdateTimer()
    }
    
    /// 处理应用激活
    @objc private func handleAppDidBecomeActive() {
        print("应用已激活 - 确保音频会话和控制中心状态同步")
        setupAudioSession()
        checkRemoteCommandCenter()
        updateNowPlayingInfo(forceUpdate: true)
    }
    
    /// 处理应用即将进入非活动状态
    @objc private func handleAppWillResignActive() {
        print("应用即将进入非活动状态 - 确保控制中心状态同步")
        updateNowPlayingInfo(forceUpdate: true)
        checkRemoteCommandCenter()
    }
    
    /// 开始后台任务
    private func startBackgroundTask() {
        // 结束可能存在的之前的后台任务
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // 开始新的后台任务
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "YikeAudioControlUpdate") { [weak self] in
            // 后台任务到期时的清理代码
            self?.endBackgroundTask()
        }
        
        print("开始后台任务: \(backgroundTask)")
    }
    
    /// 结束后台任务
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("结束后台任务")
        }
    }
    
    /// 启动高频更新定时器
    private func startHighFrequencyUpdateTimer() {
        // 停止可能存在的之前的定时器
        stopHighFrequencyUpdateTimer()
        
        // 在后台时，每0.5秒更新一次锁屏信息
        statusMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo(forceUpdate: true)
        }
        RunLoop.current.add(statusMonitorTimer!, forMode: .common)
    }
    
    /// 停止高频更新定时器
    private func stopHighFrequencyUpdateTimer() {
        statusMonitorTimer?.invalidate()
        statusMonitorTimer = nil
    }
    
    /// 检查并重新设置远程控制中心
    private func checkRemoteCommandCenter() {
        // 在各种状态变化时确保远程控制中心设置正确
        setupRemoteCommandCenter()
    }
    
    /// 设置远程控制中心
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 移除所有现有的目标，确保不会重复添加
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // 启用需要的命令
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        // 添加播放命令
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { 
                print("远程播放命令失败：self 已释放")
                return .commandFailed 
            }
            print("远程播放命令接收: \(event)")
            
            // 检查音频会话
            self.checkAndActivateAudioSession()
            
            if !self.isPlaying {
                print("远程播放命令执行：开始播放")
                self.play()
                return .success
            }
            print("远程播放命令被忽略：已经在播放中")
            return .commandFailed
        }
        
        // 添加暂停命令
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { 
                print("远程暂停命令失败：self 已释放")
                return .commandFailed 
            }
            print("远程暂停命令接收: \(event)")
            
            if self.isPlaying {
                print("远程暂停命令执行：暂停播放")
                self.pause()
                return .success
            }
            print("远程暂停命令被忽略：当前未在播放")
            return .commandFailed
        }
        
        // 添加切换播放/暂停命令
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            guard let self = self else { 
                print("远程切换播放状态命令失败：self 已释放")
                return .commandFailed 
            }
            print("远程切换播放状态命令接收: \(event)")
            
            // 检查音频会话
            self.checkAndActivateAudioSession()
            
            if self.isPlaying {
                print("远程切换播放状态命令执行：从播放切换到暂停")
                self.pause()
            } else {
                print("远程切换播放状态命令执行：从暂停切换到播放")
                self.play()
            }
            return .success
        }
        
        // 添加下一首命令
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else {
                print("远程下一首命令失败：self 已释放")
                return .commandFailed
            }
            print("远程下一首命令执行：播放下一句 \(event)")
            self.next()
            return .success
        }
        
        // 添加上一首命令
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else {
                print("远程上一首命令失败：self 已释放")
                return .commandFailed
            }
            print("远程上一首命令执行：播放上一句 \(event)")
            self.previous()
            return .success
        }
        
        // 添加跳转播放位置命令
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                print("远程跳转位置命令失败：无效参数")
                return .commandFailed
            }
            
            print("远程跳转位置命令接收: \(positionEvent.positionTime)")
            
            // 获取总时长
            let timeComponents = self.totalTime.split(separator: ":")
            if timeComponents.count == 2,
               let minutes = Int(timeComponents[0]),
               let seconds = Int(timeComponents[1]) {
                let totalSeconds = Double(minutes * 60 + seconds)
                if totalSeconds > 0 {
                    // 计算目标进度
                    let targetProgress = positionEvent.positionTime / totalSeconds
                    
                    // 根据进度定位到对应的句子
                    let targetIndex = Int(targetProgress * Double(self.speechManager.sentences.count))
                    if targetIndex >= 0 && targetIndex < self.speechManager.sentences.count {
                        print("跳转到句子索引: \(targetIndex)")
                        self.speechManager.jumpToSentence(at: targetIndex)
                        return .success
                    }
                }
            }
            
            return .commandFailed
        }
        
        print("远程控制中心设置成功 - 强化版")
    }
    
    /// 检查并激活音频会话
    private func checkAndActivateAudioSession() {
        if !AVAudioSession.sharedInstance().isOtherAudioPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                print("音频会话已激活")
            } catch {
                print("激活音频会话失败: \(error.localizedDescription)")
            }
        } else {
            print("其他音频正在播放，不强制激活音频会话")
        }
    }
    
    /// 更新正在播放的信息
    private func updateNowPlayingInfo(forceUpdate: Bool = false) {
        // 限制更新频率，除非强制更新
        let now = Date()
        if !forceUpdate && now.timeIntervalSince(lastInfoUpdateTime) < 0.5 {
            return
        }
        lastInfoUpdateTime = now
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()
        
        // 添加更多媒体信息
        nowPlayingInfo[MPMediaItemPropertyTitle] = "忆刻语音朗读"
        nowPlayingInfo[MPMediaItemPropertyArtist] = isPlaying ? "正在播放" : "已暂停"
        
        // 更明确的播放状态
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        
        // 设置应用图标或默认图像作为封面图片
        if let appIcon = UIImage(named: "AppIcon") ?? 
                         UIImage(named: "Icon") ??
                         getAppIcon() {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in return appIcon }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        } else if let image = UIImage(named: "Image") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // 确保设置播放位置信息
        let timeComponents = totalTime.split(separator: ":")
        if timeComponents.count == 2,
           let minutes = Int(timeComponents[0]),
           let seconds = Int(timeComponents[1]) {
            let totalSeconds = TimeInterval(minutes * 60 + seconds)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalSeconds
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = totalSeconds * progress
        }
        
        // 设置当前语音在所有句子中的索引
        if let currentIndex = speechManager.currentSentenceIndex,
           let sentencesCount = speechManager.sentencesCount {
            nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = NSNumber(value: currentIndex + 1)
            nowPlayingInfo[MPNowPlayingInfoPropertyChapterCount] = NSNumber(value: sentencesCount)
        }
        
        // 记录打印详细的锁屏信息
        print("更新锁屏控制中心信息: 播放状态=\(isPlaying), 进度=\(progress), 时间=\(currentTime)/\(totalTime)")
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    /// 获取应用图标
    private func getAppIcon() -> UIImage? {
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
    
    /// 开始播放状态监控
    private func startPlaybackStatusMonitor() {
        // 停止可能存在的之前的定时器
        statusMonitorTimer?.invalidate()
        
        // 创建新的定时器，每1秒检查一次播放状态
        statusMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 检查实际播放状态与UI状态是否一致
            let actuallyPlaying = self.speechManager.synthesizer.isSpeaking
            if self.isPlaying != actuallyPlaying {
                print("播放状态不一致：UI显示 \(self.isPlaying ? "播放中" : "已暂停")，但实际 \(actuallyPlaying ? "正在播放" : "未播放")，执行同步")
                self.isPlaying = actuallyPlaying
            }
            
            // 确保锁屏控制中心信息是最新的
            self.updateNowPlayingInfo()
            
            // 检查远程控制中心是否正确设置
            if UIApplication.shared.applicationState == .background && self.isPlaying {
                self.checkRemoteCommandCenter()
            }
        }
        
        // 确保定时器在所有运行模式下都能工作
        RunLoop.current.add(statusMonitorTimer!, forMode: .common)
    }
    
    /// 准备播放文本
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - speed: 播放速度
    ///   - intervalSeconds: 句子间隔时间
    func prepare(text: String, speed: Float, intervalSeconds: Int) {
        speechManager.prepare(text: text, speed: speed, intervalSeconds: intervalSeconds)
        updateNowPlayingInfo(forceUpdate: true)
    }
    
    /// 开始播放
    func play() {
        // 确保音频会话激活
        checkAndActivateAudioSession()
        
        speechManager.play()
        updateNowPlayingInfo(forceUpdate: true)
        
        // 如果在后台，启动高频更新
        if UIApplication.shared.applicationState == .background {
            startHighFrequencyUpdateTimer()
        }
    }
    
    /// 暂停播放
    func pause() {
        speechManager.pause()
        updateNowPlayingInfo(forceUpdate: true)
        
        // 停止高频更新
        if UIApplication.shared.applicationState == .background {
            stopHighFrequencyUpdateTimer()
        }
    }
    
    /// 停止播放
    func stop() {
        speechManager.stop()
        // 清除锁屏控制中心信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // 停止高频更新
        stopHighFrequencyUpdateTimer()
    }
    
    /// 播放上一句
    func previous() {
        speechManager.previous()
        updateNowPlayingInfo(forceUpdate: true)
    }
    
    /// 播放下一句
    func next() {
        speechManager.next()
        updateNowPlayingInfo(forceUpdate: true)
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        speechManager.setSpeed(speed)
        updateNowPlayingInfo(forceUpdate: true)
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
        
        // 停止状态监控定时器
        statusMonitorTimer?.invalidate()
        statusMonitorTimer = nil
        
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
        
        // 结束后台任务
        endBackgroundTask()
        
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