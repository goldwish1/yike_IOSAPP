import Foundation
import AVFoundation

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
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 播放音频文件
    /// - Parameters:
    ///   - url: 音频文件URL
    ///   - completion: 播放完成回调
    func play(url: URL, completion: (() -> Void)? = nil) {
        // 停止当前播放
        stop()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            completionHandler = completion
            print("开始播放音频: \(url.path)")
        } catch {
            print("播放音频失败: \(error.localizedDescription)")
            completion?()
        }
    }
    
    /// 暂停播放
    func pause() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.pause()
        isPlaying = false
        print("暂停播放音频")
    }
    
    /// 继续播放
    func resume() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        isPlaying = true
        print("继续播放音频")
    }
    
    /// 停止播放
    func stop() {
        guard let player = audioPlayer else { return }
        player.stop()
        audioPlayer = nil
        isPlaying = false
        completionHandler = nil
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
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("音频播放完成")
        completionHandler?()
        completionHandler = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        print("音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        completionHandler?()
        completionHandler = nil
    }
} 