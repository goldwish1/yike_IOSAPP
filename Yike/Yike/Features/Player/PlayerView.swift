import SwiftUI
import AVFoundation

struct PlayerView: View {
    // 单个记忆项目（向后兼容）
    let memoryItem: MemoryItem
    
    // 记忆项目列表和当前索引（用于项目间导航）
    let memoryItems: [MemoryItem]
    let initialIndex: Int
    let enableItemNavigation: Bool
    
    @StateObject private var viewModel: PlaybackControlViewModel
    @ObservedObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject private var router: NavigationRouter
    @State private var shouldPopToRoot = false
    @Environment(\.presentationMode) var presentationMode
    
    // 原有初始化方法（单个记忆项目，向后兼容）
    init(memoryItem: MemoryItem) {
        self.memoryItem = memoryItem
        self.memoryItems = [memoryItem]
        self.initialIndex = 0
        self.enableItemNavigation = false
        self._viewModel = StateObject(wrappedValue: PlaybackControlViewModel(memoryItem: memoryItem))
    }
    
    // 新增初始化方法（支持项目间导航）
    init(memoryItems: [MemoryItem], initialIndex: Int) {
        guard initialIndex >= 0 && initialIndex < memoryItems.count else {
            // 防止索引越界
            self.memoryItem = memoryItems.first ?? MemoryItem(id: UUID(), title: "", content: "", progress: 0, reviewStage: 0, lastReviewDate: nil, nextReviewDate: nil)
            self.memoryItems = memoryItems
            self.initialIndex = 0
            self.enableItemNavigation = memoryItems.count > 1
            self._viewModel = StateObject(wrappedValue: PlaybackControlViewModel(memoryItems: memoryItems, initialIndex: 0))
            return
        }
        
        self.memoryItem = memoryItems[initialIndex]
        self.memoryItems = memoryItems
        self.initialIndex = initialIndex
        self.enableItemNavigation = memoryItems.count > 1
        self._viewModel = StateObject(wrappedValue: PlaybackControlViewModel(memoryItems: memoryItems, initialIndex: initialIndex))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text(viewModel.currentMemoryItem.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 内容
            ScrollView {
                Text(viewModel.currentMemoryItem.content)
                    .font(.body)
                    .lineSpacing(8)
                    .padding()
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 波形动画
            WaveformAnimationView(isPlaying: viewModel.isPlaying)
            
            // 进度条
            PlaybackProgressView(viewModel: viewModel)
            
            // 控制按钮
            PlayerControlsView(viewModel: viewModel, useApiVoice: settingsManager.settings.useApiVoice)
            
            if let error = viewModel.error {
                Button(action: {
                    if error.contains("积分不足") {
                        // 导航到积分中心
                        router.navigate(to: .pointsCenter)
                    }
                }) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 播放速度选择
            SpeedSelectionView(viewModel: viewModel)
        }
        .padding(.bottom, 24)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    viewModel.openEditPage()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    viewModel.updateMemoryProgress()
                }) {
                    Text("完成学习")
                        .foregroundColor(.blue)
                }
            }
        )
        .navigationDestination(isPresented: $viewModel.shouldNavigateToEdit) {
            PreviewEditView(memoryItem: viewModel.currentMemoryItem, shouldPopToRoot: $shouldPopToRoot)
        }
        .onAppear {
            viewModel.preparePlayback()
        }
        .onDisappear {
            // 立即停止所有音频播放
            viewModel.stopPlayback()
            // 再进行完整清理
            viewModel.cleanup()
        }
        .onChange(of: shouldPopToRoot) { oldValue, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert(isPresented: $viewModel.shouldShowCompletionAlert) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
                    print("【调试】确认按钮被点击：开始停止音频播放和清理资源")
                    
                    // 确保所有异步操作和音频播放完全停止
                    // 首先强制禁用自动重播
                    ApiVoicePlaybackManager.shared.stop()
                    print("【调试】已调用ApiVoicePlaybackManager.shared.stop()")
                    
                    // 停止其他所有播放
                    viewModel.stopPlayback()
                    print("【调试】已调用viewModel.stopPlayback()")
                    
                    // 延长等待时间以确保停止命令完全生效
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("【调试】确认按钮异步操作：延迟0.5秒后执行")
                        
                        // 再次停止所有播放以确保没有新的播放开始
                        ApiVoicePlaybackManager.shared.stop()
                        print("【调试】再次调用ApiVoicePlaybackManager.shared.stop()")
                        
                        viewModel.stopPlayback()
                        print("【调试】再次调用viewModel.stopPlayback()")
                        
                        // 清理所有资源
                        print("【调试】开始清理所有资源")
                        viewModel.cleanup()
                        print("【调试】已完成清理所有资源")
                        
                        // 再等待一小段时间确保所有回调已执行完毕
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            print("【调试】确认按钮最终异步操作：准备关闭页面")
                            // 关闭页面
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            )
        }
    }
}