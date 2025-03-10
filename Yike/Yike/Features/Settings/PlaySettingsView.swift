import SwiftUI

struct PlaySettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var speechManager = SpeechManager.shared
    @State private var settings: UserSettings
    private let previewText = "这是一段示例文本，用于预览当前选择的语音效果。"
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
    }
    
    var body: some View {
        Form {
            Section(header: Text("语音设置"), footer: Text("选择不同音色可以获得不同的播放体验，点击试听按钮可以预览效果")) {
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
                        speechManager.prepare(text: previewText, speed: Float(settings.playbackSpeed))
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
        }
    }
}

#Preview {
    NavigationView {
        PlaySettingsView()
    }
} 