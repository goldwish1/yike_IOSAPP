import XCTest
import AVFoundation
@testable import Yike

class MockAVSpeechSynthesizerTests: XCTestCase {
    
    var mockSynthesizer: MockAVSpeechSynthesizer!
    var mockDelegate: MockSpeechSynthesizerDelegate!
    var testUtterance: AVSpeechUtterance!
    
    override func setUp() {
        super.setUp()
        mockSynthesizer = MockAVSpeechSynthesizer()
        mockDelegate = MockSpeechSynthesizerDelegate()
        mockSynthesizer.delegate = mockDelegate
        testUtterance = AVSpeechUtterance(string: "测试语音合成")
        
        // 设置较短的延迟以加快测试速度
        mockSynthesizer.synthesisDelay = 0.1
        
        // 重置静态错误
        MockAVSpeechSynthesizer.errorToThrow = nil
    }
    
    override func tearDown() {
        mockSynthesizer = nil
        mockDelegate = nil
        testUtterance = nil
        MockAVSpeechSynthesizer.errorToThrow = nil
        super.tearDown()
    }
    
    // MARK: - 基本功能测试
    
    func test_Init_CreatesEmptySynthesizer() {
        // 直接访问内部属性，避免记录操作
        XCTAssertFalse(mockSynthesizer.isSpeakingMock)
        XCTAssertFalse(mockSynthesizer.isPausedMock)
        XCTAssertEqual(mockSynthesizer.operations.count, 0)
    }
    
