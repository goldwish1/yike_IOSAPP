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
    
    private var intervalTimer: DispatchWorkItem? = nil
    private var cancellables = Set<AnyCancellable>()
    
    private let audioPlayerService = AudioPlayerService.shared
    private let dataManager = DataManager.shared
    private let settingsManager = SettingsManager.shared
    
    private var sentences: [String] = []
    private var currentSentenceIndex: Int = 0
    
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
        // 取消之前的间隔计时器
        cancelIntervalTimer()
        
        // 如果是新的文本或者是重新开始播放，则分割句子
        if sentences.isEmpty || text != sentences.joined() {
            sentences = splitIntoSentences(text)
            currentSentenceIndex = 0
        }
        
        // 如果没有句子或者已经播放完所有句子，则重置
        if sentences.isEmpty || currentSentenceIndex >= sentences.count {
            sentences = splitIntoSentences(text)
            currentSentenceIndex = 0
        }
        
        // 如果仍然没有句子，则返回
        if sentences.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        
        // 检查积分是否足够
        if dataManager.points < 5 {
            isLoading = false
            error = "积分不足，无法使用在线语音。当前积分: \(dataManager.points)"
            return
        }
        
        // 获取当前句子
        let currentSentence = sentences[currentSentenceIndex]
        
        // 调用API生成语音
        SiliconFlowTTSService.shared.generateSpeech(
            text: currentSentence,
            voice: voice,
            speed: speed
        ) { [weak self] audioURL, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = "加载失败: \(error.localizedDescription)"
                    return
                }
                
                guard let audioURL = audioURL else {
                    self.error = "加载失败: 未知错误"
                    return
                }
                
                // 播放音频
                self.audioPlayerService.play(url: audioURL) {
                    // 在主线程上更新UI状态
                    DispatchQueue.main.async {
                        // 更新播放状态
                        self.isPlaying = false
                        
                        // 移动到下一个句子
                        self.currentSentenceIndex += 1
                        
                        // 如果已经播放完所有句子
                        if self.currentSentenceIndex >= self.sentences.count {
                            // 重置句子索引
                            self.currentSentenceIndex = 0
                            
                            // 调用完成回调
                            completion?()
                        }
                        
                        // 检查是否启用了播放间隔
                        if self.settingsManager.settings.enablePlaybackInterval {
                            // 获取间隔时间
                            let intervalSeconds = self.settingsManager.settings.playbackInterval
                            print("API音频播放完成，启动间隔计时器: \(intervalSeconds)秒")
                            
                            // 创建一个新的计时器任务
                            let workItem = DispatchWorkItem { [weak self] in
                                guard let self = self else { return }
                                // 确保我们仍在当前视图中
                                if !self.isPlaying {
                                    self.play(text: text, voice: voice, speed: speed)
                                }
                            }
                            
                            // 保存计时器任务的引用，以便稍后可以取消它
                            self.intervalTimer = workItem
                            
                            // 安排计时器任务在指定的间隔时间后执行
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(intervalSeconds), execute: workItem)
                        } else {
                            // 如果未启用播放间隔，则直接播放下一句
                            print("API音频播放完成，未启用间隔，直接播放下一句")
                            self.play(text: text, voice: voice, speed: speed)
                        }
                    }
                }
                
                self.isPlaying = true
                
                // 扣除积分（仅在首次生成时扣除，缓存的不扣除）
                if !SiliconFlowTTSService.shared.isCached(text: currentSentence, voice: voice, speed: speed) {
                    _ = self.dataManager.deductPoints(5, reason: "使用在线语音")
                }
            }
        }
    }
    
    /// 将文本分割成句子
    /// - Parameter text: 要分割的文本
    /// - Returns: 句子数组
    private func splitIntoSentences(_ text: String) -> [String] {
        // 使用常见的句子分隔符分割文本
        let separators = ["。", "！", "？", ".", "!", "?", "\n"]
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            
            // 如果当前字符是分隔符，则添加当前句子到数组中
            if separators.contains(String(char)) {
                if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sentences.append(currentSentence)
                    currentSentence = ""
                }
            }
        }
        
        // 添加最后一个句子（如果有）
        if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(currentSentence)
        }
        
        return sentences
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
        audioPlayerService.stop()
        isPlaying = false
        // 取消间隔计时器
        cancelIntervalTimer()
        // 重置句子索引
        currentSentenceIndex = 0
    }
    
    /// 切换播放/暂停状态
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - voice: 语音类型
    ///   - speed: 播放速度
    func togglePlayPause(text: String, voice: String, speed: Float) {
        if isLoading {
            return
        }
        
        if isPlaying {
            pause()
        } else {
            if audioPlayerService.duration > 0 {
                resume()
            } else {
                play(text: text, voice: voice, speed: speed)
            }
        }
    }
    
    /// 取消间隔计时器
    private func cancelIntervalTimer() {
        if intervalTimer != nil {
            print("取消API音频间隔计时器")
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