import XCTest
@testable import Yike

/// AudioTestCase的测试类
final class AudioTestCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AudioTestCase!
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        sut = AudioTestCase()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// 测试音频服务初始化
    func test_mockAudioService_initialization() {
        // When
        sut.setUp()
        
        // Then
        XCTAssertNotNil(sut.mockAudioService)
        
        // When
        sut.tearDown()
        
        // Then
        XCTAssertNil(sut.mockAudioService)
    }
    
    /// 测试播放状态验证
    func test_verifyIsPlaying() {
        // Given
        sut.setUp()
        let testData = Data([1, 2, 3])
        
        // When - 初始状态
        let initialState = sut.verifyIsPlaying()
        
        // Then
        XCTAssertFalse(initialState)
        
        // When - 播放状态
        sut.mockAudioService.play(testData)
        let playingState = sut.verifyIsPlaying()
        
        // Then
        XCTAssertTrue(playingState)
        
        // When - 暂停状态
        sut.mockAudioService.pause()
        let pausedState = sut.verifyIsPlaying()
        
        // Then
        XCTAssertFalse(pausedState)
    }
    
    /// 测试当前音频验证
    func test_verifyCurrentAudio() {
        // Given
        sut.setUp()
        let testData = Data([1, 2, 3])
        
        // When - 初始状态（currentAudio为nil）
        let initialResult = sut.verifyCurrentAudio(nil)
        
        // Then
        XCTAssertTrue(initialResult, "初始状态下currentAudio应为nil")
        
        // When - 播放音频
        sut.mockAudioService.play(testData)
        let matchResult = sut.verifyCurrentAudio(testData)
        let mismatchResult = sut.verifyCurrentAudio(Data([4, 5, 6]))
        
        // Then
        XCTAssertTrue(matchResult, "当前播放的音频应与测试数据匹配")
        XCTAssertFalse(mismatchResult, "不同的音频数据应该不匹配")
    }
} 