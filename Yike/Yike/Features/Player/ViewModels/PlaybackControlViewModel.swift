import SwiftUI
import Combine

/// PlaybackControlViewModel 负责处理播放控制的业务逻辑
///
/// 主要功能：
/// - 统一管理本地语音和API语音的播放控制
/// - 处理播放状态和进度的更新
/// - 管理记忆项目的导航和更新
/// - 处理播放速度的调整
class PlaybackControlViewModel: ObservableObject {
    // 播放状态
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    @Published var error: String? = nil
    @Published var selectedSpeed: Float = 1.0
    
    // 记忆项目
    @Published var currentItemIndex: Int
    @Published var shouldShowCompletionAlert: Bool = false
    
    // 服务
    private let localVoiceManager = LocalVoicePlaybackManager.shared
    private let apiVoiceManager = ApiVoicePlaybackManager.shared
    private let settingsManager = SettingsManager.shared
    private let dataManager = DataManager.shared
    private let router = NavigationRouter.shared
    
    // 数据
    let memoryItems: [MemoryItem]
    private var cancellables = Set<AnyCancellable>()
    
    /// 是否启用项目间导航
    var enableItemNavigation: Bool {
        return memoryItems.count > 1
    }
    
    /// 当前显示的记忆项目
    var currentMemoryItem: MemoryItem {
        if enableItemNavigation && currentItemIndex >= 0 && currentItemIndex < memoryItems.count {
            return memoryItems[currentItemIndex]
        }
        return memoryItems.first ?? MemoryItem(id: UUID(), title: "", content: "", progress: 0, reviewStage: 0, lastReviewDate: nil, nextReviewDate: nil)
    }
    
    /// 是否使用API语音
    var useApiVoice: Bool {
        return settingsManager.settings.useApiVoice
    }
    
    /// 初始化（单个记忆项目）
    /// - Parameter memoryItem: 记忆项目
    init(memoryItem: MemoryItem) {
        self.memoryItems = [memoryItem]
        self.currentItemIndex = 0
        setupBindings()
    }
    
    /// 初始化（多个记忆项目）
    /// - Parameters:
    ///   - memoryItems: 记忆项目列表
    ///   - initialIndex: 初始索引
    init(memoryItems: [MemoryItem], initialIndex: Int) {
        guard initialIndex >= 0 && initialIndex < memoryItems.count else {
            self.memoryItems = memoryItems
            self.currentItemIndex = 0
            setupBindings()
            return
        }
        
        self.memoryItems = memoryItems
        self.currentItemIndex = initialIndex
        setupBindings()
    }
    
    /// 设置数据绑定
    private func setupBindings() {
        // 设置默认播放速度
        selectedSpeed = Float(settingsManager.settings.playbackSpeed)
        
        // 监听本地语音管理器的状态变化
        localVoiceManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                guard let self = self, !self.useApiVoice else { return }
                self.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        localVoiceManager.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                guard let self = self, !self.useApiVoice else { return }
                self.progress = progress
            }
            .store(in: &cancellables)
        
        localVoiceManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self, !self.useApiVoice else { return }
                self.currentTime = time
            }
            .store(in: &cancellables)
        
        localVoiceManager.$totalTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self, !self.useApiVoice else { return }
                self.totalTime = time
            }
            .store(in: &cancellables)
        
        // 监听API语音管理器的状态变化
        apiVoiceManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                guard let self = self, self.useApiVoice else { return }
                self.isPlaying = isPlaying
            }
            .store(in: &cancellables)
        
        // 确保API加载状态始终正确同步，无论API模式是否激活
        apiVoiceManager.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if self.useApiVoice {
                    self.isLoading = isLoading
                    if isLoading {
                        print("【调试详细】PlaybackControlViewModel: apiVoiceManager.isLoading -> true，已更新ViewModel状态")
                    } else {
                        print("【调试详细】PlaybackControlViewModel: apiVoiceManager.isLoading -> false，已更新ViewModel状态")
                    }
                }
            }
            .store(in: &cancellables)
        
        apiVoiceManager.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                guard let self = self, self.useApiVoice else { return }
                self.error = error
            }
            .store(in: &cancellables)
        
        apiVoiceManager.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                guard let self = self, self.useApiVoice else { return }
                self.progress = progress
            }
            .store(in: &cancellables)
        
        // 更新API语音的时间显示
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.useApiVoice else { return }
                self.currentTime = self.apiVoiceManager.formatTime(self.apiVoiceManager.currentTime)
                self.totalTime = self.apiVoiceManager.formatTime(self.apiVoiceManager.duration)
            }
            .store(in: &cancellables)
    }
    
    /// 准备播放
    func preparePlayback() {
        if useApiVoice {
            // 使用API语音，预加载音频
            playWithApiVoice()
        } else {
            // 使用本地音色
            localVoiceManager.prepare(
                text: currentMemoryItem.content,
                speed: selectedSpeed,
                intervalSeconds: settingsManager.settings.playbackInterval
            )
        }
    }
    
    /// 切换播放/暂停状态
    func togglePlayPause() {
        if useApiVoice {
            apiVoiceManager.togglePlayPause(
                text: currentMemoryItem.content,
                voice: settingsManager.settings.apiVoiceType.rawValue,
                speed: selectedSpeed
            )
        } else {
            localVoiceManager.togglePlayPause(
                text: currentMemoryItem.content,
                speed: selectedSpeed,
                intervalSeconds: settingsManager.settings.playbackInterval
            )
        }
    }
    
    /// 播放上一句
    func playPrevious() {
        if enableItemNavigation && currentItemIndex > 0 {
            navigateToPreviousItem()
        } else if !useApiVoice {
            // 如果没有启用项目间导航或已经是第一个项目，但使用本地语音，则播放上一句
            localVoiceManager.previous()
        }
    }
    
    /// 播放下一句
    func playNext() {
        if enableItemNavigation && currentItemIndex < memoryItems.count - 1 {
            navigateToNextItem()
        } else if !useApiVoice {
            // 如果没有启用项目间导航或已经是最后一个项目，但使用本地语音，则播放下一句
            localVoiceManager.next()
        }
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        selectedSpeed = speed
        
        if !useApiVoice {
            localVoiceManager.setSpeed(speed)
        } else if isPlaying {
            // 如果正在使用API音频，需要重新加载
            stopPlayback()
            playWithApiVoice()
        }
    }
    
    /// 使用API语音播放
    private func playWithApiVoice() {
        apiVoiceManager.play(
            text: currentMemoryItem.content,
            voice: settingsManager.settings.apiVoiceType.rawValue,
            speed: selectedSpeed
        )
    }
    
    /// 导航到上一个记忆项目
    func navigateToPreviousItem() {
        guard enableItemNavigation, currentItemIndex > 0 else { return }
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex -= 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("导航到上一个记忆项目，当前索引：\(currentItemIndex)")
        
        // 自动开始播放新内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.useApiVoice {
                self.playWithApiVoice()
            } else {
                self.localVoiceManager.prepare(
                    text: self.currentMemoryItem.content,
                    speed: self.selectedSpeed,
                    intervalSeconds: self.settingsManager.settings.playbackInterval
                )
                self.localVoiceManager.play()
            }
        }
    }
    
    /// 导航到下一个记忆项目
    func navigateToNextItem() {
        guard enableItemNavigation, currentItemIndex < memoryItems.count - 1 else { return }
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex += 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("导航到下一个记忆项目，当前索引：\(currentItemIndex)")
        
        // 自动开始播放新内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.useApiVoice {
                self.playWithApiVoice()
            } else {
                self.localVoiceManager.prepare(
                    text: self.currentMemoryItem.content,
                    speed: self.selectedSpeed,
                    intervalSeconds: self.settingsManager.settings.playbackInterval
                )
                self.localVoiceManager.play()
            }
        }
    }
    
    /// 停止所有播放
    func stopPlayback() {
        print("【最终方案】stopPlayback 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【最终方案】stopPlayback 在非主线程调用，立即切换到主线程")
            DispatchQueue.main.sync { [weak self] in
                self?.stopPlayback()
            }
            return
        }
        
        // 1. 首先确保禁用自动重播 - 这是最关键的第一步
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 2. 快速同步重置状态 - 立即进行UI响应
        print("【最终方案】stopPlayback: 同步重置状态")
        let oldPlaying = isPlaying
        let oldLoading = isLoading
        isPlaying = false
        isLoading = false
        error = nil
        
        print("【最终方案】stopPlayback: 已重置UI状态 - isPlaying: \(oldPlaying) -> false, isLoading: \(oldLoading) -> false")
        
        // 3. 停止播放器 - 同步操作
        print("【最终方案】stopPlayback: 停止本地和API播放器")
        localVoiceManager.stop()
        apiVoiceManager.stop()
        
        print("【最终方案】stopPlayback: 完成 - 时间: \(Date())")
    }
    
    /// 重置播放状态
    func resetPlaybackState() {
        print("【调试】PlaybackControlViewModel.resetPlaybackState 被调用")
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 时间=\(Date())")
        
        localVoiceManager.reset()
        
        let oldError = error
        error = nil
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 已重置错误状态: \(oldError ?? "无") -> nil")
        
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 完成 - 当前状态: isPlaying=\(isPlaying), isLoading=\(isLoading), 时间=\(Date())")
    }
    
    /// 清理资源
    func cleanup() {
        print("【调试】PlaybackControlViewModel.cleanup 被调用")
        print("【调试详细】PlaybackControlViewModel.cleanup: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 线程=\(Thread.isMainThread ? "主线程" : "后台线程"), 时间=\(Date())")
        
        // 确保在主线程执行状态更新
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.cleanup()
            }
            return
        }
        
        // 先停止播放，这是同步操作
        localVoiceManager.stop()
        apiVoiceManager.stop()
        
        // 重置状态
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0.0
        
        // 顺序清理订阅、本地语音资源和API语音资源
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理所有订阅 - 之前, 订阅数=\(cancellables.count)")
        cancellables.removeAll()
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理所有订阅 - 之后, 订阅数=\(cancellables.count)")
        
        // 简单干净的资源清理，不需要复杂的回调和超时
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理本地语音资源")
        localVoiceManager.reset()
        
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理API语音资源")
        apiVoiceManager.stop()
        
        // 重置所有状态标志
        setupBindings()
        
