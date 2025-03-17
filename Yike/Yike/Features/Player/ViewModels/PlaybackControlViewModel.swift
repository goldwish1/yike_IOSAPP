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
        // 停止系统语音
        localVoiceManager.stop()
        
        // 停止API语音
        apiVoiceManager.stop()
    }
    
    /// 重置播放状态
    func resetPlaybackState() {
        localVoiceManager.reset()
        error = nil
    }
    
    /// 清理资源
    func cleanup() {
        stopPlayback()
        cancellables.removeAll()
    }
    
    /// 更新记忆进度
    func updateMemoryProgress() {
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
        shouldShowCompletionAlert = true
    }
    
    /// 打开编辑页面
    func openEditPage() {
        shouldNavigateToEdit = true
    }
} 