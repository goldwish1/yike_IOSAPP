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
    
    // 导航控制
    @Published var shouldReturnToPreviousScreen: Bool = false
    
    // 操作锁，防止同一时间多个操作导致状态混乱
    private var isOperationInProgress = false
    private let operationQueue = DispatchQueue(label: "com.yike.viewmodel.operation", qos: .userInitiated)
    
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
        
        // 创建组合绑定 - 监听播放状态，增强状态同步可靠性
        Publishers.CombineLatest(
            localVoiceManager.$isPlaying,
            apiVoiceManager.$isPlaying
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] localIsPlaying, apiIsPlaying in
            guard let self = self else { return }
            let newPlayingState: Bool
            
            if self.useApiVoice {
                newPlayingState = apiIsPlaying
            } else {
                newPlayingState = localIsPlaying
            }
            
            if self.isPlaying != newPlayingState {
                print("【状态同步】ViewModel.isPlaying 从 \(self.isPlaying) 更新为 \(newPlayingState)")
                self.isPlaying = newPlayingState
            }
        }
        .store(in: &cancellables)
        
        // 监听本地语音管理器的状态变化
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
        
        // 监听API语音管理器的加载状态 - 创建组合绑定
        apiVoiceManager.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                
                // 只有在API模式下才更新加载状态
                if self.useApiVoice && self.isLoading != isLoading {
                    print("【状态同步】ViewModel.isLoading 从 \(self.isLoading) 更新为 \(isLoading)")
                    self.isLoading = isLoading
                }
            }
            .store(in: &cancellables)
        
        apiVoiceManager.$error
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                guard let self = self, self.useApiVoice else { return }
                if (self.error != nil) != (error != nil) || (error != nil && self.error != error) {
                    print("【状态同步】ViewModel.error 更新")
                    self.error = error
                }
            }
            .store(in: &cancellables)
        
        apiVoiceManager.$progress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                guard let self = self, self.useApiVoice else { return }
                self.progress = progress
            }
            .store(in: &cancellables)
        
        // 更新API语音的时间显示 - 使用防抖动定时器
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                guard let self = self, self.useApiVoice, self.isPlaying else { return }
                
                let newCurrentTime = self.apiVoiceManager.formatTime(self.apiVoiceManager.currentTime)
                let newTotalTime = self.apiVoiceManager.formatTime(self.apiVoiceManager.duration)
                
                // 只有值变化时才更新，减少UI刷新
                if self.currentTime != newCurrentTime {
                    self.currentTime = newCurrentTime
                }
                
                if self.totalTime != newTotalTime {
                    self.totalTime = newTotalTime
                }
            }
            .store(in: &cancellables)
        
        // 监控设置变化，确保状态同步
        settingsManager.$settings
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] settings in
                guard let self = self else { return }
                // 当设置变化时，确保选定速度与设置同步
                if settings.playbackSpeed != Double(self.selectedSpeed) {
                    self.selectedSpeed = Float(settings.playbackSpeed)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 安全执行操作，防止操作冲突
    /// - Parameters:
    ///   - operation: 要执行的操作
    private func performSafeOperation(_ operation: @escaping () -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isOperationInProgress {
                print("【状态保护】操作被跳过，因为已有操作正在进行")
                return
            }
            
            self.isOperationInProgress = true
            
            // 在主线程执行操作
            DispatchQueue.main.async {
                operation()
                
                // 操作完成后释放锁
                self.operationQueue.async {
                    self.isOperationInProgress = false
                }
            }
        }
    }
    
    /// 准备播放
    func preparePlayback() {
        performSafeOperation { [weak self] in
            guard let self = self else { return }
            print("【状态同步】准备播放 - 使用\(self.useApiVoice ? "API语音" : "本地语音")")
            
            if self.useApiVoice {
                // 使用API语音，预加载音频
                self.playWithApiVoice()
            } else {
                // 使用本地音色
                self.localVoiceManager.prepare(
                    text: self.currentMemoryItem.content,
                    speed: self.selectedSpeed,
                    intervalSeconds: self.settingsManager.settings.playbackInterval
                )
            }
        }
    }
    
    /// 切换播放/暂停状态
    func togglePlayPause() {
        performSafeOperation { [weak self] in
            guard let self = self else { return }
            print("【状态同步】切换播放/暂停 - 当前状态：isPlaying=\(self.isPlaying), isLoading=\(self.isLoading)")
            
            if self.useApiVoice {
                self.apiVoiceManager.togglePlayPause(
                    text: self.currentMemoryItem.content,
                    voice: self.settingsManager.settings.apiVoiceType.rawValue,
                    speed: self.selectedSpeed
                )
            } else {
                self.localVoiceManager.togglePlayPause(
                    text: self.currentMemoryItem.content,
                    speed: self.selectedSpeed,
                    intervalSeconds: self.settingsManager.settings.playbackInterval
                )
            }
        }
    }
    
    /// 播放上一句
    func playPrevious() {
        performSafeOperation { [weak self] in
            guard let self = self else { return }
            
            if self.enableItemNavigation && self.currentItemIndex > 0 {
                self.navigateToPreviousItem()
            } else if !self.useApiVoice {
                // 如果没有启用项目间导航或已经是第一个项目，但使用本地语音，则播放上一句
                self.localVoiceManager.previous()
            }
        }
    }
    
    /// 播放下一句
    func playNext() {
        performSafeOperation { [weak self] in
            guard let self = self else { return }
            
            if self.enableItemNavigation && self.currentItemIndex < self.memoryItems.count - 1 {
                self.navigateToNextItem()
            } else if !self.useApiVoice {
                // 如果没有启用项目间导航或已经是最后一个项目，但使用本地语音，则播放下一句
                self.localVoiceManager.next()
            }
        }
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度
    func setSpeed(_ speed: Float) {
        performSafeOperation { [weak self] in
            guard let self = self else { return }
            
            self.selectedSpeed = speed
            
            if !self.useApiVoice {
                self.localVoiceManager.setSpeed(speed)
            } else if self.isPlaying {
                // 如果正在使用API音频，需要重新加载
                self.stopPlayback()
                self.playWithApiVoice()
            }
        }
    }
    
    /// 使用API语音播放
    private func playWithApiVoice() {
        print("【状态同步】使用API语音播放 - 内容长度：\(currentMemoryItem.content.count)")
        apiVoiceManager.play(
            text: currentMemoryItem.content,
            voice: settingsManager.settings.apiVoiceType.rawValue,
            speed: selectedSpeed
        )
    }
    
    /// 导航到上一个记忆项目
    func navigateToPreviousItem() {
        guard enableItemNavigation, currentItemIndex > 0 else { return }
        
        // 先停止当前播放并禁用自动重播
        print("【状态同步】导航到上一项 - 当前索引: \(currentItemIndex)")
        apiVoiceManager.disableAutoReplay()
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex -= 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("【状态同步】导航到上一个记忆项目完成，当前索引：\(currentItemIndex)")
        
        // 使用延迟避免状态更新冲突
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
        
        // 先禁用自动重播
        print("【状态同步】导航到下一项 - 当前索引: \(currentItemIndex)")
        apiVoiceManager.disableAutoReplay()
        
        // 停止当前播放
        stopPlayback()
        
        // 更新索引
        currentItemIndex += 1
        
        // 重置播放状态
        resetPlaybackState()
        
        print("【状态同步】导航到下一个记忆项目完成，当前索引：\(currentItemIndex)")
        
        // 使用延迟避免状态更新冲突
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
    
    /// 停止播放
    func stopPlayback() {
        print("【新方案】stopPlayback 被调用")
        
        // 1. 先更新UI状态 - 最快反馈
        if isPlaying || isLoading {
            isPlaying = false
            isLoading = false
            error = nil
        }
        
        // 2. 禁用API自动重播 - 轻量级同步操作
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 3. 最后执行实际的播放器停止操作
        localVoiceManager.stop()
        apiVoiceManager.stop()
        
        print("【新方案】stopPlayback 完成")
    }
    
    /// 重置播放状态
    func resetPlaybackState() {
        print("【调试】PlaybackControlViewModel.resetPlaybackState 被调用")
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 时间=\(Date())")
        
        // 禁用自动重播
        apiVoiceManager.disableAutoReplay()
        
        // 确保UI状态一致
        if isPlaying || isLoading {
            isPlaying = false
            isLoading = false
        }
        
        // 重置本地播放器状态
        localVoiceManager.reset()
        
        // 清除错误
        let oldError = error
        error = nil
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 已重置错误状态: \(oldError ?? "无") -> nil")
        
        // 重置进度
        progress = 0.0
        currentTime = "00:00"
        totalTime = "00:00"
        
        print("【调试详细】PlaybackControlViewModel.resetPlaybackState: 完成 - 当前状态: isPlaying=\(isPlaying), isLoading=\(isLoading), 时间=\(Date())")
    }
    
    /// 清理所有资源
    func cleanup() {
        print("【方案三】PlaybackControlViewModel.cleanup 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保在主线程执行
        if !Thread.isMainThread {
            print("【方案三】cleanup在非主线程调用，转到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.cleanup()
            }
            return
        }
        
        // 状态检查和标记操作开始
        print("【方案三】当前状态 - isPlaying: \(isPlaying), isLoading: \(isLoading)")
        
        // 设置操作超时保护
        let operationTimeout = DispatchWorkItem { [weak self] in
            print("【方案三】cleanup操作超时保护触发")
            if let self = self, self.isOperationInProgress {
                self.isOperationInProgress = false
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0, execute: operationTimeout)
        
        // 标记操作开始
        isOperationInProgress = true
        
        // 1. 首先禁用自动重播
        print("【方案三】禁用自动重播")
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 2. 停止播放
        print("【方案三】停止播放")
        localVoiceManager.stop()
        apiVoiceManager.stop()
        
        // 3. 重置所有状态标志 - 在主线程上安全
        print("【方案三】重置所有状态标志")
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0
        
        // 4. 清除所有订阅
        print("【方案三】清除所有订阅")
        cancellables.removeAll()
        
        // 创建清理组
        let cleanupGroup = DispatchGroup()
        
        // 5. 清理本地语音资源
        print("【方案三】清理本地语音资源")
        cleanupGroup.enter()
        localVoiceManager.forceCleanup {
            print("【方案三】本地语音资源清理完成")
            cleanupGroup.leave()
        }
        
        // 6. 清理API语音资源
        print("【方案三】清理API语音资源")
        cleanupGroup.enter()
        apiVoiceManager.forceCleanup {
            print("【方案三】API语音资源清理完成")
            cleanupGroup.leave()
        }
        
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
    }
    
    /// 更新记忆进度
    func updateMemoryProgress() {
        print("【终极方案】updateMemoryProgress 被调用 - 线程: \(Thread.isMainThread ? "主线程" : "后台线程"), 时间: \(Date())")
        
        // 确保主线程执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateMemoryProgress()
            }
            return
        }
        
        // 检查是否有操作正在进行
        if isOperationInProgress {
            print("【状态保护】updateMemoryProgress 检测到操作正在进行中，避免冲突退出")
            return
        }
        
        // 设置操作状态标记
        isOperationInProgress = true
        
        // 设置超时保护
        let operationTimeout = DispatchWorkItem { [weak self] in
            print("【终极方案】updateMemoryProgress - 操作超时保护触发")
            if let self = self, self.isOperationInProgress {
                // 确保在主线程更新状态
                DispatchQueue.main.async {
                    self.isOperationInProgress = false
                }
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0, execute: operationTimeout)
        
        // 1. 立即集中更新所有UI状态变量，确保UI渲染一致性
        let wasPlaying = isPlaying
        isPlaying = false
        isLoading = false
        error = nil
        progress = 0
        
        // 2. 禁用自动重播，这是一个轻量级同步操作，不会阻塞UI
        print("【终极方案】禁用自动重播")
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 3. 创建一个DispatchGroup来协调资源清理和数据更新
        let operationGroup = DispatchGroup()
        
        // 4. 如果需要停止播放，先等待播放停止完成
        if wasPlaying {
            operationGroup.enter()
            print("【终极方案】开始停止播放 - 时间: \(Date())")
            
            // 在后台停止播放器，完成后释放信号量
            ApiVoicePlaybackManager.shared.stop {
                print("【终极方案】播放停止完成 - 时间: \(Date())")
                operationGroup.leave()
            }
        }
        
        // 5. 异步更新记忆项目数据，保持界面响应
        operationGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                operationGroup.leave()
                return
            }
            
            print("【终极方案】开始后台更新学习进度 - 时间: \(Date())")
            
            // 获取当前记忆项目的副本
            let currentItem = self.currentMemoryItem
            var updatedItem = currentItem
            
            // 更新进度
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
            
            // 保存记忆项目
            print("【终极方案】保存更新")
            self.dataManager.updateMemoryItem(updatedItem)
            
            print("【终极方案】后台更新学习进度完成 - 时间: \(Date())")
            operationGroup.leave()
        }
        
        // 6. 设置超时保护
        let timeoutSeconds = 3.0
        let timeoutWorkItem = DispatchWorkItem {
            if operationGroup.wait(timeout: .now()) != .success {
                print("【终极方案】updateMemoryProgress - 操作超时，强制继续 - 时间: \(Date())")
                // 超时后强制释放所有信号量
                if wasPlaying {
                    operationGroup.leave() // 释放播放停止信号量
                }
                operationGroup.leave() // 释放数据更新信号量
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWorkItem)
        
        // 7. 不等待所有操作完成，先显示确认弹窗
        // 这是关键修改：立即显示弹窗，不等待资源清理完成
        print("【终极方案】立即显示确认弹窗，不等待资源清理 - 时间: \(Date())")
        
        // 确保在主线程上更新UI状态，并使用事件保护器确保弹窗不会被中断
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 重要：先取消可能已存在的警告框，确保状态一致
            if self.shouldShowCompletionAlert {
                self.shouldShowCompletionAlert = false
                EventGuardian.shared.registerAlertDismissed()
                print("【事件保护】重置现有警告框状态以确保一致性")
                
                // 延迟一小段时间再显示，避免状态冲突
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    self.showAlertWithProtection()
                }
            } else {
                self.showAlertWithProtection()
            }
        }
        
        // 8. 当所有操作完成后，重置状态更新标志
        operationGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // 取消超时任务
            timeoutWorkItem.cancel()
            operationTimeout.cancel()
            
            print("【终极方案】所有后台操作已完成 - 时间: \(Date())")
            self.isOperationInProgress = false
        }
    }
    
    /// 使用保护机制显示警告框
    private func showAlertWithProtection() {
        // 使用EventGuardian检查是否可以显示警告框
        if EventGuardian.shared.canPresentAlert() {
            self.shouldShowCompletionAlert = true
            // 注意：这里不需要手动调用registerAlertPresented，
            // 因为我们已经使用protectedAlertBinding来处理状态变化
            print("【终极方案】shouldShowCompletionAlert已设置为true - 时间: \(Date())")
        } else {
            print("【事件保护】警告框显示被阻止，已有活跃警告框 - 时间: \(Date())")
            // 延迟一段时间后重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                if EventGuardian.shared.canPresentAlert() {
                    self.shouldShowCompletionAlert = true
                    print("【终极方案】shouldShowCompletionAlert延迟后设置为true - 时间: \(Date())")
                }
            }
        }
    }
    
    /// 打开编辑页面
    func openEditPage() {
        router.navigate(to: .previewEdit(memoryItem: currentMemoryItem, shouldPopToRoot: Binding.constant(false)))
    }
    
    /// 标记学习完成
    /// 此方法只负责更新数据并显示确认弹窗，不涉及导航控制
    func markLearningCompleted() {
        print("【新方案】markLearningCompleted 被调用")
        
        // 确保主线程执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.markLearningCompleted()
            }
            return
        }
        
        // 如果已有操作进行，则需要等待
        if isOperationInProgress {
            print("【状态保护】已有操作正在进行，延迟标记完成")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.markLearningCompleted()
            }
            return
        }
        
        // 标记操作开始
        isOperationInProgress = true
        
        // 1. 禁用自动重播，这是最优先的操作
        ApiVoicePlaybackManager.shared.disableAutoReplay()
        
        // 2. 停止当前播放
        stopPlayback()
        
        // 3. 更新记忆项目的进度数据
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
        
        // 4. 保存更新
        dataManager.updateMemoryItem(updatedItem)
        
        // 5. 显示确认弹窗
        self.shouldShowCompletionAlert = true
        
        // 6. 重置操作状态
        isOperationInProgress = false
        
        print("【新方案】markLearningCompleted 完成")
    }
} 