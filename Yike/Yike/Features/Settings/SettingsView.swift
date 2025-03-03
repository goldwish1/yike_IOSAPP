import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var settings: UserSettings
    @State private var showingAboutSheet = false
    @EnvironmentObject var dataManager: DataManager
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
    }
    
    var body: some View {
        NavigationView {
            List {
                // 播放设置
                Section(header: Text("播放设置")) {
                    NavigationLink(destination: PlaySettingsView()) {
                        SettingRow(icon: "speaker.wave.2.fill", iconColor: .blue, title: "播放设置")
                    }
                }
                
                // 复习设置
                Section(header: Text("复习设置")) {
                    NavigationLink(destination: ReminderSettingsView()) {
                        SettingRow(icon: "bell.fill", iconColor: .orange, title: "提醒设置")
                    }
                }
                
                // 积分管理
                Section(header: Text("积分管理")) {
                    NavigationLink(destination: PointsCenterView()) {
                        SettingRow(icon: "creditcard.fill", iconColor: .green, title: "积分中心")
                        
                        Spacer()
                        
                        Text("\(dataManager.points)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 关于我们
                Section(header: Text("其他")) {
                    Button(action: {
                        showingAboutSheet = true
                    }) {
                        SettingRow(icon: "info.circle.fill", iconColor: .gray, title: "关于")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .cornerRadius(8)
            
            Text(title)
                .font(.body)
                .padding(.leading, 8)
        }
    }
} 