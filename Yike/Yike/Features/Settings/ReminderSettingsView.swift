import SwiftUI

struct ReminderSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var settings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        _settings = State(initialValue: SettingsManager.shared.settings)
    }
    
    var body: some View {
        Form {
            Section(header: Text("每日提醒")) {
                Toggle("开启每日提醒", isOn: $settings.enableDailyReminder)
                
                if settings.enableDailyReminder {
                    DatePicker("提醒时间", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("提醒方式")) {
                Picker("提醒样式", selection: $settings.reminderStyle) {
                    ForEach(UserSettings.ReminderStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("复习策略"), footer: Text(settings.reviewStrategy.description)) {
                Picker("记忆策略", selection: $settings.reviewStrategy) {
                    ForEach(UserSettings.ReviewStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("复习天数提示：")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(settings.reviewStrategy.intervals, id: \.self) { day in
                            Text("第\(day)天")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("提醒设置")
        .navigationBarItems(trailing: Button("保存") {
            settingsManager.updateSettings(settings)
            presentationMode.wrappedValue.dismiss()
        })
    }
} 