import SwiftUI
import AVFoundation
<<<<<<< HEAD
// import AlertToast  // 暂时注释掉这行

// 导入自定义服务
// AudioResourceGuardian已在同一模块，无需导入
=======
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)

struct PlayerView: View {
    // 单个记忆项目（向后兼容）
    let memoryItem: MemoryItem
    
    // 记忆项目列表和当前索引（用于项目间导航）
    let memoryItems: [MemoryItem]
    let initialIndex: Int
    let enableItemNavigation: Bool
    
    // 页面唯一标识 - 用于生命周期管理
    private let pageId = UUID().uuidString
    
    @StateObject private var viewModel: PlaybackControlViewModel
    @ObservedObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject private var router: NavigationRouter
    
    // 使用系统提供的dismiss机制
    @Environment(\.dismiss) private var dismiss
    
    // 添加标志来跟踪资源清理状态
    @State private var isCleaningUp: Bool = false
    @State private var showingConfirmation: Bool = false // 单纯跟踪确认弹窗的状态
    
    // 添加生命周期管理器引用
    @ObservedObject private var lifecycleManager = ViewLifecycleManager.shared
    // 添加资源监视器引用
    @ObservedObject private var resourceMonitor = GlobalResourceMonitor.shared
    
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
<<<<<<< HEAD
                    // 使用新的生命周期管理执行保护操作
                    handleCompleteLearning()
=======
                    print("【调试】完成学习按钮点击：准备显示确认对话框")
                    
                    // 立即禁用自动重播，这是最重要的第一步
                    ApiVoicePlaybackManager.shared.disableAutoReplay()
                    
                    // 立即停止所有播放，同步操作
                    viewModel.stopPlayback()
                    
