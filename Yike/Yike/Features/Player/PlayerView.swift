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
    
    // 使用系统提供的dismiss机制
    @Environment(\.dismiss) private var dismiss
    
    // 添加标志来跟踪资源清理状态
    @State private var isCleaningUp: Bool = false
    @State private var showingConfirmation: Bool = false // 单纯跟踪确认弹窗的状态
    
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
                    print("【调试】完成学习按钮点击：准备显示确认对话框")
                    
                    // 立即禁用自动重播，这是最重要的第一步
                    ApiVoicePlaybackManager.shared.disableAutoReplay()
                    
                    // 立即停止所有播放，同步操作
                    viewModel.stopPlayback()
                    
                    // 简单将状态存储在showingConfirmation中，然后让updateMemoryProgress处理业务逻辑
                    viewModel.updateMemoryProgress()
                }) {
                    Text("完成学习")
                        .foregroundColor(.blue)
                }
            }
        )
        .onAppear {
            // 重置清理状态
            isCleaningUp = false
            showingConfirmation = false
            // 准备播放
            viewModel.preparePlayback()
        }
        .onDisappear {
            if !isCleaningUp {
                print("【调试】PlayerView.onDisappear: 开始清理资源")
                isCleaningUp = true
                
                // 极简的onDisappear处理，只关心停止播放和禁用自动重播
                ApiVoicePlaybackManager.shared.disableAutoReplay()
                viewModel.stopPlayback()
                
                // 延迟彻底清理所有资源，但不管这个是否完成
                DispatchQueue.global(qos: .background).async {
                    print("【调试】PlayerView.onDisappear: 后台线程执行彻底资源清理")
                    // 这里直接调用原子操作的清理方法，不需要回调或协调
                    ApiVoicePlaybackManager.shared.forceCleanup(completion: nil)
                    // 允许足够的时间完成清理
                    Thread.sleep(forTimeInterval: 0.5)
                    print("【调试】PlayerView.onDisappear: 后台线程资源清理完成")
                }
            }
        }
        .alert(isPresented: $viewModel.shouldShowCompletionAlert) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
                    print("【调试】确认按钮被点击：极简处理")
                    
                    // 关键：最短路径处理，无复杂逻辑
                    // 1. 立即禁用自动重播 - 同步操作
                    ApiVoicePlaybackManager.shared.disableAutoReplay()
                    
                    // 2. 重置弹窗状态 - 同步操作
                    viewModel.shouldShowCompletionAlert = false
                    
                    // 3. 设置清理标志，防止onDisappear重复清理
                    isCleaningUp = true
                    
                    // 4. 立即返回
                    print("【调试】确认按钮：立即调用dismiss()")
                    dismiss()
                }
            )
        }
    }
}