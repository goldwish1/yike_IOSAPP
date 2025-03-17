import SwiftUI

struct PlaySettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var speechManager = SpeechManager.shared
    @ObservedObject private var dataManager = DataManager.shared
    @State private var settings: UserSettings
    @State private var isTestingApiVoice = false
    @State private var apiVoiceTestError: String? = nil
    @State private var selectedCategory: UserSettings.ApiVoiceCategory = .male
    @State private var showingApiVoiceAlert = false
    private let previewText = "这是一段示例文本，用于预览当前选择的语音效果。"
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
        _selectedCategory = State(initialValue: SettingsManager.shared.settings.apiVoiceType.category)
    }
    
    var body: some View {
        Form {
            Section(header: Text("语音来源"), footer: Text("选择使用本地语音合成或在线API语音合成")) {
                HStack {
                    Toggle("使用在线高质量语音", isOn: $settings.useApiVoice)
                        .accessibilityIdentifier("useApiVoiceSwitch")
                        .onChange(of: settings.useApiVoice) { oldValue, newValue in
                            // 切换语音来源时停止播放
                            if speechManager.isPlaying {
                                speechManager.stop()
                            }
                            
                            // 如果用户首次开启在线语音，且未显示过提示，则显示提示信息
                            if newValue && !dataManager.hasShownApiVoiceAlert {
                                showingApiVoiceAlert = true
                            }
                        }
                    
                    Text("Beta")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            
            if settings.useApiVoice {
                // 在线API音色设置
                Section(header: Text("在线音色设置"), footer: Text("选择不同音色可以获得不同的播放体验，点击试听按钮可以预览效果。试听功能完全免费，正式使用在线音色需要消耗积分。")) {
                    Picker("音色分类", selection: $selectedCategory) {
                        ForEach(UserSettings.ApiVoiceCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(isTestingApiVoice)
                    .onChange(of: selectedCategory) { oldValue, newValue in
                        // 当分类改变时，选择该分类下的第一个音色
                        if let firstVoice = UserSettings.ApiVoiceType.allCases.first(where: { $0.category == newValue }) {
                            settings.apiVoiceType = firstVoice
                        }
                    }
                    
                    Picker("音色选择", selection: $settings.apiVoiceType) {
                        ForEach(UserSettings.ApiVoiceType.allCases.filter { $0.category == selectedCategory }, id: \.self) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    }
                    .disabled(isTestingApiVoice)
                    
                    Button(action: {
                        testApiVoice()
                    }) {
                        HStack {
                            Text(isTestingApiVoice ? "正在试听中..." : "试听效果")
                            Spacer()
                            if isTestingApiVoice {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "speaker.wave.2")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(isTestingApiVoice)
                    
                    if let errorMessage = apiVoiceTestError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            } else {
                // 本地音色设置
                Section(header: Text("本地音色设置"), footer: Text("选择不同音色可以获得不同的播放体验，点击试听按钮可以预览效果")) {
                    Picker("音色选择", selection: $settings.playbackVoiceType) {
                        ForEach(UserSettings.VoiceType.allCases, id: \.self) { voice in
                            Text(voice.rawValue).tag(voice)
                        }
                    }
                    
                    Button(action: {
                        if speechManager.isPlaying {
                            // 如果正在播放，则暂停
                            speechManager.stop()
                        } else {
                            // 否则开始播放
                            speechManager.prepare(
                                text: previewText, 
                                speed: Float(settings.playbackSpeed),
                                intervalSeconds: settings.playbackInterval
                            )
                            speechManager.play()
                        }
                    }) {
                        HStack {
                            Text(speechManager.isPlaying ? "停止试听" : "试听效果")
                            Spacer()
                            Image(systemName: speechManager.isPlaying ? "stop.fill" : "speaker.wave.2")
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("播放设置")) {
                HStack {
                    Text("播放速度")
                    Spacer()
                    Text("\(String(format: "%.1f", settings.playbackSpeed))x")
                }
                
                Slider(value: $settings.playbackSpeed, in: 0.5...2.0, step: 0.1) {
                    Text("播放速度")
                } minimumValueLabel: {
                    Text("0.5x")
                } maximumValueLabel: {
                    Text("2.0x")
                }
                
                Toggle("启用播放间隔", isOn: $settings.enablePlaybackInterval)
                
                if settings.enablePlaybackInterval {
                    HStack {
                        Text("间隔时间")
                        Spacer()
                        Text("\(settings.playbackInterval)秒")
                    }
                    
                    Slider(value: Binding(
                        get: { Double(settings.playbackInterval) },
                        set: { settings.playbackInterval = Int($0) }
                    ), in: 1...20, step: 1) {
                        Text("间隔时间")
                    } minimumValueLabel: {
                        Text("1秒")
                    } maximumValueLabel: {
                        Text("20秒")
                    }
                }
            }
            
            if settings.useApiVoice {
                Section(header: Text("关于在线语音"), footer: Text("在线语音由硅基流动API提供，试听功能完全免费，正式使用每次会消耗5积分。生成的语音会缓存到本地，重复播放不会重复消耗积分。")) {
                    Button(action: {
                        SiliconFlowTTSService.shared.cleanExpiredCache()
                    }) {
                        HStack {
                            Text("清理过期缓存")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                    .foregroundColor(.red)
                    
                    Button(action: {
                        SiliconFlowTTSService.shared.clearAllCache()
                    }) {
                        HStack {
                            Text("清除所有缓存")
                            Spacer()
                            Image(systemName: "trash.fill")
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("播放设置")
        .onChange(of: settings) { oldValue, newValue in
            settingsManager.updateSettings(newValue)
        }
        .onDisappear {
            // 确保在视图消失时停止播放
            if speechManager.isPlaying {
                speechManager.stop()
            }
            
            // 停止API音频播放
            AudioPlayerService.shared.stop()
        }
        .alert("在线语音提示", isPresented: $showingApiVoiceAlert) {
            Button("我知道了") {
                dataManager.markApiVoiceAlertAsShown()
            }
        } message: {
            Text("使用在线高质量语音将消耗积分，每次使用消耗5积分。试听功能完全免费。\n\n已生成的语音会缓存到本地，重复播放不会重复消耗积分。\n\n您当前的积分余额：\(dataManager.points)积分")
        }
    }
    
    // 测试API音色
    private func testApiVoice() {
        isTestingApiVoice = true
        apiVoiceTestError = nil
        
        print("【试听日志】开始试听API音色: \(settings.apiVoiceType.rawValue)，当前积分: \(dataManager.points)")
        
        // 调用API生成语音
        SiliconFlowTTSService.shared.generateSpeech(
            text: previewText,
            voice: settings.apiVoiceType.rawValue,
            speed: Float(settings.playbackSpeed)
        ) { audioURL, error in
            DispatchQueue.main.async {
                if let error = error {
                    isTestingApiVoice = false
                    apiVoiceTestError = "试听失败: \(error.localizedDescription)"
                    print("【试听日志】试听失败: \(error.localizedDescription)")
                    return
                }
                
                guard let audioURL = audioURL else {
                    isTestingApiVoice = false
                    apiVoiceTestError = "试听失败: 未知错误"
                    print("【试听日志】试听失败: 未知错误")
                    return
                }
                
                print("【试听日志】试听成功，开始播放音频")
                
                // 播放音频
                AudioPlayerService.shared.play(url: audioURL) {
                    DispatchQueue.main.async {
                        isTestingApiVoice = false
                        print("【试听日志】试听播放完成")
                    }
                }
                
                // 试听功能设置为免费，不扣除积分
                // dataManager.deductPoints(5, reason: "试听API音色")
                print("【试听日志】试听功能免费，不扣除积分，当前积分: \(self.dataManager.points)")
            }
        }
    }
}

#Preview {
    NavigationView {
        PlaySettingsView()
    }
} 