import XCTest
import AVFoundation
@testable import Yike

class MockAVAudioPlayerTests: XCTestCase {
    
    var mockPlayer: MockAVAudioPlayer!
    var testData: Data!
    
    override func setUp() {
        super.setUp()
        // 创建一个简单的测试音频数据
        testData = Data([0, 1, 2, 3, 4, 5])
        
        // 重置静态错误
        MockAVAudioPlayer.errorToThrow = nil
        
        // 创建模拟播放器
        do {
            mockPlayer = try MockAVAudioPlayer(data: testData, fileTypeHint: nil)
        } catch {
            XCTFail("Failed to create MockAVAudioPlayer: \(error)")
        }
    }
    
    override func tearDown() {
        mockPlayer = nil
        testData = nil
        MockAVAudioPlayer.errorToThrow = nil
        super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func test_InitWithData_RecordsOperation() {
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .initWithData))
        XCTAssertEqual(mockPlayer.operationCount(ofType: .initWithData), 1)
    }
    
    func test_InitWithURL_RecordsOperation() throws {
        // 准备
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.mp3")
        
        // 执行
        let player = try MockAVAudioPlayer(contentsOf: url, fileTypeHint: nil)
        
        // 验证
        XCTAssertTrue(player.hasOperation(ofType: .initWithURL))
        XCTAssertEqual(player.operationCount(ofType: .initWithURL), 1)
    }
    
    func test_InitWithError_ThrowsError() {
        // 准备
        let testError = NSError(domain: "test", code: 123)
        MockAVAudioPlayer.errorToThrow = testError
        
        // 执行 & 验证
        XCTAssertThrowsError(try MockAVAudioPlayer(data: testData, fileTypeHint: nil)) { error in
            XCTAssertEqual((error as NSError).domain, testError.domain)
            XCTAssertEqual((error as NSError).code, testError.code)
        }
    }
    
    // MARK: - 重置测试
    
    func test_Reset_ClearsAllData() {
        // 准备 - 执行一些操作
        _ = mockPlayer.play()
        mockPlayer.volume = 0.5
        mockPlayer.currentTime = 10
        
        // 执行
        mockPlayer.reset()
        
        // 验证
        XCTAssertEqual(mockPlayer.operations.count, 0)
        XCTAssertFalse(mockPlayer.isPlaying)
        XCTAssertEqual(mockPlayer.currentTime, 0)
        XCTAssertEqual(mockPlayer.volume, 1.0)
    }
    
    // MARK: - 播放控制测试
    
    func test_PrepareToPlay_RecordsOperation() {
        // 执行
        _ = mockPlayer.prepareToPlay()
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .prepareToPlay))
    }
    
    func test_Play_RecordsOperationAndUpdatesState() {
        // 执行
        _ = mockPlayer.play()
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .play))
        XCTAssertTrue(mockPlayer.isPlaying)
    }
    
    func test_PlayAtTime_RecordsOperationAndUpdatesState() {
        // 执行
        _ = mockPlayer.play(atTime: 10)
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .playAtTime))
        XCTAssertTrue(mockPlayer.isPlaying)
        XCTAssertEqual(mockPlayer.currentTime, 10)
    }
    
    func test_Pause_RecordsOperationAndUpdatesState() {
        // 准备
        _ = mockPlayer.play()
        
        // 执行
        mockPlayer.pause()
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .pause))
        XCTAssertFalse(mockPlayer.isPlaying)
    }
    
    func test_Stop_RecordsOperationAndUpdatesState() {
        // 准备
        _ = mockPlayer.play()
        mockPlayer.currentTime = 10
        
        // 执行
        mockPlayer.stop()
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .stop))
        XCTAssertFalse(mockPlayer.isPlaying)
        XCTAssertEqual(mockPlayer.currentTime, 0)
    }
    
    // MARK: - 属性测试
    
    func test_CurrentTime_GetAndSet() {
        // 执行 & 验证 - 获取
        _ = mockPlayer.currentTime
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getCurrentTime))
        
        // 执行 & 验证 - 设置
        mockPlayer.currentTime = 20
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .setCurrentTime))
        XCTAssertEqual(mockPlayer.currentTime, 20)
    }
    
    func test_Duration_Get() {
        // 准备
        mockPlayer.setDuration(30)
        
        // 执行 & 验证
        XCTAssertEqual(mockPlayer.duration, 30)
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getDuration))
    }
    
    func test_Volume_GetAndSet() {
        // 执行 & 验证 - 获取
        _ = mockPlayer.volume
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getVolume))
        
        // 执行 & 验证 - 设置
        mockPlayer.volume = 0.7
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .setVolume))
        XCTAssertEqual(mockPlayer.volume, 0.7)
    }
    
    func test_Rate_GetAndSet() {
        // 执行 & 验证 - 获取
        _ = mockPlayer.rate
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getRate))
        
        // 执行 & 验证 - 设置
        mockPlayer.rate = 1.5
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .setRate))
        XCTAssertEqual(mockPlayer.rate, 1.5)
    }
    
    func test_NumberOfLoops_GetAndSet() {
        // 执行 & 验证 - 获取
        _ = mockPlayer.numberOfLoops
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getNumberOfLoops))
        
        // 执行 & 验证 - 设置
        mockPlayer.numberOfLoops = 3
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .setNumberOfLoops))
        XCTAssertEqual(mockPlayer.numberOfLoops, 3)
    }
    
    func test_IsMeteringEnabled_GetAndSet() {
        // 执行 & 验证 - 获取
        _ = mockPlayer.isMeteringEnabled
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getIsMeteringEnabled))
        
        // 执行 & 验证 - 设置
        mockPlayer.isMeteringEnabled = true
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .setIsMeteringEnabled))
        XCTAssertTrue(mockPlayer.isMeteringEnabled)
    }
    
    // MARK: - 测量测试
    
    func test_UpdateMeters_RecordsOperation() {
        // 执行
        mockPlayer.updateMeters()
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .updateMeters))
    }
    
    func test_AveragePower_RecordsOperation() {
        // 执行
        _ = mockPlayer.averagePower(forChannel: 0)
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getAveragePower))
    }
    
    func test_PeakPower_RecordsOperation() {
        // 执行
        _ = mockPlayer.peakPower(forChannel: 0)
        
        // 验证
        XCTAssertTrue(mockPlayer.hasOperation(ofType: .getPeakPower))
    }
    
    // MARK: - 回调测试
    
    func test_CompletionHandler_CalledWhenPlaybackFinishes() {
        // 准备
        let expectation = self.expectation(description: "Completion handler should be called")
        mockPlayer.setDuration(0.1) // 设置一个很短的持续时间
        mockPlayer.mockCompletionHandler = {
            expectation.fulfill()
        }
        
        // 执行
        _ = mockPlayer.play()
        
        // 验证
        waitForExpectations(timeout: 0.5)
        XCTAssertFalse(mockPlayer.isPlaying)
    }
    
    func test_CompletionHandler_WithLoops_CalledAfterAllLoops() {
        // 准备
        let expectation = self.expectation(description: "Completion handler should be called after loops")
        mockPlayer.setDuration(0.1) // 设置一个很短的持续时间
        mockPlayer.numberOfLoops = 2 // 设置循环次数
        
        var playCount = 0
        mockPlayer.mockCompletionHandler = {
            playCount += 1
            if playCount > 2 { // 初始播放 + 2次循环 = 3次播放
                expectation.fulfill()
            }
        }
        
        // 执行
        _ = mockPlayer.play()
        
        // 验证 - 增加超时时间以确保有足够时间完成所有循环
        waitForExpectations(timeout: 2.0)
        XCTAssertFalse(mockPlayer.isPlaying)
    }
}