<<<<<<< HEAD
        // 当所有清理操作完成后
        cleanupGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // 取消超时保护
            operationTimeout.cancel()
            
            // 重置操作状态
            self.isOperationInProgress = false
            
            // 重新设置绑定
            self.setupBindings()
            
            print("【方案三】资源清理全部完成 - 时间: \(Date())")
        }
        
        print("【方案三】资源清理方法执行完毕 - 时间: \(Date())")
    }
    
    /// 显示完成弹窗并在确认后退出
    func showCompletionAlertAndExit() {
        print("【调试】显示完成弹窗并在确认后退出")
        // 确保在主线程执行UI更新
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showCompletionAlertAndExit()
            }
            return
        }
        
        // 更新UI状态
        shouldShowCompletionAlert = true
    }
    
    /// 退出页面并返回上一级
    func dismissAndNavigateBack() {
        print("【调试】dismissAndNavigateBack 被调用")
        
        // 确保在主线程执行UI更新
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.dismissAndNavigateBack()
            }
            return
        }
        
        // 立即更新UI状态
        shouldReturnToPreviousScreen = true
        
        // 通知路由器导航返回
        router.navigateBack()
        
        print("【调试】dismissAndNavigateBack 完成")
    }
    
    /// 强制清理所有播放资源
    func forceClearAllPlaybackResources(completion: (() -> Void)? = nil) {
        print("【方案三】forceClearAllPlaybackResources 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 检查是否在主线程，如果不是则切换到主线程
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.forceClearAllPlaybackResources(completion: completion)
            }
            return
        }
        
        // 1. 立即更新UI状态，确保界面响应性
        if self.isPlaying || self.isLoading {
            self.isPlaying = false
            self.isLoading = false
        }
        
        // 2. 尝试调用ApiVoicePlaybackManager的强制清理方法
        print("【方案三】开始调用ApiVoicePlaybackManager.forceCleanup - 时间: \(Date())")
        ApiVoicePlaybackManager.shared.forceCleanup {
            // 确保回调在主线程执行
            DispatchQueue.main.async {
                print("【方案三】ApiVoicePlaybackManager.forceCleanup 完成回调执行 - 时间: \(Date())")
                
                // 执行完成回调
                completion?()
            }
        }
        
        print("【方案三】资源清理方法执行完毕 - 时间: \(Date())")
=======
        print("【调试详细】PlaybackControlViewModel.cleanup: 方法执行完毕 - 时间=\(Date())")
