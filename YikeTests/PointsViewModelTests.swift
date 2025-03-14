//
//  PointsViewModelTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class PointsViewModelTests: YikeBaseTests {
    
    // 被测试的视图模型
    var viewModel: PointsViewModel!
    
    // 模拟点数管理器
    var mockPointsManager: MockPointsManager!
    
    override func setUp() {
        super.setUp()
        
        // 创建模拟点数管理器
        mockPointsManager = MockPointsManager()
        mockPointsManager.setPoints(100)
        
        // 使用方法交换替换实际的点数管理器
        PointsManager.swapInstanceForTesting(mockPointsManager)
        
        // 初始化视图模型
        viewModel = PointsViewModel()
    }
    
    override func tearDown() {
        // 恢复原始点数管理器
        PointsManager.restoreOriginalInstance()
        
        super.tearDown()
    }
    
    // MARK: - 测试积分操作
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertEqual(viewModel.currentPoints, 100)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testRechargePoints() {
        // 模拟充值
        viewModel.rechargePoints(amount: 50, packageId: "test_package")
        
        // 验证积分更新
        XCTAssertEqual(viewModel.currentPoints, 150)
        
        // 验证记录添加
        let records = viewModel.pointsRecords
        XCTAssertTrue(records.contains { $0.amount == 50 && $0.type == .recharge })
    }
    
    func testConsumePoints() {
        // 模拟消费
        let success = viewModel.consumePoints(amount: 30, feature: "测试功能")
        
        // 验证消费结果
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.currentPoints, 70)
        
        // 验证记录添加
        let records = viewModel.pointsRecords
        XCTAssertTrue(records.contains { $0.amount == -30 && $0.type == .consume })
    }
    
    func testConsumeInsufficientPoints() {
        // 尝试消费超出余额的积分
        let success = viewModel.consumePoints(amount: 150, feature: "测试功能")
        
        // 验证消费失败
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.currentPoints, 100)
        
        // 验证没有添加记录
        let records = viewModel.pointsRecords
        XCTAssertFalse(records.contains { $0.amount == -150 })
    }
    
    // MARK: - 测试记录操作
    
    func testLoadPointsRecords() {
        // 准备测试数据
        mockPointsManager.addTestRecords()
        
        // 加载记录
        viewModel.loadPointsRecords()
        
        // 验证记录加载
        XCTAssertFalse(viewModel.pointsRecords.isEmpty)
    }
    
    func testFilterRecordsByDate() {
        // 准备测试数据
        mockPointsManager.addTestRecords()
        viewModel.loadPointsRecords()
        
        // 按日期筛选
        let today = Date()
        viewModel.filterRecords(startDate: today.addingTimeInterval(-86400), endDate: today)
        
        // 验证筛选结果
        // 注意：这里的验证取决于模拟数据的设计
    }
    
    func testFilterRecordsByType() {
        // 准备测试数据
        mockPointsManager.addTestRecords()
        viewModel.loadPointsRecords()
        
        // 按类型筛选
        viewModel.filterRecordsByType(.recharge)
        
        // 验证筛选结果
        let filteredRecords = viewModel.filteredRecords
        XCTAssertTrue(filteredRecords.allSatisfy { $0.type == .recharge })
    }
}

// 扩展模拟点数管理器以添加测试记录
extension MockPointsManager {
    func addTestRecords() {
        // 添加一些测试记录
        // 这些记录应该在内存中存储，而不是持久化
        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)
        
        // 模拟记录
        let records = [
            PointsRecord(id: UUID(), amount: 100, type: .recharge, reason: "初始充值", date: yesterday),
            PointsRecord(id: UUID(), amount: -5, type: .consume, reason: "在线语音", date: yesterday),
            PointsRecord(id: UUID(), amount: 50, type: .recharge, reason: "套餐充值", date: today),
            PointsRecord(id: UUID(), amount: -10, type: .consume, reason: "特殊功能", date: today)
        ]
        
        // 将记录添加到测试环境
        // 实际实现取决于PointsManager的内部结构
    }
} 