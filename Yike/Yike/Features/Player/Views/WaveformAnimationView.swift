import SwiftUI

/// WaveformAnimationView 负责显示音频波形动画
///
/// 主要功能：
/// - 显示音频播放时的波形动画效果
/// - 根据播放状态调整动画
struct WaveformAnimationView: View {
    // 是否正在播放
    var isPlaying: Bool
    
    // 波形线条数量
    private let lineCount = 30
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.blue)
                    .frame(width: 3, height: isPlaying ? 10 + CGFloat.random(in: 0...20) : 5)
                    .animation(
                        Animation.easeInOut(duration: 0.2)
                            .repeatForever()
                            .delay(Double(index) * 0.05),
                        value: isPlaying
                    )
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
    }
} 