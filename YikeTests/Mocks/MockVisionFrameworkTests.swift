import XCTest
import Vision
@testable import Yike

class MockVisionFrameworkTests: YikeBaseTests {
    
    // MARK: - 属性
    
    var mockVision: MockVisionFramework!
    var testImageData: Data!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        mockVision = MockVisionFramework()
        testImageData = Data(repeating: 0, count: 100) // 模拟图像数据
    }
    
    override func tearDown() {
        mockVision = nil
        testImageData = nil
        MockVisionFramework.errorToThrow = nil
        super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func test_Init_CreatesEmptyVisionFramework() {
        XCTAssertEqual(mockVision.operations.count, 0)
    }
    
    // MARK: - 文本识别请求测试
    
    func test_CreateTextRecognitionRequest_RecordsOperation() {
        // 创建请求
        let _ = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in }
        
        // 验证操作记录
        XCTAssertEqual(mockVision.operations.count, 1)
        XCTAssertTrue(mockVision.hasOperation(ofType: .createTextRecognitionRequest))
        XCTAssertEqual(mockVision.operationCount(ofType: .createTextRecognitionRequest), 1)
    }
    
    func test_CreateTextRecognitionRequest_ReturnsRequest() {
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in }
        
        // 验证请求类型
        XCTAssertTrue(request is MockVNRecognizeTextRequest)
    }
    
    // MARK: - 执行请求测试
    
    func test_PerformRequests_RecordsOperation() throws {
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in }
        
        // 执行请求
        try mockVision.perform([request], on: testImageData, orientation: .up)
        
        // 验证操作记录
        XCTAssertEqual(mockVision.operations.count, 2)
        XCTAssertTrue(mockVision.hasOperation(ofType: .performRequests))
        XCTAssertEqual(mockVision.operationCount(ofType: .performRequests), 1)
    }
    
    func test_PerformRequests_CallsCompletionHandler() {
        // 创建期望
        let expectation = self.expectation(description: "Completion handler called")
        
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in
            expectation.fulfill()
        }
        
        // 执行请求
        XCTAssertNoThrow(try mockVision.perform([request], on: testImageData, orientation: .up))
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_PerformRequests_WithError_ThrowsError() {
        // 设置错误
        struct TestError: Error {}
        MockVisionFramework.errorToThrow = TestError()
        
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in }
        
        // 执行请求，应该抛出错误
        XCTAssertThrowsError(try mockVision.perform([request], on: testImageData, orientation: .up))
    }
    
    // MARK: - 结果测试
    
    func test_RecognitionResults_ReturnsConfiguredResults() {
        // 创建期望
        let expectation = self.expectation(description: "Results returned")
        
        // 创建模拟结果
        let testObservation = MockVisionFramework.createTextObservation(text: "测试文本")
        mockVision.setRecognitionResult(for: "testImage", observations: [testObservation])
        
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { request, _ in
            // 验证结果
            XCTAssertEqual(request.results?.count, 1)
            if let textObservation = request.results?.first as? VNRecognizedTextObservation,
               let recognizedText = textObservation.topCandidates(1).first {
                XCTAssertEqual(recognizedText.string, "测试文本")
                expectation.fulfill()
            } else {
                XCTFail("无法获取识别结果")
            }
        }
        
        // 执行请求
        XCTAssertNoThrow(try mockVision.perform([request], on: testImageData, orientation: .up))
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_DefaultRecognitionResults_ReturnsDefaultResults() {
        // 创建期望
        let expectation = self.expectation(description: "Default results returned")
        
        // 创建默认模拟结果
        let defaultObservation = MockVisionFramework.createTextObservation(text: "默认文本")
        mockVision.setDefaultRecognitionResult([defaultObservation])
        
        // 创建请求（没有为此图像设置特定结果）
        let request = mockVision.createTextRecognitionRequest(for: "unknownImage") { request, _ in
            // 验证结果
            XCTAssertEqual(request.results?.count, 1)
            if let textObservation = request.results?.first as? VNRecognizedTextObservation,
               let recognizedText = textObservation.topCandidates(1).first {
                XCTAssertEqual(recognizedText.string, "默认文本")
                expectation.fulfill()
            } else {
                XCTFail("无法获取识别结果")
            }
        }
        
        // 执行请求
        XCTAssertNoThrow(try mockVision.perform([request], on: testImageData, orientation: .up))
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - 错误处理测试
    
    func test_CompletionHandler_WithError_PassesError() {
        // 创建期望
        let expectation = self.expectation(description: "Error passed to completion handler")
        
        // 设置错误
        struct TestError: Error {}
        MockVisionFramework.errorToThrow = TestError()
        
        // 创建请求
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error is TestError)
            expectation.fulfill()
        }
        
        // 执行请求
        XCTAssertThrowsError(try mockVision.perform([request], on: testImageData, orientation: .up))
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - 重置测试
    
    func test_Reset_ClearsOperations() {
        // 创建请求并执行
        let request = mockVision.createTextRecognitionRequest(for: "testImage") { _, _ in }
        XCTAssertNoThrow(try mockVision.perform([request], on: testImageData, orientation: .up))
        
        // 验证操作记录
        XCTAssertEqual(mockVision.operations.count, 2)
        
        // 重置
        mockVision.reset()
        
        // 验证操作记录已清除
        XCTAssertEqual(mockVision.operations.count, 0)
    }
    
    // MARK: - 辅助方法测试
    
    func test_CreateTextObservation_CreatesObservationWithText() {
        // 创建观察结果
        let observation = MockVisionFramework.createTextObservation(text: "测试文本", confidence: 0.95)
        
        // 验证文本和置信度
        if let recognizedText = observation.topCandidates(1).first {
            XCTAssertEqual(recognizedText.string, "测试文本")
            XCTAssertEqual(recognizedText.confidence, 0.95)
        } else {
            XCTFail("无法获取识别结果")
        }
    }
}
