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
    
    /// 强制清理所有资源
    /// - Parameter completion: 完成回调
    func forceCleanup(completion: (() -> Void)?) {
        print("【方案三】LocalVoicePlaybackManager.forceCleanup 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【方案三】forceCleanup在非主线程调用，转到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.forceCleanup(completion: completion)
            }
            return
        }
        
        // 1. 立即停止播放
        print("【方案三】停止播放")
        stop()
        
        // 2. 移除所有订阅
        print("【方案三】移除所有订阅")
        cancellables.removeAll()
        
        // 3. 重置所有状态
        print("【方案三】重置所有状态")
        isPlaying = false
        progress = 0
        
        // 4. 延迟执行回调，但仍在主线程上
        if let completion = completion {
            print("【方案三】安排回调执行 - 延迟0.3秒")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("【方案三】执行回调 - 时间: \(Date())")
                completion()
                print("【方案三】回调执行完成")
            }
        } else {
            print("【方案三】没有提供回调")
        }
        
        print("【方案三】forceCleanup方法执行完毕 - 时间: \(Date())")
    }
} 