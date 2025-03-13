import SwiftUI

/// SpeedSelectionView 负责显示播放速度选择按钮
///
/// 主要功能：
/// - 显示不同播放速度的选择按钮
/// - 处理速度选择事件
struct SpeedSelectionView: View {
    // 播放控制ViewModel
    @ObservedObject var viewModel: PlaybackControlViewModel
    
    // 可选的播放速度
    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.5, 2.0]
    
    var body: some View {
        HStack {
            ForEach(speedOptions, id: \.self) { speed in
                Button(action: {
                    viewModel.setSpeed(speed)
                }) {
                    Text("\(String(format: "%.1f", speed))x")
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(viewModel.selectedSpeed == speed ? Color.blue : Color(.systemGray6))
                        .foregroundColor(viewModel.selectedSpeed == speed ? .white : .primary)
                        .cornerRadius(15)
                }
            }
        }
    }
} 