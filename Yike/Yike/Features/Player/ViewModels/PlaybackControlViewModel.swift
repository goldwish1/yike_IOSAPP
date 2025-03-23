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
    @Published var shouldNavigateToEdit: Bool = false
    @Published var shouldShowCompletionAlert: Bool = false
    
    // 服务
    private let localVoiceManager = LocalVoicePlaybackManager.shared
    private let apiVoiceManager = ApiVoicePlaybackManager.shared
    private let settingsManager = SettingsManager.shared
    private let dataManager = DataManager.shared
    
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
        
        apiVoiceManager.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                guard let self = self, self.useApiVoice else { return }
                self.isLoading = isLoading
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
        print("【调试】PlaybackControlViewModel.stopPlayback 被调用")
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 线程=\(Thread.isMainThread ? "主线程" : "后台线程"), 时间=\(Date())")
        
        // 停止系统语音
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 即将停止本地语音 - 之前")
        localVoiceManager.stop()
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 已停止本地语音 - 之后")
        
        // 停止API语音
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 即将停止API语音 - 之前")
        apiVoiceManager.stop()
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 已停止API语音 - 之后")
        
        print("【调试详细】PlaybackControlViewModel.stopPlayback: 完成 - 当前状态: isPlaying=\(isPlaying), isLoading=\(isLoading), 时间=\(Date())")
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
        
        // 停止所有播放
        print("【调试详细】PlaybackControlViewModel.cleanup: 停止所有播放 - 之前")
        stopPlayback()
        print("【调试详细】PlaybackControlViewModel.cleanup: 停止所有播放 - 之后")
        
        // 清理所有订阅
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理所有订阅 - 之前, 订阅数=\(cancellables.count)")
        cancellables.removeAll()
        print("【调试详细】PlaybackControlViewModel.cleanup: 清理所有订阅 - 之后, 订阅数=\(cancellables.count)")
        
        // 重置错误状态
        print("【调试详细】PlaybackControlViewModel.cleanup: 重置错误状态 - 之前, 当前错误=\(error ?? "无")")
        let oldError = error
        error = nil
        print("【调试详细】PlaybackControlViewModel.cleanup: 重置错误状态 - 之后, 旧错误=\(oldError ?? "无")")
        
        // 确保播放状态被重置
        let oldIsPlaying = isPlaying
        let oldIsLoading = isLoading
        isPlaying = false
        isLoading = false
        print("【调试详细】PlaybackControlViewModel.cleanup: 重置播放状态 - isPlaying: \(oldIsPlaying) -> false, isLoading: \(oldIsLoading) -> false")
        
        let oldProgress = progress
        progress = 0.0
        print("【调试详细】PlaybackControlViewModel.cleanup: 重置进度 - progress: \(oldProgress) -> 0.0")
        
        // 再次确保语音管理器的状态被清理
        print("【调试详细】PlaybackControlViewModel.cleanup: 准备异步再次停止音频 - 时间=\(Date())")
        DispatchQueue.main.async {
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步操作开始 - 线程=\(Thread.isMainThread ? "主线程" : "后台线程"), 时间=\(Date())")
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步操作中当前状态 - isPlaying=\(self.isPlaying), isLoading=\(self.isLoading)")
            
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步再次停止API语音 - 之前")
            self.apiVoiceManager.stop()
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步再次停止API语音 - 之后")
            
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步再次停止本地语音 - 之前")
            self.localVoiceManager.stop()
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步再次停止本地语音 - 之后")
            
            print("【调试详细】PlaybackControlViewModel.cleanup: 异步操作完成 - 时间=\(Date())")
        }
        
        print("【调试详细】PlaybackControlViewModel.cleanup: 方法执行完毕 - 时间=\(Date())")
    }
    
    /// 更新记忆进度
    func updateMemoryProgress() {
        // 先停止所有音频播放，避免弹窗显示时还在播放
        print("【调试】updateMemoryProgress: 先停止音频播放再显示确认弹窗")
        stopPlayback()
        
        // 强制清理所有播放资源，确保彻底终止所有异步操作
        print("【调试】updateMemoryProgress: 强制清理所有播放资源")
        forceClearAllPlaybackResources()
        
        // 更新学习进度和复习阶段
        var updatedItem = currentMemoryItem
        
        if updatedItem.isNew {
            // 首次学习，设置为第一阶段
            updatedItem.reviewStage = 1
            updatedItem.progress = 0.2
            
            // 设置下一次复习时间（明天）
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                updatedItem.nextReviewDate = tomorrow
            }
        } else {
            // 已在复习中，更新进度
            let progressIncrement = 0.2
            updatedItem.progress = min(1.0, updatedItem.progress + progressIncrement)
            updatedItem.reviewStage = min(5, updatedItem.reviewStage + 1)
            
            // 设置下一次复习时间
            if updatedItem.reviewStage < 5, let interval = SettingsManager.shared.settings.reviewStrategy.intervals.dropFirst(updatedItem.reviewStage - 1).first {
                if let nextDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) {
                    updatedItem.nextReviewDate = nextDate
                }
            } else {
                // 已完成所有复习阶段
                updatedItem.nextReviewDate = nil
            }
        }
        
        updatedItem.lastReviewDate = Date()
        dataManager.updateMemoryItem(updatedItem)
        
        // 确保所有音频已停止后，再显示确认弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            print("【调试】updateMemoryProgress: 确保音频已停止，显示确认弹窗")
            self.shouldShowCompletionAlert = true
        }
    }
    
    /// 强制清理所有播放资源
    /// 用于在关键时刻（如显示确认弹窗前和确认按钮点击时）确保所有资源被彻底清理
    func forceClearAllPlaybackResources() {
        print("【调试】PlaybackControlViewModel.forceClearAllPlaybackResources 被调用")
        print("【调试详细】forceClearAllPlaybackResources: 当前状态 - isPlaying=\(isPlaying), isLoading=\(isLoading), 线程=\(Thread.isMainThread ? "主线程" : "后台线程")")
        
        // 强制停止并清理本地语音资源
        localVoiceManager.forceCleanup()
        
        // 强制停止并清理API语音资源
        apiVoiceManager.forceCleanup()
        
        // 重置ViewModel状态
        isPlaying = false
        isLoading = false
        progress = 0.0
        error = nil
        
        print("【调试详细】forceClearAllPlaybackResources: 完成 - 当前状态: isPlaying=\(isPlaying), isLoading=\(isLoading)")
    }
    
    /// 打开编辑页面
    func openEditPage() {
        shouldNavigateToEdit = true
    }
} 