//
//  SiliconFlowTTSServiceTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class SiliconFlowTTSServiceTests: YikeBaseTests {
    
    // 被测试的服务
    var ttsService: SiliconFlowTTSService!
    
    // 模拟点数管理器
    var mockPointsManager: MockPointsManager!
    
    override func setUp() {
        super.setUp()
        
        // 创建模拟点数管理器
        mockPointsManager = MockPointsManager()
        
        // 使用方法交换替换实际的点数管理器
        PointsManager.swapInstanceForTesting(mockPointsManager)
        
        // 获取服务实例
        ttsService = SiliconFlowTTSService.shared
    }
    
    override func tearDown() {
        // 恢复原始点数管理器
        PointsManager.restoreOriginalInstance()
        
        super.tearDown()
    }
    
    // MARK: - 测试基本功能
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertFalse(ttsService.isProcessing)
        XCTAssertNil(ttsService.error)
    }
    
    // MARK: - 测试语音合成
    
    func testSynthesizeWithValidText() {
        // 设置初始点数
        mockPointsManager.setPoints(100)
        
        // 设置期望
        let expectation = self.expectation(description: "语音合成完成")
        
        // 执行语音合成
        ttsService.synthesize(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", previewMode: false) { result in
            switch result {
            case .success(let url):
                // 验证结果
                XCTAssertNotNil(url)
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                
                // 验证点数扣除
                XCTAssertEqual(self.mockPointsManager.points, 95) // 扣除5点
                
            case .failure(let error):
                XCTFail("语音合成应该成功，但失败: \(error)")
            }
            
            expectation.fulfill()
        }
        
        // 等待异步操作完成
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSynthesizeInPreviewMode() {
        // 设置初始点数
        mockPointsManager.setPoints(100)
        
        // 设置期望
        let expectation = self.expectation(description: "预览模式语音合成完成")
        
        // 执行预览模式语音合成
        ttsService.synthesize(text: "预览测试", voice: "zh-CN-XiaoxiaoNeural", previewMode: true) { result in
            switch result {
            case .success(let url):
                // 验证结果
                XCTAssertNotNil(url)
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                
                // 验证点数未扣除（预览模式免费）
                XCTAssertEqual(self.mockPointsManager.points, 100)
                
            case .failure(let error):
                XCTFail("预览模式语音合成应该成功，但失败: \(error)")
            }
            
            expectation.fulfill()
        }
        
        // 等待异步操作完成
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSynthesizeWithInsufficientPoints() {
        // 设置点数不足
        mockPointsManager.setPoints(3)
        
        // 设置期望
        let expectation = self.expectation(description: "点数不足测试完成")
        
        // 执行语音合成
        ttsService.synthesize(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", previewMode: false) { result in
            switch result {
            case .success(_):
                XCTFail("点数不足时语音合成应该失败")
                
            case .failure(let error):
                // 验证错误类型
                if case TTSError.insufficientPoints = error {
                    // 验证点数未变化
                    XCTAssertEqual(self.mockPointsManager.points, 3)
                } else {
                    XCTFail("应该是点数不足错误，但收到: \(error)")
                }
            }
            
            expectation.fulfill()
        }
        
        // 等待异步操作完成
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // MARK: - 测试缓存功能
    
    func testCacheHitDoesNotConsumePoints() {
        // 设置初始点数
        mockPointsManager.setPoints(100)
        
        // 设置期望
        let expectation1 = self.expectation(description: "第一次语音合成完成")
        let expectation2 = self.expectation(description: "第二次语音合成完成")
        
        // 第一次合成，消耗点数
        ttsService.synthesize(text: "缓存测试", voice: "zh-CN-XiaoxiaoNeural", previewMode: false) { _ in
            expectation1.fulfill()
            
            // 第二次合成相同内容，应该命中缓存
            self.ttsService.synthesize(text: "缓存测试", voice: "zh-CN-XiaoxiaoNeural", previewMode: false) { _ in
                // 验证点数只扣除一次
                XCTAssertEqual(self.mockPointsManager.points, 95) // 只扣除5点
                expectation2.fulfill()
            }
        }
        
        // 等待异步操作完成
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    // MARK: - 测试错误处理
    
    func testNetworkError() {
        // 此测试需要模拟网络错误，可以使用URL Session模拟
    }
}

// MARK: - 辅助类

/// 模拟点数管理器
class MockPointsManager: PointsManager {
    var points: Int = 0
    
    func setPoints(_ value: Int) {
        points = value
    }
    
    override func getCurrentPoints() -> Int {
        return points
    }
    
    override func consumePoints(_ amount: Int, for reason: String) -> Bool {
        if points >= amount {
            points -= amount
            return true
        }
        return false
    }
    
    override func addPoints(_ amount: Int, for reason: String) {
        points += amount
    }
} 