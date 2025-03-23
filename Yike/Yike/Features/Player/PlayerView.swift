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
    // 保留presentationMode用于其他功能
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
                    // 立即禁用自动重播，防止在处理过程中开始新的播放循环
                    ApiVoicePlaybackManager.shared.disableAutoReplay()
                    // 然后再更新学习进度
                    viewModel.updateMemoryProgress()
                }) {
                    Text("完成学习")
                        .foregroundColor(.blue)
                }
            }
        )
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
                router.navigateBack()
            }
        }
        .alert(isPresented: $viewModel.shouldShowCompletionAlert) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
                    print("【调试】确认按钮被点击：采用强制导航方式")
                    
                    // 再次确保禁用自动重播
                    ApiVoicePlaybackManager.shared.disableAutoReplay()
                    
                    // 先确保所有播放都被停止
                    viewModel.stopPlayback()
                    
                    // 重置弹窗状态
                    viewModel.shouldShowCompletionAlert = false
                    
                    // 使用两种导航方式，确保在路由器方式失败时有后备
                    DispatchQueue.main.async {
                        // 首先尝试路由器导航
                        if router.canNavigateBack() {
                            print("【调试】确认按钮：使用router导航")
                            router.navigateBack()
                        } else {
                            // 后备方案：使用presentationMode
                            print("【调试】确认按钮：使用presentationMode导航")
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                        // 使用shouldPopToRoot标志作为最后的后备方式
                        if !router.isNavigating {
                            print("【调试】确认按钮：使用shouldPopToRoot导航")
                            shouldPopToRoot = true
                        }
                    }
                    
                    // 在另一个线程进行资源清理，不阻塞UI
                    DispatchQueue.global(qos: .background).async {
                        // 强制停止API语音播放，防止任何可能的自动重播
                        ApiVoicePlaybackManager.shared.stop()
                        // 最后进行全面资源清理
                        viewModel.forceClearAllPlaybackResources()
                    }
                }
            )
        }
    }
}