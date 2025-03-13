import SwiftUI

/// PlaybackProgressView 负责显示播放进度
///
/// 主要功能：
/// - 显示当前播放时间和总时间
/// - 显示播放进度条
struct PlaybackProgressView: View {
    // 播放控制ViewModel
    @ObservedObject var viewModel: PlaybackControlViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.currentTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(viewModel.totalTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.blue)
        }
        .padding(.horizontal)
    }
} 