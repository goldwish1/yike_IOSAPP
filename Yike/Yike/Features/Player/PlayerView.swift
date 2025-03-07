import SwiftUI
import AVFoundation

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
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
        utterance = AVSpeechUtterance(string: text)
        utterance?.rate = playbackSpeed * AVSpeechUtteranceDefaultSpeechRate
        utterance?.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        // 更新进度
        progress = Double(currentIndex) / Double(max(1, sentences.count))
        updateTimes()
    }
    
    func play() {
        guard let utterance = utterance else { return }
        synthesizer.speak(utterance)
        isPlaying = true
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
        invalidateTimer()
        if currentIndex < sentences.count - 1 {
            currentIndex += 1
            prepareUtterance(for: sentences[currentIndex])
            if isPlaying {
                play()
            }
        } else {
            // 到最后一句时，自动从头开始
            currentIndex = 0
            prepareUtterance(for: sentences[currentIndex])
            if isPlaying {
                play()
            }
        }
    }
    
    func setSpeed(_ speed: Float) {
        self.playbackSpeed = speed
        if let text = utterance?.speechString {
            // 如果正在播放，需要重新设置语速
            let wasPlaying = isPlaying
            invalidateTimer()
            synthesizer.stopSpeaking(at: .immediate)
            prepareUtterance(for: text)
            if wasPlaying {
                play()
            }
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
        if SettingsManager.shared.settings.enablePlaybackInterval {
            isPlaying = false
            startIntervalTimer()
        } else {
            // 自动播放下一句，如果是最后一句会自动从头开始
            next()
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
            .onChange(of: speechManager.isPlaying) { newValue in
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
            speechManager.stop()
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