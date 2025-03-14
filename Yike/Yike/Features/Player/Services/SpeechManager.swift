import SwiftUI
import AVFoundation

/// SpeechManager 负责管理本地语音合成和播放
/// 
/// 主要功能：
/// - 文本转语音合成
/// - 播放控制（播放、暂停、停止）
/// - 句子导航（上一句、下一句）
/// - 播放速度调整
/// - 播放进度跟踪
/// - 间隔播放控制
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private var sentences: [String] = []
    private var currentIndex: Int = 0
    
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    
    private var playbackSpeed: Float = 1.0
    private var intervalTimer: Timer?
    private var intervalSeconds: Int = 5
    
    // 添加一个属性来追踪当前正在播放的 utterance
    private var currentUtterance: AVSpeechUtterance?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // 不在这里设置音频会话，避免与AudioPlayerService冲突
        // 在需要播放时再设置
    }
    
    /// 设置音频会话
    private func setupAudioSession() {
        do {
            // 检查当前会话状态，避免与AudioPlayerService冲突
            let currentCategory = AVAudioSession.sharedInstance().category
            if currentCategory != .playback {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
                try AVAudioSession.sharedInstance().setActive(true)
                print("SpeechManager: 设置音频会话成功")
            }
        } catch {
            print("SpeechManager: 设置音频会话失败: \(error)")
        }
    }
    
    /// 准备播放文本
    /// - Parameters:
    ///   - text: 要播放的文本内容
    ///   - speed: 播放速度
    ///   - intervalSeconds: 句子间隔时间（秒）
    func prepare(text: String, speed: Float = 1.0, intervalSeconds: Int = 5) {
        stop()
        self.playbackSpeed = speed
        self.intervalSeconds = intervalSeconds
        
        // 简单的分句处理
        sentences = text.components(separatedBy: CharacterSet(charactersIn: "。.!?！？\n"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        updateTimes()
        
        if !sentences.isEmpty {
            currentIndex = 0
            prepareUtterance(for: sentences[currentIndex])
        }
    }
    
    /// 为指定文本准备语音合成
    /// - Parameter text: 要合成的文本
    private func prepareUtterance(for text: String) {
        print("准备播放文本: \(text)")
        utterance = AVSpeechUtterance(string: text)
        utterance?.rate = playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
        
        // 获取用户设置的音色类型
        let settings = SettingsManager.shared.settings
        let voiceType = settings.playbackVoiceType
        
        print("应用音色设置: \(voiceType.rawValue)")
        
        // 选择默认中文语音
        utterance?.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        // 根据音色类型设置参数
        switch voiceType {
        case .standard:
            // 标准音色 - 保持默认设置
            utterance?.pitchMultiplier = 1.0
            utterance?.volume = 0.9
            utterance?.rate = utterance!.rate * 1.0
        case .gentle:
            // 轻柔音色 - 较高音调，较轻音量，稍快语速
            utterance?.pitchMultiplier = 1.2
            utterance?.volume = 0.85
            utterance?.rate = utterance!.rate * 1.05
        case .deep:
            // 浑厚音色 - 低音调，大音量，慢语速
            utterance?.pitchMultiplier = 0.75
            utterance?.volume = 1.0
            utterance?.rate = utterance!.rate * 0.9
        }
        
        print("设置音调倍数: \(utterance?.pitchMultiplier ?? 0), 音量: \(utterance?.volume ?? 0), 语速: \(utterance?.rate ?? 0)")
        
        // 保存当前 utterance 的引用
        currentUtterance = utterance
        
        // 更新进度
        progress = Double(currentIndex) / Double(max(1, sentences.count))
        updateTimes()
        print("当前进度: \(progress), 当前索引: \(currentIndex)")
    }
    
    /// 开始播放
    func play() {
        guard let utterance = utterance else {
            print("播放失败: utterance 为空")
            return
        }
        
        // 在播放前设置音频会话
        setupAudioSession()
        
        // 如果已经在播放，先不要打断
        if isPlaying {
            print("已经在播放中，忽略重复的播放请求")
            return
        }
        
        // 检查合成器是否正在播放任何内容
        if synthesizer.isSpeaking {
            print("合成器正在播放，停止当前播放")
            synthesizer.stopSpeaking(at: .immediate)
            
            // 停止后等待一小段时间再开始新的播放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, let currentUtterance = self.utterance else { return }
                
                // 创建一个新的 utterance 实例，而不是重用旧的
                let newUtterance = AVSpeechUtterance(string: currentUtterance.speechString)
                newUtterance.rate = self.playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
                newUtterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
                
                // 更新引用
                self.utterance = newUtterance
                self.currentUtterance = newUtterance
                
                print("重新开始播放: isPlaying=\(self.isPlaying), currentIndex=\(self.currentIndex)")
                self.isPlaying = true
                self.synthesizer.speak(newUtterance)
            }
            return
        }
        
        print("开始播放: isPlaying=\(isPlaying), currentIndex=\(currentIndex)")
        
        // 设置状态为播放中，防止重复调用
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    /// 暂停播放
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
        invalidateTimer()
        isPlaying = false
    }
    
    /// 停止播放
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        invalidateTimer()
        isPlaying = false
        progress = 0.0
        currentIndex = 0
        // 清理当前的 utterance
        utterance = nil
        currentUtterance = nil
        // 清空句子数组
        sentences = []
        updateTimes()
    }
    
    /// 播放上一句
    func previous() {
        invalidateTimer()
        if currentIndex > 0 {
            currentIndex -= 1
            prepareUtterance(for: sentences[currentIndex])
            if isPlaying {
                play()
            }
        }
    }
    
    /// 播放下一句
    func next() {
        print("执行 next(), 当前索引: \(currentIndex), 总句数: \(sentences.count)")
        invalidateTimer()
        if currentIndex < sentences.count - 1 {
            currentIndex += 1
            prepareUtterance(for: sentences[currentIndex])
            print("准备下一句")
        } else {
            print("到达最后一句，重新开始")
            currentIndex = 0
            prepareUtterance(for: sentences[currentIndex])
        }
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        self.playbackSpeed = speed
        if let text = utterance?.speechString {
            // 如果正在播放，需要重新设置语速
            let wasPlaying = isPlaying
            invalidateTimer()
            
            // 先更新播放状态
            isPlaying = false
            
            // 停止当前播放
            synthesizer.stopSpeaking(at: .immediate)
            
            // 准备新的 utterance
            prepareUtterance(for: text)
            
            // 如果之前在播放，则重新开始播放
            if wasPlaying {
                // 延迟一小段时间再开始播放，确保状态更新完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.play()
                }
            }
            
            print("速度已更改为: \(speed)x, 之前状态: \(wasPlaying ? "播放中" : "已暂停")")
        }
    }
    
    /// 更新播放时间
    private func updateTimes() {
        // 估算每个字0.3秒
        let averageTimePerChar: Double = 0.3 / Double(playbackSpeed)
        let totalLength = sentences.joined().count
        
        let totalSeconds = Int(Double(totalLength) * averageTimePerChar)
        let currentSeconds = Int(progress * Double(totalSeconds))
        
        totalTime = formatTime(totalSeconds)
        currentTime = formatTime(currentSeconds)
    }
    
    /// 格式化时间为 MM:SS 格式
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化后的时间字符串
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// 启动间隔计时器
    private func startIntervalTimer() {
        invalidateTimer()
        intervalTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalSeconds), repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // 间隔结束后，重新从第一句开始播放
            self.currentIndex = 0
            self.prepareUtterance(for: self.sentences[self.currentIndex])
            self.play()
            print("间隔结束，重新开始播放")
        }
    }
    
    /// 取消间隔计时器
    private func invalidateTimer() {
        intervalTimer?.invalidate()
        intervalTimer = nil
    }
    
    /// 重置播放状态
    func reset() {
        // 重置播放状态，但不停止当前播放
        invalidateTimer()
        isPlaying = false
        progress = 0.0
        currentIndex = 0
        // 清理当前的 utterance
        utterance = nil
        currentUtterance = nil
        // 清空句子数组
        sentences = []
        updateTimes()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // 确保是当前的 utterance
        guard utterance === currentUtterance else {
            print("忽略非当前 utterance 的完成回调")
            return
        }
        
        print("播放完成一句，当前索引: \(currentIndex)")
        
        // 清理当前 utterance
        self.utterance = nil
        self.currentUtterance = nil
        
        // 确保在主线程更新状态
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否是最后一句
            let isLastSentence = self.currentIndex >= self.sentences.count - 1
            
            if isLastSentence && SettingsManager.shared.settings.enablePlaybackInterval {
                // 如果是最后一句且启用了间隔，启动间隔计时器
                self.isPlaying = false
                self.startIntervalTimer()
                print("播放完最后一句，启动间隔计时器")
            } else if isLastSentence {
                // 如果是最后一句但没有启用间隔，直接重新开始（循环播放）
                self.currentIndex = 0
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.isPlaying = false
                self.play()
                print("播放完最后一句，直接重新开始")
            } else {
                // 如果不是最后一句，继续播放下一句
                self.currentIndex += 1
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.isPlaying = false
                self.play()
                print("播放完一句，继续播放下一句")
            }
        }
    }
    
    // 添加进度更新的回调方法
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 确保是当前的 utterance
        guard utterance === currentUtterance else { return }
        
        // 计算当前句子的播放进度
        let progress = Float(characterRange.location + characterRange.length) / Float(utterance.speechString.count)
        
        // 更新总体进度
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 计算当前句子在总体中的权重
            let sentenceWeight = 1.0 / Double(max(1, self.sentences.count))
            
            // 更新总体进度 = 已完成句子的进度 + 当前句子的进度
            let completedProgress = Double(self.currentIndex) * sentenceWeight
            let currentSentenceProgress = Double(progress) * sentenceWeight
            let totalProgress = completedProgress + currentSentenceProgress
            
            self.progress = totalProgress
            self.updateTimes()
            
            print("进度更新: 字符位置=\(characterRange.location)/\(utterance.speechString.count), 句子进度=\(progress), 总进度=\(totalProgress)")
        }
    }
} 