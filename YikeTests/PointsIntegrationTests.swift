import XCTest
@testable import Yike

class PointsIntegrationTests: XCTestCase {
    
    // 测试前准备
    override func setUp() {
        super.setUp()
        
        // 设置模拟服务
        MockSiliconFlowTTSService.mockShared = MockSiliconFlowTTSService()
        
        // 使用方法交换（Method Swizzling）替换单例
        swizzleSiliconFlowTTSServiceShared()
        
        // 设置模拟数据管理器
        MockDataManager.mockShared = MockDataManager()
        
        // 使用方法交换替换单例
        swizzleDataManagerShared()
    }
    
    // 测试后清理
    override func tearDown() {
        // 恢复原始单例
        restoreSiliconFlowTTSServiceShared()
        restoreDataManagerShared()
        
        super.tearDown()
    }
    
    // MARK: - 集成测试
    
    /// 测试PlayerView中的积分消耗逻辑
    func testPlayerViewPointsConsumption() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        mockTTSService.cachedTexts = [:]
        
        // 确认初始缓存状态
        XCTAssertFalse(mockTTSService.isCached(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0), "文本在测试开始时不应该被缓存")
        
        // 模拟播放API语音
        func simulatePlayWithApiVoice() -> URL? {
            // 检查点数是否足够
            if mockDataManager.points < 5 {
                return nil
            }
            
            // 通过API生成语音
            var resultURL: URL? = nil
            let expectation = self.expectation(description: "API调用完成")
            
            mockTTSService.generateSpeech(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0) { audioURL, error in
                if error != nil {
                    expectation.fulfill()
                    return
                }
                
                // 确保audioURL不为nil
                guard let audioURL = audioURL else {
                    XCTFail("生成的音频URL不应为nil")
                    expectation.fulfill()
                    return
                }
                
                // 不再需要在这里调用deductPoints，因为MockSiliconFlowTTSService的generateSpeech方法已经会自动调用
                
                resultURL = audioURL
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0, handler: nil)
            
            return resultURL
        }
        
        let audioURL = simulatePlayWithApiVoice()
        
        // 确保audioURL不为nil，并且使用它
        guard let url = audioURL else {
            XCTFail("audioURL不应该为nil")
            return
        }
        
        // 验证URL是否有效
        XCTAssertTrue(url.absoluteString.count > 0, "URL应该是有效的")
        
        // 不再需要在这里调用deductPoints，因为MockSiliconFlowTTSService的generateSpeech方法已经会自动调用
        
        // 验证积分扣除后的状态
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 1, "应该调用一次积分扣除")
        XCTAssertEqual(mockDataManager.lastDeductedReason, "使用在线语音", "扣除原因应该是使用在线语音")
        XCTAssertEqual(mockDataManager.lastDeductedAmount, 5, "扣除金额应该是5积分")
        XCTAssertEqual(mockDataManager.points, 95, "积分余额应该是95")
    }
    
    /// 测试PlaySettingsView中的试听功能
    func testPlaySettingsViewPreviewFunction() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        
        // 模拟无缓存状态
        mockTTSService.cachedTexts = [:]
        
        // 模拟PlaySettingsView中的testApiVoice方法
        func simulateTestApiVoice() -> (success: Bool, error: String?) {
            var success = false
            var resultError: String? = nil
            
            let expectation = self.expectation(description: "API调用完成")
            
            // 调用API生成语音
            mockTTSService.generateSpeech(
                text: "这是一段示例文本，用于预览当前选择的语音效果。",
                voice: "标准男声",
                speed: 1.0
            ) { audioURL, error in
                if let error = error {
                    resultError = "试听失败: \(error.localizedDescription)"
                    expectation.fulfill()
                    return
                }
                
                guard let audioURL = audioURL else {
                    resultError = "试听失败: 未知错误"
                    expectation.fulfill()
                    return
                }
                
                // 试听功能设置为免费，不扣除积分
                // 这里不调用deductPoints
                
                success = true
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0, handler: nil)
            
            return (success, resultError)
        }
        
        // 执行测试
        let result = simulateTestApiVoice()
        
        // 验证结果
        XCTAssertTrue(result.success, "试听应该成功")
        XCTAssertNil(result.error, "试听不应该有错误")
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 100, "积分余额应该保持不变")
    }
    
    /// 测试积分不足时的错误处理
    func testInsufficientPointsErrorHandling() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 3 // 设置积分不足
        
        // 模拟无缓存状态
        mockTTSService.cachedTexts = [:]
        
        // 创建测试用的MemoryItem
        let testItem = MemoryItem(
            id: UUID(),
            title: "测试标题",
            content: "测试内容",
            progress: 0.0,
            reviewStage: 0,
            lastReviewDate: nil,
            nextReviewDate: nil
        )
        
        // 模拟PlayerView中的playWithApiVoice方法
        func simulatePlayWithApiVoice() -> (success: Bool, error: String?) {
            // 检查积分是否足够
            if mockDataManager.points < 5 {
                return (false, "积分不足，无法使用在线语音。当前积分: \(mockDataManager.points)")
            }
            
            // 如果积分足够，继续执行（这部分代码在积分不足时不会执行）
            let expectation = self.expectation(description: "API调用完成")
            
            mockTTSService.generateSpeech(
                text: testItem.content,
                voice: "标准男声",
                speed: 1.0
            ) { _, _ in
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0, handler: nil)
            
            return (true, nil)
        }
        
        // 执行测试
        let result = simulatePlayWithApiVoice()
        
        // 验证结果
        XCTAssertFalse(result.success, "积分不足时应该失败")
        XCTAssertNotNil(result.error, "积分不足时应该有错误信息")
        XCTAssertEqual(result.error, "积分不足，无法使用在线语音。当前积分: 3", "错误信息应该正确")
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 3, "积分余额应该保持不变")
        XCTAssertEqual(mockTTSService.generateSpeechCallCount, 0, "不应该调用生成语音方法")
    }
    
    // MARK: - 辅助方法
    
    /// 替换SiliconFlowTTSService的shared单例
    private func swizzleSiliconFlowTTSServiceShared() {
        let originalMethod = class_getClassMethod(SiliconFlowTTSService.self, #selector(getter: SiliconFlowTTSService.shared))!
        let swizzledMethod = class_getClassMethod(MockSiliconFlowTTSService.self, #selector(getter: MockSiliconFlowTTSService.mockShared))!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    /// 恢复SiliconFlowTTSService的shared单例
    private func restoreSiliconFlowTTSServiceShared() {
        let originalMethod = class_getClassMethod(SiliconFlowTTSService.self, #selector(getter: SiliconFlowTTSService.shared))!
        let swizzledMethod = class_getClassMethod(MockSiliconFlowTTSService.self, #selector(getter: MockSiliconFlowTTSService.mockShared))!
        method_exchangeImplementations(swizzledMethod, originalMethod)
    }
    
    /// 替换DataManager的shared单例
    private func swizzleDataManagerShared() {
        let originalMethod = class_getClassMethod(DataManager.self, #selector(getter: DataManager.shared))!
        let swizzledMethod = class_getClassMethod(MockDataManager.self, #selector(getter: MockDataManager.mockShared))!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    /// 恢复DataManager的shared单例
    private func restoreDataManagerShared() {
        let originalMethod = class_getClassMethod(DataManager.self, #selector(getter: DataManager.shared))!
        let swizzledMethod = class_getClassMethod(MockDataManager.self, #selector(getter: MockDataManager.mockShared))!
        method_exchangeImplementations(swizzledMethod, originalMethod)
    }
} 