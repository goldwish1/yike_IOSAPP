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
            guard let self = self else { return }
            
            // 检查是否有更多句子需要播放
            if self.currentIndex < self.sentences.count - 1 {
                // 播放下一句
                self.currentIndex += 1
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.play()
            } else {
                // 如果是最后一句，重新开始（循环播放）
                self.currentIndex = 0
                self.prepareUtterance(for: self.sentences[self.currentIndex])
                self.play()
            }
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
                    // 如果是最后一句，重新开始（循环播放）
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
}

struct PlayerView: View {
    // 单个记忆项目（向后兼容）
    let memoryItem: MemoryItem
    
    // 记忆项目列表和当前索引（用于项目间导航）
    let memoryItems: [MemoryItem]
    @State private var currentItemIndex: Int
    let enableItemNavigation: Bool
    
    @ObservedObject private var speechManager = SpeechManager.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedSpeed: Float = 1.0
    @State private var showCompletionAlert = false
    @State private var isLoadingApiAudio = false
    @State private var apiAudioError: String? = nil
    @State private var isPlayingApiAudio = false
    @State private var navigateToEdit = false
    @State private var shouldPopToRoot = false
    @State private var apiAudioIntervalTimer: DispatchWorkItem? = nil
    @Environment(\.presentationMode) var presentationMode
    
    // 原有初始化方法（单个记忆项目，向后兼容）
    init(memoryItem: MemoryItem) {
        self.memoryItem = memoryItem
        self.memoryItems = [memoryItem]
        self._currentItemIndex = State(initialValue: 0)
        self.enableItemNavigation = false
    }
    
    // 新增初始化方法（支持项目间导航）
    init(memoryItems: [MemoryItem], initialIndex: Int) {
        guard initialIndex >= 0 && initialIndex < memoryItems.count else {
            // 防止索引越界
            self.memoryItem = memoryItems.first ?? MemoryItem(id: UUID(), title: "", content: "", progress: 0, reviewStage: 0, lastReviewDate: nil, nextReviewDate: nil)
            self.memoryItems = memoryItems
            self._currentItemIndex = State(initialValue: 0)
            self.enableItemNavigation = memoryItems.count > 1
            return
        }
        
        self.memoryItem = memoryItems[initialIndex]
        self.memoryItems = memoryItems
        self._currentItemIndex = State(initialValue: initialIndex)
        self.enableItemNavigation = memoryItems.count > 1
    }
    
