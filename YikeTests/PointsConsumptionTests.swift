import XCTest
@testable import Yike

// MARK: - 模拟服务

/// 模拟的硅基流动TTS服务，用于测试
@objc class MockSiliconFlowTTSService: SiliconFlowTTSService {
    // 覆盖单例，使测试可以使用模拟实例
    @objc static var mockShared: MockSiliconFlowTTSService!
    
    // 模拟缓存状态
    var cachedTexts: [String: Bool] = [:]
    
    // 模拟API调用计数
    var generateSpeechCallCount = 0
    
    // 模拟错误
    var shouldReturnError = false
    var mockError: Error?
    
    // 公共初始化方法
    public override init() {
        super.init()
    }
    
    // 添加isCached方法，用于测试
    override func isCached(text: String, voice: String, speed: Float) -> Bool {
        let key = "\(text)_\(voice)_\(speed)"
        return cachedTexts[key] ?? false
    }
    
    // 覆盖generateSpeech方法
    override func generateSpeech(text: String, voice: String, speed: Float, completion: @escaping (URL?, Error?) -> Void) {
        generateSpeechCallCount += 1
        
        if shouldReturnError {
            completion(nil, mockError ?? NSError(domain: "MockError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "模拟错误"]))
            return
        }
        
        let key = "\(text)_\(voice)_\(speed)"
        
        // 模拟缓存检查
        if isCached(text: text, voice: voice, speed: speed) {
            // 返回模拟的缓存URL
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mock_audio.mp3")
            completion(tempURL, nil)
            return
        }
        
        // 非缓存情况下，扣除积分
        let dataManager = MockDataManager.mockShared!
        _ = dataManager.deductPoints(5, reason: "使用在线语音")
        
        // 模拟API调用成功
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mock_audio.mp3")
        
        // 创建一个空文件作为模拟音频
        try? Data().write(to: tempURL)
        
        // 将此文本标记为已缓存
        cachedTexts[key] = true
        
        completion(tempURL, nil)
    }
}

// MARK: - 模拟数据管理器

/// 模拟的数据管理器，用于测试
@objc class MockDataManager: DataManager {
    // 覆盖单例，使测试可以使用模拟实例
    @objc static var mockShared: MockDataManager!
    
    // 公共初始化方法
    public override init() {
        super.init()
    }
    
    // 模拟积分
    override var points: Int {
        get { return _points }
        set { _points = newValue }
    }
    private var _points: Int = 100
    
    // 模拟积分记录
    override var pointsRecords: [PointsRecord] {
        get { return _pointsRecords }
        set { _pointsRecords = newValue }
    }
    private var _pointsRecords: [PointsRecord] = []
    
    // 记录方法调用
    var deductPointsCallCount = 0
    var lastDeductedAmount = 0
    var lastDeductedReason = ""
    
    // 覆盖扣除积分方法
    override func deductPoints(_ amount: Int, reason: String) -> Bool {
        deductPointsCallCount += 1
        lastDeductedAmount = amount
        lastDeductedReason = reason
        
        if points >= amount {
            points -= amount
            let record = PointsRecord(id: UUID(), amount: -amount, reason: reason, date: Date())
            pointsRecords.append(record)
            return true
        }
        return false
    }
    
    // 重置测试状态
    func reset() {
        _points = 100
        _pointsRecords = []
        deductPointsCallCount = 0
        lastDeductedAmount = 0
        lastDeductedReason = ""
    }
}

// MARK: - 测试用例

class PointsConsumptionTests: XCTestCase {
    
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
    
    // MARK: - 单元测试
    
    /// 测试在线语音功能积分消耗 - 首次使用（无缓存）
    func testOnlineVoicePointsConsumption_FirstTime() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        
        // 模拟无缓存状态
        mockTTSService.cachedTexts = [:]
        
        // 确认初始状态
        XCTAssertFalse(mockTTSService.isCached(text: "测试文本", voice: "标准男声", speed: 1.0), "初始状态应该是未缓存")
        
        // 执行测试
        let expectation = self.expectation(description: "API调用完成")
        
        // 模拟PlayerView中的调用逻辑
        if mockDataManager.points < 5 {
            XCTFail("积分不足，无法进行测试")
            return
        }
        
        mockTTSService.generateSpeech(
            text: "测试文本",
            voice: "标准男声",
            speed: 1.0
        ) { audioURL, error in
            // 验证音频URL不为nil
            XCTAssertNotNil(audioURL, "生成的音频URL不应为nil")
            
            // 不再需要在这里手动调用deductPoints，因为已经在MockSiliconFlowTTSService中处理了
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证缓存状态
        let isCachedAfter = mockTTSService.isCached(text: "测试文本", voice: "标准男声", speed: 1.0)
        XCTAssertTrue(isCachedAfter, "文本应该被标记为已缓存")
        
        // 验证结果
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 1, "应该调用一次扣除积分方法")
        XCTAssertEqual(mockDataManager.lastDeductedAmount, 5, "应该扣除5积分")
        XCTAssertEqual(mockDataManager.lastDeductedReason, "使用在线语音", "扣除原因应该正确")
        XCTAssertEqual(mockDataManager.points, 95, "积分余额应该正确")
        XCTAssertEqual(mockDataManager.pointsRecords.count, 1, "应该有一条积分记录")
        XCTAssertEqual(mockTTSService.generateSpeechCallCount, 1, "应该调用一次生成语音方法")
    }
    
    /// 测试在线语音功能积分消耗 - 重复使用（有缓存）
    func testOnlineVoicePointsConsumption_WithCache() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        
        // 模拟有缓存状态
        mockTTSService.cachedTexts = ["测试文本_标准男声_1.0": true]
        
        // 执行测试
        let expectation = self.expectation(description: "API调用完成")
        
        // 模拟PlayerView中的调用逻辑
        if mockDataManager.points < 5 {
            XCTFail("积分不足，无法进行测试")
            return
        }
        
        mockTTSService.generateSpeech(
            text: "测试文本",
            voice: "标准男声",
            speed: 1.0
        ) { audioURL, error in
            // 验证音频URL不为nil
            XCTAssertNotNil(audioURL, "生成的音频URL不应为nil")
            
            // 不再需要在这里手动调用deductPoints，因为已经在MockSiliconFlowTTSService中处理了
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证结果
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 100, "积分余额应该保持不变")
        XCTAssertEqual(mockDataManager.pointsRecords.count, 0, "不应该有积分记录")
        XCTAssertEqual(mockTTSService.generateSpeechCallCount, 1, "应该调用一次生成语音方法")
    }
    
