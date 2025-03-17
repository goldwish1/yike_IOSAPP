import SwiftUI

/// PlayerControlsView 负责播放控制按钮的UI展示
///
/// 主要功能：
/// - 显示播放/暂停按钮
/// - 显示上一句/下一句按钮
/// - 处理按钮点击事件
struct PlayerControlsView: View {
    // 播放控制ViewModel
    @ObservedObject var viewModel: PlaybackControlViewModel
    
    // 是否使用API语音
    var useApiVoice: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            if useApiVoice {
                // API音频播放控制
                Button(action: {
                    viewModel.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.enableItemNavigation && viewModel.currentItemIndex > 0 ? .primary : .gray)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.enableItemNavigation || viewModel.currentItemIndex <= 0)
                
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 70, height: 70)
                            .background(Color.blue)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("playButton")
                
                Button(action: {
                    viewModel.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.enableItemNavigation && viewModel.currentItemIndex < viewModel.memoryItems.count - 1 ? .primary : .gray)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.enableItemNavigation || viewModel.currentItemIndex >= viewModel.memoryItems.count - 1)
            } else {
                // 本地语音播放控制
                Button(action: {
                    viewModel.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.enableItemNavigation && viewModel.currentItemIndex > 0 ? .primary : .gray)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.enableItemNavigation || viewModel.currentItemIndex <= 0)
                
                Button(action: {
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    viewModel.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.enableItemNavigation && viewModel.currentItemIndex < viewModel.memoryItems.count - 1 ? .primary : .gray)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.enableItemNavigation || viewModel.currentItemIndex >= viewModel.memoryItems.count - 1)
            }
        }
    }
} 