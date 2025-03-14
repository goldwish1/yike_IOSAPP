//
//  ApiVoicePlaybackManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//  Updated on 2025/3/21.
//

import XCTest
import AVFoundation
@testable import Yike

class ApiVoicePlaybackManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var playbackManager: ApiVoicePlaybackManager!
    
    // 模拟音频播放服务
    var mockAudioService: MockAudioPlayerService!
    
    // 模拟TTS服务
    var mockTTSService: MockSiliconFlowTTSService!
    
    override func setUp() {
        super.setUp()
        
        // 创建模拟服务
        mockAudioService = MockAudioPlayerService()
        mockTTSService = MockSiliconFlowTTSService()
        
        // 进行方法交换
        AudioPlayerService.swapInstanceForTesting(mockAudioService)
        SiliconFlowTTSService.swapInstanceForTesting(mockTTSService)
        
        // 获取单例实例
        playbackManager = ApiVoicePlaybackManager.shared
    }
    
    override func tearDown() {
        // 停止任何正在进行的播放
        playbackManager.stop()
        
        // 恢复原始服务
        AudioPlayerService.restoreOriginalInstance()
        SiliconFlowTTSService.restoreOriginalInstance()
        
        super.tearDown()
    }
    
    // MARK: - 测试基本功能
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertFalse(playbackManager.isLoading)
        XCTAssertNil(playbackManager.error)
        XCTAssertEqual(playbackManager.progress, 0.0)
    }
    
    func testFormatTime() {
        // 测试时间格式化
        XCTAssertEqual(playbackManager.formatTime(0), "00:00")
        XCTAssertEqual(playbackManager.formatTime(65), "01:05")
        XCTAssertEqual(playbackManager.formatTime(3600), "60:00")
    }
    
    // MARK: - 测试播放控制
    
    func testTogglePlayPause() {
        // 测试播放暂停切换
        
        // 初始状态
        XCTAssertFalse(playbackManager.isPlaying)
        
        // 模拟成功的TTS合成和音频加载
        let testUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
        mockTTSService.mockSuccessResult(url: testUrl)
        mockAudioService.mockIsPlayingValue = true
        
        // 尝试播放
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证加载状态
        XCTAssertTrue(playbackManager.isLoading)
        
        // 完成加载
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证播放状态
        XCTAssertTrue(playbackManager.isPlaying)
        XCTAssertFalse(playbackManager.isLoading)
        
        // 再次切换（暂停）
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 验证暂停状态
        XCTAssertFalse(playbackManager.isPlaying)
    }
    
    func testStop() {
        // 测试停止功能
        
        // 首先播放
        let testUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
        mockTTSService.mockSuccessResult(url: testUrl)
        mockAudioService.mockIsPlayingValue = true
        
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 现在停止
        playbackManager.stop()
        
        // 验证状态
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(playbackManager.progress, 0.0)
        XCTAssertEqual(mockAudioService.stopCallCount, 1)
    }
    
    func testSetSpeed() {
        // 测试设置播放速度
        playbackManager.setSpeed(1.5)
        
        // 播放音频
        let testUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
        mockTTSService.mockSuccessResult(url: testUrl)
        
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证设置速度被调用
        XCTAssertEqual(mockAudioService.lastSpeedValue, 1.5)
    }
    
    // MARK: - 测试错误处理
    
    func testTTSFailure() {
        // 模拟TTS失败
        mockTTSService.mockErrorResult(error: TTSError.networkError)
        
        // 尝试播放
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 完成请求（带错误）
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证错误状态
        XCTAssertNotNil(playbackManager.error)
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertFalse(playbackManager.isLoading)
    }
    
    func testPlaybackFailure() {
        // 模拟音频播放失败
        let testUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
        mockTTSService.mockSuccessResult(url: testUrl)
        mockAudioService.mockPlayError = NSError(domain: "test", code: -1, userInfo: nil)
        
        // 尝试播放
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 完成TTS请求
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证错误状态
        XCTAssertNotNil(playbackManager.error)
        XCTAssertFalse(playbackManager.isPlaying)
    }
    
    // MARK: - 测试缓存机制
    
    func testCacheHit() {
        // 第一次播放，使用相同的文本和语音
        let testUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_audio.mp3")
        mockTTSService.mockSuccessResult(url: testUrl)
        
        playbackManager.togglePlayPause(text: "缓存测试", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        mockTTSService.fulfillPendingRequests()
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 停止播放
        playbackManager.stop()
        
        // 重置计数器
        mockTTSService.resetCallCount()
        
        // 第二次播放，应该使用缓存
        playbackManager.togglePlayPause(text: "缓存测试", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 等待异步操作
        wait(for: 0.1)
        
        // 验证TTS服务没有被再次调用
        XCTAssertEqual(mockTTSService.synthesizeCallCount, 0)
    }
}

// MARK: - 辅助类

/// 模拟音频播放服务
class MockAudioPlayerService: AudioPlayerService {
    var mockIsPlayingValue: Bool = false
    var mockProgress: Double = 0.0
    var mockDuration: TimeInterval = 60.0
    var mockCurrentTime: TimeInterval = 0.0
    var lastSpeedValue: Float?
    var mockPlayError: Error?
    
    var playCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var stopCallCount = 0
    
    override var isPlaying: Bool {
        return mockIsPlayingValue
    }
    
    override var progress: Double {
        return mockProgress
    }
    
    override var duration: TimeInterval {
        return mockDuration
    }
    
    override var currentTime: TimeInterval {
        return mockCurrentTime
    }
    
    override func play(url: URL, completion: @escaping () -> Void) {
        playCallCount += 1
        
        if let error = mockPlayError {
            // 模拟播放失败
            completion()
            return
        }
        
        mockIsPlayingValue = true
        completion()
    }
    
    override func pause() {
        pauseCallCount += 1
        mockIsPlayingValue = false
    }
    
    override func resume() {
        resumeCallCount += 1
        mockIsPlayingValue = true
    }
    
    override func stop() {
        stopCallCount += 1
        mockIsPlayingValue = false
        mockCurrentTime = 0
        mockProgress = 0
    }
    
    override func setRate(_ rate: Float) {
        lastSpeedValue = rate
    }
    
    override func seek(to time: TimeInterval) {
        mockCurrentTime = min(time, mockDuration)
        mockProgress = time / mockDuration
    }
}

/// 模拟TTS服务
class MockSiliconFlowTTSService: SiliconFlowTTSService {
    private var pendingCompletions: [(Result<URL, Error>) -> Void] = []
    private var mockResult: Result<URL, Error>?
    var synthesizeCallCount = 0
    
    override func synthesize(text: String, voice: String, previewMode: Bool, completion: @escaping (Result<URL, Error>) -> Void) {
        synthesizeCallCount += 1
        
        // 存储完成回调
        pendingCompletions.append(completion)
    }
    
    func mockSuccessResult(url: URL) {
        mockResult = .success(url)
    }
    
    func mockErrorResult(error: Error) {
        mockResult = .failure(error)
    }
    
    func fulfillPendingRequests() {
        guard let result = mockResult else {
            return
        }
        
        // 调用所有挂起的完成回调
        for completion in pendingCompletions {
            completion(result)
        }
        
        pendingCompletions.removeAll()
    }
    
    func resetCallCount() {
        synthesizeCallCount = 0
    }
} 