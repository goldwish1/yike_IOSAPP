import SwiftUI
import AVFoundation

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
        
        // 配置音频会话
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
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
    
    private func prepareUtterance(for text: String) {
        print("准备播放文本: \(text)")
        utterance = AVSpeechUtterance(string: text)
        utterance?.rate = playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
        
        // 获取用户设置的声音性别和音色
        let settings = SettingsManager.shared.settings
        let gender = settings.playbackVoiceGender
        let style = settings.playbackVoiceStyle
        
        print("应用语音设置: 性别=\(gender.rawValue), 音色=\(style.rawValue)")
        
        // 选择默认中文语音
        utterance?.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        // 根据性别和音色调整音调
        var pitchMultiplier: Float = 1.0
        var volume: Float = 1.0
        
        switch (gender, style) {
        case (.male, .standard):
            pitchMultiplier = 0.9  // 标准男声
            volume = 0.9
        case (.male, .deep):
            pitchMultiplier = 0.8  // 浑厚男声
            volume = 1.0
        case (.male, .gentle):
            pitchMultiplier = 0.95  // 温柔男声
            volume = 0.85
        case (.female, .standard):
            pitchMultiplier = 1.0  // 标准女声
            volume = 0.9
        case (.female, .deep):
            pitchMultiplier = 0.9  // 浑厚女声
            volume = 0.95
        case (.female, .gentle):
            pitchMultiplier = 1.15  // 温柔女声
            volume = 0.85
        }
        
        utterance?.pitchMultiplier = pitchMultiplier
        utterance?.volume = volume
        print("设置音调倍数: \(pitchMultiplier), 音量: \(volume)")
        
        // 保存当前 utterance 的引用
        currentUtterance = utterance
        
        // 更新进度
        progress = Double(currentIndex) / Double(max(1, sentences.count))
        updateTimes()
        print("当前进度: \(progress), 当前索引: \(currentIndex)")
    }
    
    func play() {
        guard let utterance = utterance else {
            print("播放失败: utterance 为空")
            return
        }
        
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
    
    func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
        invalidateTimer()
        isPlaying = false
    }
    
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
    
    private func updateTimes() {
        // 估算每个字0.3秒
        let averageTimePerChar: Double = 0.3 / Double(playbackSpeed)
        let totalLength = sentences.joined().count
        
        let totalSeconds = Int(Double(totalLength) * averageTimePerChar)
        let currentSeconds = Int(progress * Double(totalSeconds))
        
        totalTime = formatTime(totalSeconds)
        currentTime = formatTime(currentSeconds)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func startIntervalTimer() {
        invalidateTimer()
        intervalTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalSeconds), repeats: false) { [weak self] _ in
            self?.play()
        }
    }
    
    private func invalidateTimer() {
        intervalTimer?.invalidate()
        intervalTimer = nil
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
            
            if SettingsManager.shared.settings.enablePlaybackInterval {
                self.isPlaying = false
                self.startIntervalTimer()
                print("启动间隔计时器")
            } else {
                print("准备播放下一句")
                if self.currentIndex < self.sentences.count - 1 {
                    self.currentIndex += 1
                    self.prepareUtterance(for: self.sentences[self.currentIndex])
                    self.isPlaying = false
                    self.play()
                } else {
                    self.currentIndex = 0
                    self.prepareUtterance(for: self.sentences[self.currentIndex])
                    self.isPlaying = false
                    self.play()
                }
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

struct PlayerView: View {
    @ObservedObject private var speechManager = SpeechManager.shared
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedSpeed: Float = 1.0
    @State private var waveHeight: CGFloat = 10
    @State private var isWaving = false
    @State private var showCompletionAlert = false
    
    var memoryItem: MemoryItem
    
    var body: some View {
        VStack(spacing: 24) {
            // 顶部标题和内容
            VStack(spacing: 16) {
                Text(memoryItem.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                ScrollView {
                    Text(memoryItem.content)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                }
                .frame(maxHeight: 200)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 波形图(简化实现)
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.blue)
                        .frame(width: 3, height: isWaving ? waveHeight + CGFloat.random(in: 0...20) : 5)
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever()
                                .delay(Double(index) * 0.05),
                            value: isWaving
                        )
                }
            }
            .frame(height: 50)
            .padding()
            .onChange(of: speechManager.isPlaying) { oldValue, newValue in
                isWaving = newValue
            }
            
            // 播放进度
            VStack(spacing: 8) {
                ProgressView(value: speechManager.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                HStack {
                    Text(speechManager.currentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(speechManager.totalTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // 控制按钮
            HStack(spacing: 32) {
                Button(action: {
                    speechManager.previous()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    if speechManager.isPlaying {
                        speechManager.pause()
                    } else {
                        if speechManager.progress == 0 {
                            speechManager.prepare(text: memoryItem.content, speed: selectedSpeed)
                        }
                        speechManager.play()
                    }
                }) {
                    Image(systemName: speechManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    speechManager.next()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            // 播放速度选择
            HStack {
                ForEach([0.5, 0.75, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button(action: {
                        selectedSpeed = Float(speed)
                        speechManager.setSpeed(Float(speed))
                    }) {
                        Text("\(String(format: "%.1f", speed))x")
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedSpeed == Float(speed) ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedSpeed == Float(speed) ? .white : .primary)
                            .cornerRadius(15)
                    }
                }
            }
        }
        .padding(.bottom, 24)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                updateMemoryProgress()
                showCompletionAlert = true
            }) {
                Text("完成学习")
                    .foregroundColor(.blue)
            }
        )
        .onAppear {
            if speechManager.progress == 0 {
                speechManager.prepare(text: memoryItem.content, speed: selectedSpeed)
            }
        }
        .onDisappear {
            speechManager.stop()  // 确保在视图消失时停止播放
        }
        .alert(isPresented: $showCompletionAlert) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func updateMemoryProgress() {
        // 更新学习进度和复习阶段
        var updatedItem = memoryItem
        
        if updatedItem.isNew {
            // 首次学习，设置为第一阶段
            updatedItem.reviewStage = 1
            updatedItem.progress = 0.2
            
            // 设置下一次复习时间（明天）
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                updatedItem.nextReviewDate = tomorrow
            }
        } else {
            // 已在复习中，更新进度
            let progressIncrement = 0.2
            updatedItem.progress = min(1.0, updatedItem.progress + progressIncrement)
            updatedItem.reviewStage = min(5, updatedItem.reviewStage + 1)
            
            // 设置下一次复习时间
            if updatedItem.reviewStage < 5, let interval = SettingsManager.shared.settings.reviewStrategy.intervals.dropFirst(updatedItem.reviewStage - 1).first {
                if let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) {
                    updatedItem.nextReviewDate = nextDate
                }
            } else {
                // 已完成所有复习阶段
                updatedItem.nextReviewDate = nil
            }
        }
        
        updatedItem.lastReviewDate = Date()
        dataManager.updateMemoryItem(updatedItem)
    }
} 