import SwiftUI

struct PlaySettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var settings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
    }
    
    var body: some View {
        Form {
            Section(header: Text("语音设置")) {
                Picker("声音性别", selection: $settings.playbackVoiceGender) {
                    ForEach(UserSettings.VoiceGender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                
                Picker("音色选择", selection: $settings.playbackVoiceStyle) {
                    ForEach(UserSettings.VoiceStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }
            
            Section(header: Text("播放控制")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("默认播放速度")
                    
                    HStack {
                        Text("0.5x")
                            .font(.caption)
                        
                        Slider(value: $settings.playbackSpeed, in: 0.5...2.0, step: 0.25)
                        
                        Text("2.0x")
                            .font(.caption)
                    }
                    
                    Text("\(String(format: "%.1f", settings.playbackSpeed))x")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Toggle("开启播放间隔", isOn: $settings.enablePlaybackInterval)
                
                if settings.enablePlaybackInterval {
                    Picker("默认间隔时间", selection: $settings.playbackInterval) {
                        Text("5秒").tag(5)
                        Text("10秒").tag(10)
                        Text("15秒").tag(15)
                        Text("20秒").tag(20)
                    }
                }
            }
        }
        .navigationTitle("播放设置")
        .navigationBarItems(trailing: Button("保存") {
            settingsManager.updateSettings(settings)
            presentationMode.wrappedValue.dismiss()
        })
    }
} 