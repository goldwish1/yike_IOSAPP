//
//  YikeTests.swift
//  YikeTests
//
//  Created by 冯元宙 on 2025/3/3.
//

import XCTest
@testable import Yike

/// 基础测试类，提供通用的测试环境设置
class YikeBaseTests: XCTestCase {
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        // 设置通用测试环境
        setupTestEnvironment()
    }
    
    override func tearDown() {
        // 清理测试环境
        cleanupTestEnvironment()
        super.tearDown()
    }
    
    // MARK: - 测试环境设置
    
    /// 设置测试环境
    func setupTestEnvironment() {
        // 重置用户默认设置
        resetUserDefaults()
        
        // 设置测试数据
        setupTestData()
        
        // 设置模拟服务
        setupMockServices()
    }
    
    /// 清理测试环境
    func cleanupTestEnvironment() {
        // 清理测试数据
        cleanupTestData()
        
        // 重置模拟服务
        resetMockServices()
    }
    
    // MARK: - 辅助方法
    
    /// 重置用户默认设置
    func resetUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    /// 设置测试数据
    func setupTestData() {
        // 子类可以重写此方法以设置特定的测试数据
    }
    
    /// 清理测试数据
    func cleanupTestData() {
        // 子类可以重写此方法以清理特定的测试数据
    }
    
    /// 设置模拟服务
    func setupMockServices() {
        // 子类可以重写此方法以设置特定的模拟服务
    }
    
    /// 重置模拟服务
    func resetMockServices() {
        // 子类可以重写此方法以重置特定的模拟服务
    }
}

/// 测试数据提供者
struct TestDataProvider {
    // 测试用户数据
    static let testUserName = "测试用户"
    static let testUserPoints = 100
    
    // 测试记忆项目数据
    static let testMemoryItems = [
        MemoryItem(id: UUID(), title: "测试项目1", content: "这是测试内容1", progress: 0.0, reviewStage: 0),
        MemoryItem(id: UUID(), title: "测试项目2", content: "这是测试内容2", progress: 0.0, reviewStage: 0)
    ]
    
    // 测试音频数据
    static let testAudioURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
}

/// 示例测试类
class ExampleTests: YikeBaseTests {
    
    override func setupTestData() {
        super.setupTestData()
        // 设置特定的测试数据
    }
    
    func testExample() {
        // 示例测试
        XCTAssertTrue(true, "这是一个通过的测试")
    }
}