    // 获取当前显示的记忆项目
    private var currentMemoryItem: MemoryItem {
        if enableItemNavigation && currentItemIndex >= 0 && currentItemIndex < memoryItems.count {
            return memoryItems[currentItemIndex]
        }
        return memoryItem
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text(currentMemoryItem.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 内容
            ScrollView {
                Text(currentMemoryItem.content)
                    .font(.body)
                    .lineSpacing(8)
                    .padding()
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 波形动画
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.blue)
                        .frame(width: 3, height: (settingsManager.settings.useApiVoice ? isPlayingApiAudio : speechManager.isPlaying) ? 10 + CGFloat.random(in: 0...20) : 5)
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever()
                                .delay(Double(index) * 0.05),
                            value: (settingsManager.settings.useApiVoice ? isPlayingApiAudio : speechManager.isPlaying)
                        )
                }
            }
            .frame(height: 50)
            .padding(.horizontal)
            
            // 进度条
            VStack(spacing: 8) {
                HStack {
                    Text(settingsManager.settings.useApiVoice ? formatTime(AudioPlayerService.shared.currentTime) : speechManager.currentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(settingsManager.settings.useApiVoice ? formatTime(AudioPlayerService.shared.duration) : speechManager.totalTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: settingsManager.settings.useApiVoice ? (AudioPlayerService.shared.duration > 0 ? AudioPlayerService.shared.currentTime / AudioPlayerService.shared.duration : 0) : speechManager.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.blue)
            }
            .padding(.horizontal)
            
            // 控制按钮
            HStack(spacing: 32) {
                if settingsManager.settings.useApiVoice {
                    // API音频播放控制
                    Button(action: {
                        if enableItemNavigation && currentItemIndex > 0 {
                            // 在线语音模式下，导航到上一个记忆项目
                            navigateToPreviousItem()
                        }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(enableItemNavigation && currentItemIndex > 0 ? .primary : .gray)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(!enableItemNavigation || currentItemIndex <= 0)
                    
                    Button(action: {
                        if isLoadingApiAudio {
                            return
                        }
                        
                        if isPlayingApiAudio {
                            AudioPlayerService.shared.pause()
                            isPlayingApiAudio = false
                            // 取消间隔计时器
                            cancelApiAudioIntervalTimer()
                        } else {
                            if AudioPlayerService.shared.duration > 0 {
                                AudioPlayerService.shared.resume()
                                isPlayingApiAudio = true
                            } else {
                                playWithApiVoice()
                            }
                        }
                    }) {
                        if isLoadingApiAudio {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 70, height: 70)
                                .background(Color.blue)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: isPlayingApiAudio ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isLoadingApiAudio)
                    .accessibilityIdentifier("playButton")
                    
                    Button(action: {
                        if enableItemNavigation && currentItemIndex < memoryItems.count - 1 {
                            // 在线语音模式下，导航到下一个记忆项目
                            navigateToNextItem()
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(enableItemNavigation && currentItemIndex < memoryItems.count - 1 ? .primary : .gray)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(!enableItemNavigation || currentItemIndex >= memoryItems.count - 1)
                } else {
                    // 本地语音播放控制
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
                    .disabled(!speechManager.isPlaying)
                    
                    Button(action: {
                        if speechManager.isPlaying {
                            speechManager.pause()
                        } else {
                            if speechManager.progress == 0 {
                                speechManager.prepare(
                                    text: currentMemoryItem.content, 
                                    speed: selectedSpeed,
                                    intervalSeconds: settingsManager.settings.playbackInterval
                                )
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
                    .disabled(!speechManager.isPlaying)
                }
            }
            
            if let error = apiAudioError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            // 播放速度选择
            HStack {
                ForEach([0.5, 0.75, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button(action: {
                        selectedSpeed = Float(speed)
                        if !settingsManager.settings.useApiVoice {
                            speechManager.setSpeed(Float(speed))
                        } else if isPlayingApiAudio {
                            // 如果正在使用API音频，需要重新加载
                            AudioPlayerService.shared.stop()
                            isPlayingApiAudio = false
                            playWithApiVoice()
                        }
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
            trailing: HStack {
                Button(action: {
                    navigateToEdit = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    updateMemoryProgress()
                    showCompletionAlert = true
                }) {
                    Text("完成学习")
                        .foregroundColor(.blue)
                }
            }
        )
        .background(
            NavigationLink(destination: PreviewEditView(memoryItem: currentMemoryItem, shouldPopToRoot: $shouldPopToRoot), isActive: $navigateToEdit) {
                EmptyView()
            }
        )
        .onAppear {
            selectedSpeed = Float(settingsManager.settings.playbackSpeed)
            
            if settingsManager.settings.useApiVoice {
                // 使用API音色，预加载音频
                playWithApiVoice()
            } else {
                // 使用本地音色
                if speechManager.progress == 0 {
                    speechManager.prepare(
                        text: currentMemoryItem.content, 
                        speed: selectedSpeed,
                        intervalSeconds: settingsManager.settings.playbackInterval
                    )
                }
            }
        }
        .onDisappear {
            print("PlayerView 离开视图")
            // 停止本地语音播放
            speechManager.stop()
            
            // 停止API音频播放
            AudioPlayerService.shared.stop()
            isPlayingApiAudio = false
            
            // 取消API音频间隔计时器
            cancelApiAudioIntervalTimer()
        }
        .onChange(of: shouldPopToRoot) { newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
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
    
    // 使用API音色播放
    private func playWithApiVoice() {
        // 取消之前的间隔计时器
        cancelApiAudioIntervalTimer()
        
        isLoadingApiAudio = true
        apiAudioError = nil
        
        // 检查积分是否足够
        if dataManager.points < 5 {
            isLoadingApiAudio = false
            apiAudioError = "积分不足，无法使用在线语音。当前积分: \(dataManager.points)"
            return
        }
        
        // 调用API生成语音
        SiliconFlowTTSService.shared.generateSpeech(
            text: currentMemoryItem.content,
            voice: settingsManager.settings.apiVoiceType.rawValue,
            speed: selectedSpeed
        ) { audioURL, error in
            DispatchQueue.main.async {
                isLoadingApiAudio = false
                
                if let error = error {
                    apiAudioError = "加载失败: \(error.localizedDescription)"
                    return
                }
                
                guard let audioURL = audioURL else {
                    apiAudioError = "加载失败: 未知错误"
                    return
                }
                
                // 播放音频
                AudioPlayerService.shared.play(url: audioURL) {
                    // 注意：这个回调在音频播放完成时被调用
                    // 不要在这里直接更新UI状态，因为这不是在主线程上
                    
                    // 在主线程上更新UI状态
                    DispatchQueue.main.async {
                        // 更新播放状态
                        isPlayingApiAudio = false
                        
                        // 检查是否启用了播放间隔
                        if settingsManager.settings.enablePlaybackInterval {
                            // 获取间隔时间
                            let intervalSeconds = settingsManager.settings.playbackInterval
                            print("API音频播放完成，启动间隔计时器: \(intervalSeconds)秒")
                            
                            // 创建一个新的计时器任务
                            let workItem = DispatchWorkItem {
                                // 这个代码块会在间隔时间后执行
                                print("间隔时间结束，重新播放API音频")
                                // 确保我们仍在当前视图中
                                if !isPlayingApiAudio {
                                    playWithApiVoice()
                                }
                            }
                            
                            // 保存计时器任务的引用，以便稍后可以取消它
                            apiAudioIntervalTimer = workItem
                            
                            // 安排计时器任务在指定的间隔时间后执行
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(intervalSeconds), execute: workItem)
                        } else {
                            // 如果未启用播放间隔，则直接循环播放
                            print("API音频播放完成，未启用间隔，直接循环播放")
                            playWithApiVoice()
                        }
                    }
                }
                
                isPlayingApiAudio = true
                
                // 扣除积分（仅在首次生成时扣除，缓存的不扣除）
                if !SiliconFlowTTSService.shared.isCached(text: currentMemoryItem.content, voice: settingsManager.settings.apiVoiceType.rawValue, speed: selectedSpeed) {
                    dataManager.deductPoints(5, reason: "使用在线语音")
                }
            }
        }
    }
    
    // 取消API音频间隔计时器
    private func cancelApiAudioIntervalTimer() {
        if apiAudioIntervalTimer != nil {
            print("取消API音频间隔计时器")
            apiAudioIntervalTimer?.cancel()
            apiAudioIntervalTimer = nil
        }
    }
    
    // 更新记忆进度
    private func updateMemoryProgress() {
        // 更新学习进度和复习阶段
        var updatedItem = currentMemoryItem
        
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
    
    // 格式化时间
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 导航到上一个记忆项目
    private func navigateToPreviousItem() {
        guard enableItemNavigation, currentItemIndex > 0 else { return }
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex -= 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("导航到上一个记忆项目，当前索引：\(currentItemIndex)")
    }
    
    // 导航到下一个记忆项目
    private func navigateToNextItem() {
        guard enableItemNavigation, currentItemIndex < memoryItems.count - 1 else { return }
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex += 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("导航到下一个记忆项目，当前索引：\(currentItemIndex)")
    }
    
    // 停止所有播放
    private func stopPlayback() {
        // 停止系统语音
        if speechManager.isPlaying {
            speechManager.stop()
        }
        
        // 停止API语音
        if isPlayingApiAudio {
            AudioPlayerService.shared.stop()
            isPlayingApiAudio = false
        }
        
        // 取消API音频间隔计时器
        cancelApiAudioIntervalTimer()
    }
    
    // 重置播放状态
    private func resetPlaybackState() {
        speechManager.reset()
        isPlayingApiAudio = false
        isLoadingApiAudio = false
        apiAudioError = nil
    }
}