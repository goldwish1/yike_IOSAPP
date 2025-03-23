import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject private var router: NavigationRouter
    @State private var settings: UserSettings
    @EnvironmentObject var dataManager: DataManager
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
    }
    
    var body: some View {
        contentView
            .navigationTitle("设置")
    }
    
    private var contentView: some View {
        List {
            // 播放设置
            Section(header: Text("播放设置")) {
                settingRow(
                    icon: "speaker.wave.2.fill",
                    iconColor: .blue,
                    title: "播放设置",
                    destination: .playSettings
                )
            }
            
            // 复习设置
            Section(header: Text("复习设置")) {
                settingRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "提醒设置",
                    destination: .reminderSettings
                )
            }
            
            // 积分管理
            Section(header: Text("积分管理")) {
                settingRow(
                    icon: "creditcard.fill",
                    iconColor: .green,
                    title: "积分中心",
                    destination: .pointsCenter,
                    trailing: {
                        Text("\(dataManager.points)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                )
            }
            
            // 关于我们
            Section(header: Text("其他")) {
                settingRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "关于",
                    destination: .about
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    @ViewBuilder
    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        destination: AppRoute,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        if #available(iOS 16.0, *) {
            Button {
                router.navigate(to: destination)
            } label: {
                HStack {
                    SettingRow(icon: icon, iconColor: iconColor, title: title)
                    Spacer()
                    trailing()
                }
            }
            .foregroundColor(.primary)
        } else {
            switch destination {
            case .playSettings:
                NavigationLink(destination: PlaySettingsView()) {
                    HStack {
                        SettingRow(icon: icon, iconColor: iconColor, title: title)
                        Spacer()
                        trailing()
                    }
                }
            case .reminderSettings:
                NavigationLink(destination: ReminderSettingsView()) {
                    HStack {
                        SettingRow(icon: icon, iconColor: iconColor, title: title)
                        Spacer()
                        trailing()
                    }
                }
            case .pointsCenter:
                NavigationLink(destination: PointsCenterView()) {
                    HStack {
                        SettingRow(icon: icon, iconColor: iconColor, title: title)
                        Spacer()
                        trailing()
                    }
                }
            case .about:
                NavigationLink(destination: AboutView()) {
                    HStack {
                        SettingRow(icon: icon, iconColor: iconColor, title: title)
                        Spacer()
                        trailing()
                    }
                }
            default:
                EmptyView()
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