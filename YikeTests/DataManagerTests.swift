//
//  DataManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class DataManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        
        // 创建测试用的数据管理器实例
        // 注意：在实际测试中应该使用内存存储而不是持久化存储
        dataManager = DataManager.createForTesting()
    }
    
    override func tearDown() {
        // 清理测试数据
        dataManager.deleteAllData()
        
        super.tearDown()
    }
    
    // MARK: - 测试记忆项目CRUD操作
    
    func testCreateMemoryItem() {
        // 创建测试数据
        let title = "测试标题"
        let content = "这是测试内容"
        
        // 创建记忆项目
        let item = dataManager.createMemoryItem(title: title, content: content)
        
        // 验证创建结果
        XCTAssertNotNil(item)
        XCTAssertEqual(item.title, title)
        XCTAssertEqual(item.content, content)
        XCTAssertEqual(item.progress, 0.0)
        XCTAssertEqual(item.reviewStage, 0)
        
        // 验证记忆项目已保存到数据库
        let savedItems = dataManager.getAllMemoryItems()
        XCTAssertEqual(savedItems.count, 1)
        XCTAssertEqual(savedItems.first?.id, item.id)
    }
    
    func testGetMemoryItem() {
        // 创建测试数据
        let item = dataManager.createMemoryItem(title: "测试标题", content: "这是测试内容")
        
        // 获取记忆项目
        let retrievedItem = dataManager.getMemoryItem(id: item.id)
        
        // 验证获取结果
        XCTAssertNotNil(retrievedItem)
        XCTAssertEqual(retrievedItem?.id, item.id)
        XCTAssertEqual(retrievedItem?.title, item.title)
        XCTAssertEqual(retrievedItem?.content, item.content)
    }
    
    func testUpdateMemoryItem() {
        // 创建测试数据
        let item = dataManager.createMemoryItem(title: "原标题", content: "原内容")
        
        // 更新记忆项目
        let updated = dataManager.updateMemoryItem(id: item.id, title: "新标题", content: "新内容", progress: 0.5, reviewStage: 1)
        
        // 验证更新结果
        XCTAssertTrue(updated)
        
        // 获取更新后的记忆项目
        let retrievedItem = dataManager.getMemoryItem(id: item.id)
        
        // 验证更新后的数据
        XCTAssertNotNil(retrievedItem)
        XCTAssertEqual(retrievedItem?.title, "新标题")
        XCTAssertEqual(retrievedItem?.content, "新内容")
        XCTAssertEqual(retrievedItem?.progress, 0.5)
        XCTAssertEqual(retrievedItem?.reviewStage, 1)
    }
    
    func testDeleteMemoryItem() {
        // 创建测试数据
        let item = dataManager.createMemoryItem(title: "测试标题", content: "这是测试内容")
        
        // 验证创建成功
        XCTAssertEqual(dataManager.getAllMemoryItems().count, 1)
        
        // 删除记忆项目
        let deleted = dataManager.deleteMemoryItem(id: item.id)
        
        // 验证删除结果
        XCTAssertTrue(deleted)
        XCTAssertEqual(dataManager.getAllMemoryItems().count, 0)
    }
    
    // MARK: - 测试数据一致性
    
    func testDataConsistency() {
        // 创建多个记忆项目
        let item1 = dataManager.createMemoryItem(title: "项目1", content: "内容1")
        let item2 = dataManager.createMemoryItem(title: "项目2", content: "内容2")
        let item3 = dataManager.createMemoryItem(title: "项目3", content: "内容3")
        
        // 获取所有记忆项目
        let allItems = dataManager.getAllMemoryItems()
        
        // 验证数据一致性
        XCTAssertEqual(allItems.count, 3)
        XCTAssertTrue(allItems.contains { $0.id == item1.id })
        XCTAssertTrue(allItems.contains { $0.id == item2.id })
        XCTAssertTrue(allItems.contains { $0.id == item3.id })
    }
    
    // MARK: - 测试并发操作
    
    func testConcurrentOperations() {
        // 测试并发操作的安全性
        // 注意：这是一个更复杂的测试，可能需要使用DispatchGroup或类似机制
        let expectation = self.expectation(description: "并发操作完成")
        let operationCount = 100
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<operationCount {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let item = self.dataManager.createMemoryItem(title: "并发测试\(i)", content: "内容\(i)")
                XCTAssertNotNil(item)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let allItems = self.dataManager.getAllMemoryItems()
            XCTAssertEqual(allItems.count, operationCount)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
} 