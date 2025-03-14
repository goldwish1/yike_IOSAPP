//
//  PlaybackControlViewModelTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class PlaybackControlViewModelTests: YikeBaseTests {
    
    // 被测试的视图模型
    var viewModel: PlaybackControlViewModel!
    
    // 测试数据
    var testMemoryItem: MemoryItem!
    var testMemoryItems: [MemoryItem]!
    
    // 模拟播放管理器
    var mockLocalPlaybackManager: MockLocalVoicePlaybackManager!
    var mockApiPlaybackManager: MockApiVoicePlaybackManager!
    
    // 模拟数据管理器
    var mockDataManager: MockDataManager!
    
    override func setUp() {
        super.setUp()
        
        // 创建测试数据
        testMemoryItem = MemoryItem(
            id: UUID(),
            title: "测试标题",
            content: "这是一段测试内容，用于测试播放功能。",
            progress: 0.0,
            reviewStage: 0
        )
        
        testMemoryItems = [
            testMemoryItem,
            MemoryItem(
                id: UUID(),
                title: "测试标题2",
                content: "这是第二段测试内容。",
                progress: 0.0,
                reviewStage: 0
            ),
            MemoryItem(
                id: UUID(),
                title: "测试标题3",
                content: "这是第三段测试内容。",
                progress: 0.0,
                reviewStage: 0
            )
        ]
        
        // 创建模拟播放管理器
        mockLocalPlaybackManager = MockLocalVoicePlaybackManager()
        mockApiPlaybackManager = MockApiVoicePlaybackManager()
        
        // 替换实际的播放管理器
        LocalVoicePlaybackManager.swapInstanceForTesting(mockLocalPlaybackManager)
        ApiVoicePlaybackManager.swapInstanceForTesting(mockApiPlaybackManager)
        
        // 创建模拟数据管理器
        mockDataManager = MockDataManager()
        
        // 初始化被测试的视图模型
        viewModel = PlaybackControlViewModel(memoryItem: testMemoryItem, dataManager: mockDataManager)
    }
    
    override func tearDown() {
        // 恢复原始实例
        LocalVoicePlaybackManager.restoreOriginalInstance()
        ApiVoicePlaybackManager.restoreOriginalInstance()
        
        super.tearDown()
    }
    
    // MARK: - 测试初始化
    
    func testInitWithSingleItem() {
        // 测试使用单个记忆项目初始化
        let vm = PlaybackControlViewModel(memoryItem: testMemoryItem)
        
        // 验证初始状态
        XCTAssertEqual(vm.memoryItems.count, 1)
        XCTAssertEqual(vm.currentItemIndex, 0)
        XCTAssertEqual(vm.currentMemoryItem.id, testMemoryItem.id)
        XCTAssertFalse(vm.enableItemNavigation)
        XCTAssertFalse(vm.isPlaying)
        XCTAssertEqual(vm.progress, 0.0)
    }
    
    func testInitWithMultipleItems() {
        // 测试使用多个记忆项目初始化
        let vm = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 1)
        
        // 验证初始状态
        XCTAssertEqual(vm.memoryItems.count, 3)
        XCTAssertEqual(vm.currentItemIndex, 1)
        XCTAssertEqual(vm.currentMemoryItem.id, testMemoryItems[1].id)
        XCTAssertTrue(vm.enableItemNavigation)
        XCTAssertFalse(vm.isPlaying)
        XCTAssertEqual(vm.progress, 0.0)
    }
    
    // MARK: - 测试播放控制
    
    func testTogglePlayPause() {
        // 初始状态
        XCTAssertFalse(viewModel.isPlaying)
        
        // 设置默认使用本地播放
        mockLocalPlaybackManager.mockIsPlaying = false
        
        // 切换播放状态
        viewModel.togglePlayPause()
        
        // 验证播放状态
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertTrue(mockLocalPlaybackManager.togglePlayPauseCallCount > 0)
        
        // 再次切换播放状态
        mockLocalPlaybackManager.mockIsPlaying = true
        viewModel.togglePlayPause()
        
        // 验证暂停状态
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func testSetSpeed() {
        // 设置播放速度
        viewModel.setSpeed(1.5)
        
        // 验证速度已更新
        XCTAssertEqual(viewModel.selectedSpeed, 1.5)
        XCTAssertEqual(mockLocalPlaybackManager.setSpeedCallCount, 1)
        XCTAssertEqual(mockLocalPlaybackManager.lastSpeed, 1.5)
    }
    
    func testUseApiVoice() {
        // 测试使用在线语音
        
        // 设置使用API语音
        viewModel.useApiVoice = true
        
        // 切换播放状态
        viewModel.togglePlayPause()
        
        // 验证API播放管理器被调用
        XCTAssertTrue(mockApiPlaybackManager.togglePlayPauseCallCount > 0)
        XCTAssertEqual(mockLocalPlaybackManager.togglePlayPauseCallCount, 0)
    }
    
    // MARK: - 测试导航功能
    
    func testNavigateToNextItem() {
        // 使用多个记忆项目初始化
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 0)
        
        // 导航到下一个项目
        viewModel.navigateToNextItem()
        
        // 验证当前项目已更新
        XCTAssertEqual(viewModel.currentItemIndex, 1)
        XCTAssertEqual(viewModel.currentMemoryItem.id, testMemoryItems[1].id)
        
        // 如果正在播放，应停止
        mockLocalPlaybackManager.mockIsPlaying = true
        viewModel.navigateToNextItem()
        
        // 验证播放已停止并重新配置
        XCTAssertEqual(mockLocalPlaybackManager.stopCallCount, 1)
        XCTAssertEqual(viewModel.currentItemIndex, 2)
    }
    
    func testNavigateToPreviousItem() {
        // 使用多个记忆项目初始化，从中间项目开始
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 1)
        
        // 导航到上一个项目
        viewModel.navigateToPreviousItem()
        
        // 验证当前项目已更新
        XCTAssertEqual(viewModel.currentItemIndex, 0)
        XCTAssertEqual(viewModel.currentMemoryItem.id, testMemoryItems[0].id)
    }
    
    func testNavigationBoundaries() {
        // 使用多个记忆项目初始化，从第一个项目开始
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 0)
        
        // 尝试导航到前一个项目（超出边界）
        viewModel.navigateToPreviousItem()
        
        // 验证索引未改变
        XCTAssertEqual(viewModel.currentItemIndex, 0)
        
        // 导航到最后一个项目
        viewModel.navigateToNextItem() // 到索引1
        viewModel.navigateToNextItem() // 到索引2
        XCTAssertEqual(viewModel.currentItemIndex, 2)
        
        // 尝试导航到下一个项目（超出边界）
        viewModel.navigateToNextItem()
        
        // 验证索引未改变
        XCTAssertEqual(viewModel.currentItemIndex, 2)
    }
    
    // MARK: - 测试编辑功能
    
    func testOpenEditPage() {
        // 初始状态
        XCTAssertFalse(viewModel.shouldNavigateToEdit)
        
        // 打开编辑页面
        viewModel.openEditPage()
        
        // 验证状态已更新
        XCTAssertTrue(viewModel.shouldNavigateToEdit)
    }
    
    // MARK: - 测试学习进度更新
    
    func testUpdateMemoryProgress() {
        // 确保进度更新能被正确处理
        viewModel.updateMemoryProgress()
        
        // 验证进度更新并保存到数据管理器
        XCTAssertTrue(mockDataManager.updateMemoryItemCallCount > 0)
        
        // 验证完成提示
        XCTAssertTrue(viewModel.shouldShowCompletionAlert)
    }
    
    func testCompleteReviewStage() {
        // 设置学习中的项目
        let reviewingItem = MemoryItem(
            id: UUID(),
            title: "复习中的项目",
            content: "需要完成这个复习阶段",
            progress: 0.5,
            reviewStage: 2
        )
        
        // 使用该项目初始化视图模型
        viewModel = PlaybackControlViewModel(memoryItem: reviewingItem, dataManager: mockDataManager)
        
        // 完成当前复习阶段
        viewModel.updateMemoryProgress()
        
        // 验证复习阶段已更新
        XCTAssertEqual(mockDataManager.lastUpdatedStage, 3)
        XCTAssertNotNil(mockDataManager.lastUpdatedLastReviewedAt)
    }
}

