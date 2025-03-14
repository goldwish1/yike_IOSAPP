//
//  ModelsTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class ModelsTests: YikeBaseTests {
    
    // MARK: - MemoryItem 测试
    
    func testMemoryItemInitialization() {
        // 测试基本初始化
        let id = UUID()
        let title = "测试标题"
        let content = "测试内容"
        let progress = 0.5
        let reviewStage = 2
        
        let item = MemoryItem(id: id, title: title, content: content, progress: progress, reviewStage: reviewStage)
        
        // 验证属性
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.title, title)
        XCTAssertEqual(item.content, content)
        XCTAssertEqual(item.progress, progress)
        XCTAssertEqual(item.reviewStage, reviewStage)
        
        // 验证默认日期
        XCTAssertNotNil(item.createdAt)
        XCTAssertNil(item.lastReviewedAt)
    }
    
    func testMemoryItemWithDates() {
        // 测试带日期的初始化
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        let item = MemoryItem(
            id: UUID(), 
            title: "测试", 
            content: "内容", 
            progress: 0.0, 
            reviewStage: 0,
            createdAt: yesterday,
            lastReviewedAt: now
        )
        
        // 验证日期
        XCTAssertEqual(item.createdAt, yesterday)
        XCTAssertEqual(item.lastReviewedAt, now)
    }
    
    func testMemoryItemEquality() {
        // 测试相等性
        let id = UUID()
        let item1 = MemoryItem(id: id, title: "测试", content: "内容", progress: 0.0, reviewStage: 0)
        let item2 = MemoryItem(id: id, title: "不同标题", content: "不同内容", progress: 1.0, reviewStage: 5)
        
        // 验证UUID相同的项目被视为相等
        XCTAssertEqual(item1, item2)
        
        // 验证UUID不同的项目不相等
        let item3 = MemoryItem(id: UUID(), title: "测试", content: "内容", progress: 0.0, reviewStage: 0)
        XCTAssertNotEqual(item1, item3)
    }
    
    // MARK: - PointsRecord 测试
    
    func testPointsRecordInitialization() {
        // 测试基本初始化
        let id = UUID()
        let amount = 100
        let type = PointsRecordType.recharge
        let reason = "测试充值"
        let date = Date()
        
        let record = PointsRecord(id: id, amount: amount, type: type, reason: reason, date: date)
        
        // 验证属性
        XCTAssertEqual(record.id, id)
        XCTAssertEqual(record.amount, amount)
        XCTAssertEqual(record.type, type)
        XCTAssertEqual(record.reason, reason)
        XCTAssertEqual(record.date, date)
    }
    
    func testPointsRecordDefaultDate() {
        // 测试默认日期
        let record = PointsRecord(id: UUID(), amount: 50, type: .recharge, reason: "测试")
        
        // 验证默认日期接近当前时间
        let timeDifference = Date().timeIntervalSince(record.date)
        XCTAssertLessThan(abs(timeDifference), 1.0) // 不超过1秒
    }
    
    func testPointsRecordEquality() {
        // 测试相等性
        let id = UUID()
        let record1 = PointsRecord(id: id, amount: 100, type: .recharge, reason: "测试1")
        let record2 = PointsRecord(id: id, amount: 50, type: .consume, reason: "测试2")
        
        // 验证UUID相同的记录被视为相等
        XCTAssertEqual(record1, record2)
        
        // 验证UUID不同的记录不相等
        let record3 = PointsRecord(id: UUID(), amount: 100, type: .recharge, reason: "测试1")
        XCTAssertNotEqual(record1, record3)
    }
    
    func testPointsRecordTypeDescription() {
        // 测试记录类型描述
        XCTAssertEqual(PointsRecordType.recharge.description, "充值")
        XCTAssertEqual(PointsRecordType.consume.description, "消费")
        XCTAssertEqual(PointsRecordType.system.description, "系统")
    }
} 