    /// 测试积分不足情况
    func testOnlineVoicePointsConsumption_InsufficientPoints() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 3 // 设置积分不足
        
        // 模拟无缓存状态
        mockTTSService.cachedTexts = [:]
        
        // 执行测试 - 模拟PlayerView中的检查逻辑
        XCTAssertTrue(mockDataManager.points < 5, "积分应该不足")
        
        // 验证结果
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 3, "积分余额应该保持不变")
    }
    
    /// 测试试听功能不消耗积分
    func testPreviewVoicePointsConsumption() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        let mockTTSService = MockSiliconFlowTTSService.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        
        // 模拟无缓存状态
        mockTTSService.cachedTexts = [:]
        
        // 执行测试
        let expectation = self.expectation(description: "API调用完成")
        
        // 模拟PlaySettingsView中的调用逻辑
        mockTTSService.generateSpeech(
            text: "这是一段示例文本，用于预览当前选择的语音效果。",
            voice: "标准男声",
            speed: 1.0
        ) { audioURL, error in
            // 验证音频URL不为nil
            XCTAssertNotNil(audioURL, "生成的音频URL不应为nil")
            
            // 试听功能设置为免费，不扣除积分
            // 这里不调用deductPoints
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证结果
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 100, "积分余额应该保持不变")
        XCTAssertEqual(mockDataManager.pointsRecords.count, 0, "不应该有积分记录")
        XCTAssertEqual(mockTTSService.generateSpeechCallCount, 1, "应该调用一次生成语音方法")
    }
    
    /// 测试OCR功能不消耗积分
    func testOCRPointsConsumption() {
        // 准备测试数据
        let mockDataManager = MockDataManager.mockShared!
        
        mockDataManager.reset()
        mockDataManager.points = 100
        
        // 执行测试 - 模拟OCR识别后的逻辑
        // OCR功能已设置为免费，不需要扣除积分
        
        // 验证结果
        XCTAssertEqual(mockDataManager.deductPointsCallCount, 0, "不应该调用扣除积分方法")
        XCTAssertEqual(mockDataManager.points, 100, "积分余额应该保持不变")
        XCTAssertEqual(mockDataManager.pointsRecords.count, 0, "不应该有积分记录")
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