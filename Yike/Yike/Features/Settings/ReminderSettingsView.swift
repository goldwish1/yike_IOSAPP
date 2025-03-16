import SwiftUI

// 自定义流式布局组件
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width + (lineWidth > 0 ? spacing : 0) > proposal.width ?? .infinity {
                // 换行
                width = max(width, lineWidth)
                height += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                // 继续当前行
                lineWidth += size.width + (lineWidth > 0 ? spacing : 0)
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        // 添加最后一行
        width = max(width, lineWidth)
        height += lineHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if x + size.width > bounds.maxX {
                // 换行
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// 如果您使用的是iOS 16以下版本，可以使用这个替代方案
struct LegacyFlowLayout: View {
    let items: [AnyView]
    let spacing: CGFloat
    
    init<Data, Content>(data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) where Data: RandomAccessCollection, Content: View {
        self.items = data.map { AnyView(content($0)) }
        self.spacing = spacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(0..<items.count, id: \.self) { index in
                items[index]
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geometry.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == items.count - 1 {
                            width = 0
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == items.count - 1 {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}

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
                    
                    // 使用网格布局显示复习天数
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 10)
                    ], spacing: 10) {
                        ForEach(settings.reviewStrategy.intervals, id: \.self) { day in
                            VStack(spacing: 2) {
                                Text("第")
                                    .font(.caption2)
                                Text("\(day)")
                                    .font(.system(size: 16, weight: .medium))
                                Text("天")
                                    .font(.caption2)
                            }
                            .frame(width: 50, height: 50)
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