// MARK: - 辅助类

/// 模拟本地语音播放管理器
class MockLocalVoicePlaybackManager: LocalVoicePlaybackManager {
    var mockIsPlaying: Bool = false
    var mockProgress: Double = 0.0
    var lastSpeed: Double = 1.0
    
    var prepareCallCount = 0
    var togglePlayPauseCallCount = 0
    var stopCallCount = 0
    var resetCallCount = 0
    var setSpeedCallCount = 0
    
    override var isPlaying: Bool {
        return mockIsPlaying
    }
    
    override var progress: Double {
        return mockProgress
    }
    
    override func prepare(text: String, speed: Double, intervalSeconds: Int) {
        prepareCallCount += 1
    }
    
    override func togglePlayPause(text: String, speed: Double, intervalSeconds: Int) {
        togglePlayPauseCallCount += 1
        mockIsPlaying = !mockIsPlaying
    }
    
    override func stop() {
        stopCallCount += 1
        mockIsPlaying = false
        mockProgress = 0.0
    }
    
    override func reset() {
        resetCallCount += 1
        mockIsPlaying = false
        mockProgress = 0.0
    }
    
    override func setSpeed(_ speed: Double) {
        setSpeedCallCount += 1
        lastSpeed = speed
    }
}

/// 模拟API语音播放管理器
class MockApiVoicePlaybackManager: ApiVoicePlaybackManager {
    var mockIsPlaying: Bool = false
    var mockIsLoading: Bool = false
    var mockProgress: Double = 0.0
    var lastSpeed: Double = 1.0
    
    var togglePlayPauseCallCount = 0
    var stopCallCount = 0
    var setSpeedCallCount = 0
    
    override var isPlaying: Bool {
        return mockIsPlaying
    }
    
    override var isLoading: Bool {
        return mockIsLoading
    }
    
    override var progress: Double {
        return mockProgress
    }
    
    override func togglePlayPause(text: String, voice: String, speed: Double) {
        togglePlayPauseCallCount += 1
        mockIsPlaying = !mockIsPlaying
    }
    
    override func stop() {
        stopCallCount += 1
        mockIsPlaying = false
        mockProgress = 0.0
    }
    
    override func setSpeed(_ speed: Double) {
        setSpeedCallCount += 1
        lastSpeed = speed
    }
}

/// 扩展模拟数据管理器以跟踪方法调用
extension MockDataManager {
    var updateMemoryItemCallCount = 0
    var lastUpdatedProgress: Double?
    var lastUpdatedStage: Int?
    var lastUpdatedLastReviewedAt: Date?
    
    override func updateMemoryItem(id: UUID, title: String? = nil, content: String? = nil, progress: Double? = nil, reviewStage: Int? = nil, lastReviewedAt: Date? = nil) -> Bool {
        updateMemoryItemCallCount += 1
        lastUpdatedProgress = progress
        lastUpdatedStage = reviewStage
        lastUpdatedLastReviewedAt = lastReviewedAt
        
        return super.updateMemoryItem(id: id, title: title, content: content, progress: progress, reviewStage: reviewStage, lastReviewedAt: lastReviewedAt)
    }
} 