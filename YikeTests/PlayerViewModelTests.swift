//
//  PlayerViewModelTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//

import XCTest
@testable import Yike

class PlayerViewModelTests: YikeBaseTests {
    
    // 测试用的记忆项目
    var testMemoryItem: MemoryItem!
    var testMemoryItems: [MemoryItem]!
    
    // 被测试的视图模型
    var viewModel: PlaybackControlViewModel!
    
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
            )
        ]
        
        // 初始化视图模型
        viewModel = PlaybackControlViewModel(memoryItem: testMemoryItem)
    }
    
    override func tearDown() {
        viewModel = nil
        testMemoryItem = nil
        testMemoryItems = nil
        super.tearDown()
    }
    
    // MARK: - 测试初始化
    
    func testInitWithSingleMemoryItem() {
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
    
    func testInitWithMultipleMemoryItems() {
        // 测试使用多个记忆项目初始化
        let vm = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 0)
        
        // 验证初始状态
        XCTAssertEqual(vm.memoryItems.count, 2)
        XCTAssertEqual(vm.currentItemIndex, 0)
        XCTAssertEqual(vm.currentMemoryItem.id, testMemoryItems[0].id)
        XCTAssertTrue(vm.enableItemNavigation)
        XCTAssertFalse(vm.isPlaying)
        XCTAssertEqual(vm.progress, 0.0)
    }
    
    func testInitWithInvalidIndex() {
        // 测试使用无效索引初始化
        let vm = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 5)
        
        // 验证初始状态 - 应该默认为第一个项目
        XCTAssertEqual(vm.currentItemIndex, 0)
        XCTAssertEqual(vm.currentMemoryItem.id, testMemoryItems[0].id)
    }
    
    // MARK: - 测试导航功能
    
    func testNavigateToNextItem() {
        // 使用多个记忆项目初始化
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 0)
        
        // 导航到下一个项目
        viewModel.navigateToNextItem()
        
        // 验证当前索引和项目已更新
        XCTAssertEqual(viewModel.currentItemIndex, 1)
        XCTAssertEqual(viewModel.currentMemoryItem.id, testMemoryItems[1].id)
    }
    
    func testNavigateToPreviousItem() {
        // 使用多个记忆项目初始化，从第二个开始
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 1)
        
        // 导航到上一个项目
        viewModel.navigateToPreviousItem()
        
        // 验证当前索引和项目已更新
        XCTAssertEqual(viewModel.currentItemIndex, 0)
        XCTAssertEqual(viewModel.currentMemoryItem.id, testMemoryItems[0].id)
    }
    
    func testNavigationBoundaries() {
        // 使用多个记忆项目初始化
        viewModel = PlaybackControlViewModel(memoryItems: testMemoryItems, initialIndex: 0)
        
        // 尝试导航到上一个项目（超出边界）
        viewModel.navigateToPreviousItem()
        
        // 验证索引没有变化
        XCTAssertEqual(viewModel.currentItemIndex, 0)
        
        // 导航到最后一个项目
        viewModel.navigateToNextItem()
        XCTAssertEqual(viewModel.currentItemIndex, 1)
        
        // 尝试导航到下一个项目（超出边界）
        viewModel.navigateToNextItem()
        
        // 验证索引没有变化
        XCTAssertEqual(viewModel.currentItemIndex, 1)
    }
    
    // MARK: - 测试播放控制
    
    func testSetSpeed() {
        // 设置播放速度
        viewModel.setSpeed(1.5)
        
        // 验证速度已更新
        XCTAssertEqual(viewModel.selectedSpeed, 1.5)
    }
    
    func testOpenEditPage() {
        // 初始状态
        XCTAssertFalse(viewModel.shouldNavigateToEdit)
        
        // 打开编辑页面
        viewModel.openEditPage()
        
        // 验证状态已更新
        XCTAssertTrue(viewModel.shouldNavigateToEdit)
    }
    
    // MARK: - 测试记忆进度更新
    
    func testUpdateMemoryProgressForNewItem() {
        // 确保测试项目是新的
        testMemoryItem = MemoryItem(
            id: UUID(),
            title: "新项目",
            content: "这是一个新的记忆项目",
            progress: 0.0,
            reviewStage: 0
        )
        
        viewModel = PlaybackControlViewModel(memoryItem: testMemoryItem)
        
        // 更新记忆进度
        viewModel.updateMemoryProgress()
        
        // 验证进度和复习阶段已更新
        XCTAssertEqual(viewModel.shouldShowCompletionAlert, true)
        
        // 注意：由于实际的数据更新是通过DataManager进行的，
        // 我们无法直接验证memoryItem的变化，除非我们模拟DataManager
    }
} 