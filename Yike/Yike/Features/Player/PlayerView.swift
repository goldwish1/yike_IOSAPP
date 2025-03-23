import SwiftUI
import AVFoundation
// import AlertToast  // 暂时注释掉这行

// 导入自定义服务
import class Yike.AudioResourceGuardian  // 导入AudioResourceGuardian

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
    
    // 生命周期管理标志
    @State private var hasProcessedCleanup: Bool = false
    // 添加信号量标记，避免重复执行dismiss操作
    @State private var dismissInProgress: Bool = false
    // 添加UI响应状态标记
    @State private var isUIResponsive: Bool = true
    
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
                    // 使用事件保护器执行保护操作
                    EventGuardian.shared.performProtectedAction {
                        // 防止按钮反复点击
                        guard isUIResponsive else {
                            print("【UI保护】完成学习按钮点击被忽略 - UI尚未响应")
                            return
                        }
                        
                        // 设置UI为不响应状态，防止重复操作
                        isUIResponsive = false
                        
                        print("【终极方案】完成学习按钮点击 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
                        
                        // 立即禁用自动重播（轻量级操作）
                        ApiVoicePlaybackManager.shared.disableAutoReplay()
                        
                        // 确保在主线程上执行所有UI相关操作
                        DispatchQueue.main.async {
                            // 立即更新UI状态，确保按钮变为禁用状态
                            if viewModel.isPlaying {
                                viewModel.isPlaying = false
                            }
                            
                            // 更新进度并显示弹窗
                            viewModel.updateMemoryProgress()
                            
                            // 延迟恢复UI响应性
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isUIResponsive = true
                            }
                        }
                        
                        print("【终极方案】完成学习按钮点击处理完成 - 时间: \(Date())")
                    }
                }) {
                    Text("完成学习")
                        .foregroundColor(isUIResponsive ? .blue : .gray)
                        .opacity(isUIResponsive ? 1.0 : 0.6)
                }
                .disabled(!isUIResponsive)
                .withEventFilter() // 添加事件过滤保护
            }
        )
        .onAppear {
            print("【终极方案】PlayerView.onAppear")
            // 重置生命周期标志
            hasProcessedCleanup = false
            dismissInProgress = false
            isUIResponsive = true
            // 准备播放
            viewModel.preparePlayback()
        }
        .onDisappear {
            print("【终极方案】PlayerView.onDisappear - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
            if !hasProcessedCleanup {
                // 设置标志防止重复清理
                hasProcessedCleanup = true
                print("【终极方案】PlayerView.onDisappear - 执行资源清理")
                
                // 立即在主线程上更新UI状态
                if viewModel.isPlaying {
                    viewModel.isPlaying = false
                }
                
                // 立即禁用自动重播（轻量级操作）
                ApiVoicePlaybackManager.shared.disableAutoReplay()
                
                // 创建信号量并添加超时保护
                let cleanupGroup = DispatchGroup()
                
                // 在后台线程异步执行可能耗时的资源清理操作
                cleanupGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    print("【终极方案】PlayerView.onDisappear - 后台执行资源清理 - 时间: \(Date())")
                    
                    // 停止播放器，并在完成后释放信号量
                    ApiVoicePlaybackManager.shared.stop {
                        print("【终极方案】PlayerView.onDisappear - API语音资源清理完成 - 时间: \(Date())")
                        cleanupGroup.leave()
                    }
                }
                
                // 设置超时，确保即使资源清理卡住也能继续
                let timeoutSeconds = 3.0
                DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds) {
                    if cleanupGroup.wait(timeout: .now()) != .success {
                        print("【终极方案】PlayerView.onDisappear - 资源清理超时，强制继续 - 时间: \(Date())")
                        cleanupGroup.leave() // 强制释放信号量
                    }
                }
                
                // 可选：等待资源清理完成（如果需要在视图消失前确保资源已清理）
                // 注意：这里不会阻塞UI线程，因为onDisappear已经在视图消失后异步执行
                cleanupGroup.notify(queue: .main) {
                    print("【终极方案】PlayerView.onDisappear - 所有资源清理操作已完成 - 时间: \(Date())")
                }
                
                print("【终极方案】PlayerView.onDisappear - 主线程处理完成 - 时间: \(Date())")
            }
        }
        .alert(isPresented: EventGuardian.shared.protectedAlertBinding($viewModel.shouldShowCompletionAlert)) {
            Alert(
                title: Text("学习进度已更新"),
                message: Text("你已完成一次学习，记忆进度已更新。"),
                dismissButton: .default(Text("确定")) {
                    print("【终极方案】确认按钮点击 - 当前线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
                    
                    // 使用事件保护器执行保护操作
                    EventGuardian.shared.performProtectedAction {
                        // 防止重复操作
                        guard !dismissInProgress else {
                            print("【终极方案】确认按钮点击 - dismiss已经在进行中，忽略此次操作")
                            return
                        }
                        
                        // 设置标志，防止重复点击和重复清理
                        dismissInProgress = true
                        hasProcessedCleanup = true
                        
                        // 1. 立即禁用自动重播 - 同步操作
                        print("【终极方案】disableAutoReplay 被调用")
                        ApiVoicePlaybackManager.shared.disableAutoReplay()
                        print("【终极方案】disableAutoReplay 完成 - 已禁用自动重播")
                        
                        // 2. 立即重置播放状态
                        viewModel.resetPlaybackState()
                        print("【终极方案】确认按钮点击 - UI状态已重置")
                        
                        // 3. 停止API语音播放，并提供完成回调
                        print("【终极方案】ApiVoicePlaybackManager.stop 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
                        ApiVoicePlaybackManager.shared.stop {
                            print("【终极方案】确认按钮点击 - 资源清理完成，准备dismiss")
                            
                            // 4. 在主线程上执行dismiss操作
                            DispatchQueue.main.async {
                                // 执行dismiss
                                self.dismiss()
                                
                                // 5. 重置状态
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.dismissInProgress = false
                                }
                            }
                        }
                    }
                }
            )
        }
    }
}