                    // 简单将状态存储在showingConfirmation中，然后让updateMemoryProgress处理业务逻辑
                    viewModel.updateMemoryProgress()
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
                }) {
                    Text("完成学习")
                        .foregroundColor(.blue)
                }
            }
        )
        .onAppear {
<<<<<<< HEAD
            print("【生命周期管理】PlayerView.onAppear - 页面ID: \(pageId)")
            // 重置生命周期标志
            hasProcessedCleanup = false
            dismissInProgress = false
            isUIResponsive = true
            
            // 注册页面到资源监视器
            resourceMonitor.registerPage(pageId)
            
=======
            // 重置清理状态
            isCleaningUp = false
            showingConfirmation = false
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
            // 准备播放
            viewModel.preparePlayback()
        }
        .onDisappear {
<<<<<<< HEAD
            print("【生命周期管理】PlayerView.onDisappear - 页面ID: \(pageId), 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
            
            if !hasProcessedCleanup {
                // 设置标志防止重复清理
                hasProcessedCleanup = true
                
                // 注销页面
                resourceMonitor.unregisterPage(pageId)
                
                print("【生命周期管理】PlayerView.onDisappear - 执行资源清理")
=======
            if !isCleaningUp {
                print("【调试】PlayerView.onDisappear: 开始清理资源")
                isCleaningUp = true
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
                
                // 极简的onDisappear处理，只关心停止播放和禁用自动重播
                ApiVoicePlaybackManager.shared.disableAutoReplay()
                viewModel.stopPlayback()
                
<<<<<<< HEAD
                // 异步执行资源清理
                DispatchQueue.global(qos: .userInitiated).async {
                    // 强制清理所有资源
                    ApiVoicePlaybackManager.shared.forceCleanup {
                        print("【生命周期管理】PlayerView.onDisappear - 资源清理完成")
                    }
=======
                // 延迟彻底清理所有资源，但不管这个是否完成
                DispatchQueue.global(qos: .background).async {
                    print("【调试】PlayerView.onDisappear: 后台线程执行彻底资源清理")
                    // 这里直接调用原子操作的清理方法，不需要回调或协调
                    ApiVoicePlaybackManager.shared.forceCleanup(completion: nil)
                    // 允许足够的时间完成清理
                    Thread.sleep(forTimeInterval: 0.5)
                    print("【调试】PlayerView.onDisappear: 后台线程资源清理完成")
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
                }
            }
        }
        .alert(isPresented: $viewModel.shouldShowCompletionAlert) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
<<<<<<< HEAD
                    // 使用新的生命周期管理机制处理确认按钮点击
                    handleAlertConfirmation()
=======
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
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
                }
            )
        }
        // 添加生命周期管理
        .withManagedLifecycle(id: pageId)
    }
    
    /// 处理完成学习按钮点击
    private func handleCompleteLearning() {
        // 防止按钮反复点击
        guard isUIResponsive else {
            print("【生命周期管理】完成学习按钮点击被忽略 - UI尚未响应")
            return
        }
        
        // 设置UI为不响应状态，防止重复操作
        isUIResponsive = false
        
        print("【生命周期管理】完成学习按钮点击 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 1. UI操作 - 同步执行，立即响应
        // 立即禁用自动重播（轻量级操作）
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 立即更新UI状态，确保按钮变为禁用状态
        if viewModel.isPlaying {
            viewModel.isPlaying = false
        }
        
        // 2. 更新进度并显示弹窗
        viewModel.updateMemoryProgress()
        
        // 3. 并行处理资源释放 - 不阻塞UI
        lifecycleManager.beginResourceRelease(pageId: pageId)
        
        // 异步执行资源清理，不阻塞UI线程
        DispatchQueue.global(qos: .userInitiated).async {
            // 强制清理所有资源
            ApiVoicePlaybackManager.shared.forceCleanup {
                // 资源清理完成后通知生命周期管理器
                print("【生命周期管理】资源清理完成")
                
                // 如果显示了确认对话框，让用户确认后再dismiss
                if viewModel.shouldShowCompletionAlert {
                    print("【生命周期管理】等待用户确认对话框")
                } else {
                    // 如果没有显示确认对话框，主动完成dismiss流程
                    DispatchQueue.main.async {
                        lifecycleManager.resourceReleaseCompleted(pageId: pageId) {
                            dismiss()
                        }
                    }
                }
            }
        }
        
        // 设置超时保护，确保最终资源会被释放
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // 重置UI响应状态，允许用户再次点击
            isUIResponsive = true
        }
    }
    
    /// 处理确认按钮点击
    private func handleAlertConfirmation() {
        print("【生命周期管理】确认按钮点击 - 当前线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 防止重复操作
        guard !dismissInProgress else {
            print("【生命周期管理】确认按钮点击 - dismiss已经在进行中，忽略此次操作")
            return
        }
        
        // 设置标志，防止重复点击和重复清理
        dismissInProgress = true
        hasProcessedCleanup = true
        
        // 开始退出流程
        lifecycleManager.beginDismiss(pageId: pageId) {
            // 在主线程上执行dismiss
            DispatchQueue.main.async {
                print("【生命周期管理】执行dismiss")
                dismiss()
                
                // 重置状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismissInProgress = false
                    hasProcessedCleanup = true
                }
            }
        }
        
        // 强制清理资源 - 并行执行，不阻塞UI
        DispatchQueue.global(qos: .userInitiated).async {
            // 立即禁用自动重播 - 同步操作
            ApiVoicePlaybackManager.shared.disableAutoReplay()
            
            // 重置播放状态
            DispatchQueue.main.async {
                viewModel.resetPlaybackState()
            }
            
            // 强制清理资源
            ApiVoicePlaybackManager.shared.forceCleanup {
                // 资源清理完成，通知生命周期管理器
                DispatchQueue.main.async {
                    lifecycleManager.resourceReleaseCompleted(pageId: pageId) {
                        // 资源释放完成回调内不需要执行额外操作
                        // dismiss已经在beginDismiss中处理
                        print("【生命周期管理】资源释放完成回调执行")
                    }
                }
            }
        }
    }
}