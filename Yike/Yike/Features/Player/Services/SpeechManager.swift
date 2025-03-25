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
    
    // 将合成器设为 internal 访问级别，以便 LocalVoicePlaybackManager 可以访问
    let synthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private(set) var sentences: [String] = []
    private var currentIndex: Int = 0
    
    // 暴露当前句子索引和总句子数，用于锁屏控制中心显示
    var currentSentenceIndex: Int? {
        return sentences.isEmpty ? nil : currentIndex
    }
    
    var sentencesCount: Int? {
        return sentences.isEmpty ? nil : sentences.count
    }
    
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
        // 移除音频会话设置,现在由 LocalVoicePlaybackManager 统一管理
        print("【调试】SpeechManager: 音频会话由 LocalVoicePlaybackManager 统一管理")
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
    
    /// 跳转到指定句子
    /// - Parameter index: 句子索引
    func jumpToSentence(at index: Int) {
        guard index >= 0 && index < sentences.count else {
            print("跳转到句子失败：索引超出范围 \(index)")
            return
        }
        
        print("跳转到句子：\(index)")
        
        let wasPlaying = isPlaying
        invalidateTimer()
        synthesizer.stopSpeaking(at: .immediate)
        
        currentIndex = index
        prepareUtterance(for: sentences[currentIndex])
        
        // 如果之前在播放，则继续播放
        if wasPlaying {
            // 延迟一小段时间再开始播放，确保状态更新完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.play()
            }
        }
    }
    
    /// 为指定文本准备语音合成
    /// - Parameter text: 要合成的文本
    private func prepareUtterance(for text: String) {
        // print("准备播放文本: \(text)") // 注释掉一般状态日志
        utterance = AVSpeechUtterance(string: text)
        utterance?.rate = playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
        
        let settings = SettingsManager.shared.settings
        let voiceType = settings.playbackVoiceType
        
        utterance?.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        switch voiceType {
        case .standard:
            utterance?.pitchMultiplier = 1.0
            utterance?.volume = 0.9
            utterance?.rate = utterance!.rate * 1.0
        case .gentle:
            utterance?.pitchMultiplier = 1.2
            utterance?.volume = 0.85
            utterance?.rate = utterance!.rate * 1.05
        case .deep:
            utterance?.pitchMultiplier = 0.75
            utterance?.volume = 1.0
            utterance?.rate = utterance!.rate * 0.9
        }
        
        currentUtterance = utterance
        progress = Double(currentIndex) / Double(max(1, sentences.count))
        updateTimes()
    }
    
    /// 开始播放
    func play() {
        guard let utterance = utterance else {
            print("播放失败: utterance 为空")
            return
        }
        
        print("SpeechManager: 准备开始播放，当前状态 - 播放中: \(isPlaying), 合成器播放中: \(synthesizer.isSpeaking)")
        setupAudioSession()
        
        if isPlaying {
            print("SpeechManager: 已经在播放中，忽略重复的播放请求")
            return
        }
        
        if synthesizer.isSpeaking {
            print("合成器正在播放，停止当前播放")
            synthesizer.stopSpeaking(at: .immediate)
            
            let currentText = utterance.speechString
            let currentIdx = currentIndex
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                
                if self.currentIndex != currentIdx || self.utterance?.speechString != currentText {
                    // print("延迟期间状态已改变，跳过重新播放") // 注释掉一般状态日志
                    return
                }
                
                guard let currentUtterance = self.utterance else { 
                    // print("延迟期间utterance已被清除，跳过重新播放") // 注释掉一般状态日志
                    return 
                }
                
                let newUtterance = AVSpeechUtterance(string: currentUtterance.speechString)
                newUtterance.rate = self.playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
                newUtterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
                
                let settings = SettingsManager.shared.settings
                let voiceType = settings.playbackVoiceType
                
                switch voiceType {
                case .standard:
                    newUtterance.pitchMultiplier = 1.0
                    newUtterance.volume = 0.9
                case .gentle:
                    newUtterance.pitchMultiplier = 1.2
                    newUtterance.volume = 0.85
                    newUtterance.rate = newUtterance.rate * 1.05
                case .deep:
                    newUtterance.pitchMultiplier = 0.75
                    newUtterance.volume = 1.0
                    newUtterance.rate = newUtterance.rate * 0.9
                }
                
                self.utterance = newUtterance
                self.currentUtterance = newUtterance
                
                self.isPlaying = true
                self.synthesizer.speak(newUtterance)
            }
            return
        }
        
        isPlaying = true
        print("SpeechManager: 开始播放新的内容")
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
        guard utterance === currentUtterance else {
            // print("忽略非当前 utterance 的完成回调") // 注释掉一般状态日志
            return
        }
        
        // print("播放完成一句，当前索引: \(currentIndex)") // 注释掉一般状态日志
        
        self.utterance = nil
        self.currentUtterance = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isLastSentence = self.currentIndex >= self.sentences.count - 1
            
            if isLastSentence && SettingsManager.shared.settings.enablePlaybackInterval {
                self.isPlaying = false
                self.startIntervalTimer()
                // print("播放完最后一句，启动间隔计时器") // 注释掉一般状态日志
            } else if isLastSentence {
                self.currentIndex = 0
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.isPlaying = false
                self.play()
                // print("播放完最后一句，直接重新开始") // 注释掉一般状态日志
            } else {
                self.currentIndex += 1
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.isPlaying = false
                self.play()
                // print("播放完一句，继续播放下一句") // 注释掉一般状态日志
            }
        }
    }
    
    // 添加进度更新的回调方法
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        guard utterance === currentUtterance else { return }
        let progress = Float(characterRange.location + characterRange.length) / Float(utterance.speechString.count)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let sentenceWeight = 1.0 / Double(max(1, self.sentences.count))
            let completedProgress = Double(self.currentIndex) * sentenceWeight
            let currentSentenceProgress = Double(progress) * sentenceWeight
            let totalProgress = completedProgress + currentSentenceProgress
            self.progress = totalProgress
            self.updateTimes()
        }
    }
} 