    func test_Reset_ClearsAllData() {
        // 准备 - 执行一些操作
        mockSynthesizer.speak(testUtterance)
        _ = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 执行
        mockSynthesizer.reset()
        
        // 验证
        XCTAssertEqual(mockSynthesizer.operations.count, 0)
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    // MARK: - 说话功能测试
    
    func test_Speak_RecordsOperationAndUpdatesState() {
        // 执行
        mockSynthesizer.speak(testUtterance)
        
        // 验证
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .speak))
        XCTAssertTrue(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_Speak_WithError_DoesNotUpdateState() {
        // 准备
        MockAVSpeechSynthesizer.errorToThrow = NSError(domain: "test", code: 123)
        
        // 执行
        mockSynthesizer.speak(testUtterance)
        
        // 验证
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .speak))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
    }
    
    func test_Speak_CallsDelegateDidStart() {
        // 执行
        mockSynthesizer.speak(testUtterance)
        
        // 验证
        XCTAssertTrue(mockDelegate.didStartCalled)
        XCTAssertEqual(mockDelegate.startedUtterance, testUtterance)
    }
    
    func test_Speak_CallsDelegateDidFinish() {
        // 准备
        let expectation = self.expectation(description: "Delegate didFinish should be called")
        mockDelegate.didFinishExpectation = expectation
        
        // 执行
        mockSynthesizer.speak(testUtterance)
        
        // 验证
        waitForExpectations(timeout: 0.5)
        XCTAssertTrue(mockDelegate.didFinishCalled)
        XCTAssertEqual(mockDelegate.finishedUtterance, testUtterance)
        XCTAssertFalse(mockSynthesizer.isSpeaking)
    }
    
    // MARK: - 暂停功能测试
    
    func test_PauseSpeaking_RecordsOperationAndUpdatesState() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        
        // 执行
        let result = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 验证
        XCTAssertTrue(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .pauseSpeaking))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertTrue(mockSynthesizer.isPaused)
    }
    
    func test_PauseSpeaking_WhenNotSpeaking_ReturnsFalse() {
        // 执行
        let result = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 验证
        XCTAssertFalse(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .pauseSpeaking))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_PauseSpeaking_CallsDelegateDidPause() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        
        // 执行
        _ = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 验证
        XCTAssertTrue(mockDelegate.didPauseCalled)
        XCTAssertEqual(mockDelegate.pausedUtterance, testUtterance)
    }
    
    // MARK: - 继续功能测试
    
    func test_ContinueSpeaking_RecordsOperationAndUpdatesState() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        _ = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 执行
        let result = mockSynthesizer.continueSpeaking()
        
        // 验证
        XCTAssertTrue(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .continueSpeaking))
        XCTAssertTrue(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_ContinueSpeaking_WhenNotPaused_ReturnsFalse() {
        // 执行
        let result = mockSynthesizer.continueSpeaking()
        
        // 验证
        XCTAssertFalse(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .continueSpeaking))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_ContinueSpeaking_CallsDelegateDidContinue() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        _ = mockSynthesizer.pauseSpeaking(at: .immediate)
        
        // 执行
        _ = mockSynthesizer.continueSpeaking()
        
        // 验证
        XCTAssertTrue(mockDelegate.didContinueCalled)
        XCTAssertEqual(mockDelegate.continuedUtterance, testUtterance)
    }
    
    // MARK: - 停止功能测试
    
    func test_StopSpeaking_RecordsOperationAndUpdatesState() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        
        // 执行
        let result = mockSynthesizer.stopSpeaking(at: .immediate)
        
        // 验证
        XCTAssertTrue(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .stopSpeaking))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_StopSpeaking_WhenNotSpeaking_ReturnsFalse() {
        // 执行
        let result = mockSynthesizer.stopSpeaking(at: .immediate)
        
        // 验证
        XCTAssertFalse(result)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .stopSpeaking))
        XCTAssertFalse(mockSynthesizer.isSpeaking)
        XCTAssertFalse(mockSynthesizer.isPaused)
    }
    
    func test_StopSpeaking_CallsDelegateDidCancel() {
        // 准备
        mockSynthesizer.speak(testUtterance)
        
        // 执行
        _ = mockSynthesizer.stopSpeaking(at: .immediate)
        
        // 验证
        XCTAssertTrue(mockDelegate.didCancelCalled)
        XCTAssertEqual(mockDelegate.canceledUtterance, testUtterance)
    }
    
    // MARK: - 状态查询测试
    
    func test_IsSpeaking_RecordsOperation() {
        // 执行
        _ = mockSynthesizer.isSpeaking
        
        // 验证
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .getIsSpeaking))
    }
    
    func test_IsPaused_RecordsOperation() {
        // 执行
        _ = mockSynthesizer.isPaused
        
        // 验证
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .getIsPaused))
    }
    
    // MARK: - 协议兼容性测试
    
    func test_ProtocolCompatibility_ConformsToAVSpeechSynthesizerProtocol() {
        // 验证
        XCTAssertTrue(mockSynthesizer is AVSpeechSynthesizerProtocol)
        
        // 测试协议方法
        let synthesizer: AVSpeechSynthesizerProtocol = mockSynthesizer
        XCTAssertFalse(synthesizer.isSpeaking)
        XCTAssertFalse(synthesizer.isPaused)
        
        // 测试协议方法调用
        synthesizer.speak(testUtterance)
        XCTAssertTrue(mockSynthesizer.hasOperation(ofType: .speak))
    }
}

// MARK: - 模拟 AVSpeechSynthesizerDelegate

class MockSpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    
    var didStartCalled = false
    var didFinishCalled = false
    var didPauseCalled = false
    var didContinueCalled = false
    var didCancelCalled = false
    
    var startedUtterance: AVSpeechUtterance?
    var finishedUtterance: AVSpeechUtterance?
    var pausedUtterance: AVSpeechUtterance?
    var continuedUtterance: AVSpeechUtterance?
    var canceledUtterance: AVSpeechUtterance?
    
    var didFinishExpectation: XCTestExpectation?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        didStartCalled = true
        startedUtterance = utterance
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinishCalled = true
        finishedUtterance = utterance
        didFinishExpectation?.fulfill()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        didPauseCalled = true
        pausedUtterance = utterance
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        didContinueCalled = true
        continuedUtterance = utterance
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        didCancelCalled = true
        canceledUtterance = utterance
    }
}