>>>>>>> parent of f4f318b (大大大重构，优化完成确认按钮问题)
    }
    
    /// 更新记忆进度
    func updateMemoryProgress() {
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【调试】updateMemoryProgress在非主线程调用，转到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.updateMemoryProgress()
            }
            return
        }
        
        print("【调试】updateMemoryProgress: 开始处理 - \(Date())")
        
        // 1. 首先禁用自动重播，这是最关键的第一步
        print("【调试】updateMemoryProgress: 禁用自动重播")
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 2. 快速停止所有播放，这是同步的
        print("【调试】updateMemoryProgress: 停止所有播放")
        stopPlayback()
        
        // 3. 简化处理逻辑
        print("【调试】updateMemoryProgress: 更新学习进度数据")
        var updatedItem = self.currentMemoryItem
        
        if updatedItem.isNew {
            updatedItem.reviewStage = 1
            updatedItem.progress = 0.2
            
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                updatedItem.nextReviewDate = tomorrow
            }
        } else {
            updatedItem.progress = min(1.0, updatedItem.progress + 0.2)
            updatedItem.reviewStage = min(5, updatedItem.reviewStage + 1)
            
            if updatedItem.reviewStage < 5, let interval = self.settingsManager.settings.reviewStrategy.intervals.dropFirst(updatedItem.reviewStage - 1).first {
                if let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) {
                    updatedItem.nextReviewDate = nextDate
                }
            } else {
                updatedItem.nextReviewDate = nil
            }
        }
        
        updatedItem.lastReviewDate = Date()
        
        // 4. 保存数据变更
        print("【调试】updateMemoryProgress: 保存数据更新")
        dataManager.updateMemoryItem(updatedItem)
        
        // 5. 显示确认弹窗
        print("【调试】updateMemoryProgress: 显示确认弹窗")
        self.shouldShowCompletionAlert = true
        
        print("【调试】updateMemoryProgress: 完成处理 - \(Date())")
    }
    
    /// 强制清理所有播放资源
    /// 用于在关键时刻（如显示确认弹窗前和确认按钮点击时）确保所有资源被彻底清理
    func forceClearAllPlaybackResources(completion: (() -> Void)? = nil) {
        print("【调试】PlaybackControlViewModel.forceClearAllPlaybackResources 被调用")
        print("【调试详细】forceClearAllPlaybackResources: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 线程=\(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 预先重置状态标志，防止新的播放启动
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0.0
        
        // 添加超时保护，确保回调一定会被执行
        let timeoutSeconds = 1.0
        var callbackExecuted = false
        
        // 创建超时计时器，在规定时间内如果清理操作未完成，也执行回调
        let timeoutTimer = DispatchWorkItem {
            if !callbackExecuted {
                callbackExecuted = true
                print("【调试详细】forceClearAllPlaybackResources: 清理操作超时，强制执行回调")
                completion?()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutTimer)
        
        // 创建一个DispatchGroup来协调两个清理操作
        let cleanupGroup = DispatchGroup()
        
        // 强制停止并清理本地语音资源
        cleanupGroup.enter()
        localVoiceManager.forceCleanup {
            print("【调试详细】forceClearAllPlaybackResources: 本地语音管理器清理完成")
            cleanupGroup.leave()
        }
        
        // 强制停止并清理API语音资源
        cleanupGroup.enter()
        apiVoiceManager.forceCleanup {
            print("【调试详细】forceClearAllPlaybackResources: API语音管理器清理完成")
            cleanupGroup.leave()
        }
        
        // 使用异步操作确保所有清理都已完成
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 确保音频播放器状态被重置
            if self.isPlaying || self.isLoading {
                self.isPlaying = false
                self.isLoading = false
                print("【调试详细】forceClearAllPlaybackResources: 异步再次重置播放状态")
            }
            
            // 确保不会有新的播放启动
            self.localVoiceManager.stop()
            self.apiVoiceManager.stop()
        }
        
        // 当所有清理操作完成后调用回调
        cleanupGroup.notify(queue: .main) {
            print("【调试详细】forceClearAllPlaybackResources: 所有清理操作已完成")
            
            // 取消超时计时器
            timeoutTimer.cancel()
            
            // 确保回调只执行一次
            if !callbackExecuted {
                callbackExecuted = true
                completion?()
            }
        }
        
        print("【调试详细】forceClearAllPlaybackResources: 完成 - 当前状态: isPlaying=\(isPlaying), isLoading=\(isLoading)")
    }
    
    /// 打开编辑页面
    func openEditPage() {
        router.navigate(to: .previewEdit(memoryItem: currentMemoryItem, shouldPopToRoot: Binding.constant(false)))
    }
} 