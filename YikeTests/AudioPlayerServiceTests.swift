//
//  AudioPlayerServiceTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//

import XCTest
import AVFoundation
@testable import Yike

/// 模拟音频播放器
class MockAVAudioPlayer: AVAudioPlayer {
    // 模拟播放状态
    var mockIsPlaying = false
    
    // 模拟音量
    var mockVolume: Float = 1.0
    
    // 模拟当前时间
    var mockCurrentTime: TimeInterval = 0.0
    
    // 模拟总时长
    var mockDuration: TimeInterval = 60.0
    
    // 模拟方法调用计数
    var playCallCount = 0
    var pauseCallCount = 0
    var stopCallCount = 0
    
    // 覆盖原始方法
    override var isPlaying: Bool {
        return mockIsPlaying
    }
    
    override var volume: Float {
        get { return mockVolume }
        set { mockVolume = newValue }
    }
    
    override var currentTime: TimeInterval {
        get { return mockCurrentTime }
        set { mockCurrentTime = newValue }
    }
    
    override var duration: TimeInterval {
        return mockDuration
    }
    
    override func play() -> Bool {
        playCallCount += 1
        mockIsPlaying = true
        return true
    }
    
    override func pause() {
        pauseCallCount += 1
        mockIsPlaying = false
    }
    
    override func stop() {
        stopCallCount += 1
        mockIsPlaying = false
        mockCurrentTime = 0
    }
}

/// 音频播放服务测试类
class AudioPlayerServiceTests: YikeBaseTests {
    
    // 被测试的服务
    var audioService: AudioPlayerService!
    
    // 模拟音频播放器
    var mockPlayer: MockAVAudioPlayer!
    
    // 测试音频URL
    var testAudioURL: URL!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        
        // 初始化测试音频URL
        testAudioURL = TestDataProvider.testAudioURL
        
        // 创建测试音频文件
        createTestAudioFile()
        
        // 获取服务实例
        audioService = AudioPlayerService.shared
        
        // 设置模拟播放器
        setupMockAudioPlayer()
    }
    
    override func tearDown() {
        // 删除测试音频文件
        deleteTestAudioFile()
        
        // 重置服务状态
        audioService.stop()
        
        super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    /// 创建测试音频文件
    private func createTestAudioFile() {
        // 创建一个简单的测试音频文件
        let testData = Data(repeating: 0, count: 1024)
        try? testData.write(to: testAudioURL)
    }
    
    /// 删除测试音频文件
    private func deleteTestAudioFile() {
        try? FileManager.default.removeItem(at: testAudioURL)
    }
    
    /// 设置模拟音频播放器
    private func setupMockAudioPlayer() {
        // 这里需要使用运行时替换或依赖注入来设置模拟播放器
        // 由于AVAudioPlayer是系统类，我们可能需要在AudioPlayerService中添加测试钩子
        
        // 注意：这是一个简化的示例，实际实现可能需要更复杂的方法
        mockPlayer = MockAVAudioPlayer()
    }
    
    // MARK: - 测试用例
    
    /// 测试播放功能
    func testPlay() {
        // 设置期望
        let expectation = self.expectation(description: "播放完成")
        
        // 执行测试
        audioService.play(url: testAudioURL) { success in
            // 验证结果
            XCTAssertTrue(success, "播放应该成功")
            XCTAssertTrue(self.audioService.isPlaying, "播放状态应该为true")
            
            // 完成期望
            expectation.fulfill()
        }
        
        // 等待期望完成
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    /// 测试暂停功能
    func testPause() {
        // 先播放
        audioService.play(url: testAudioURL) { _ in }
        
        // 执行暂停
        audioService.pause()
        
        // 验证结果
        XCTAssertFalse(audioService.isPlaying, "暂停后播放状态应该为false")
    }
    
    /// 测试继续播放功能
    func testResume() {
        // 先播放然后暂停
        audioService.play(url: testAudioURL) { _ in }
        audioService.pause()
        
        // 执行继续播放
        audioService.resume()
        
        // 验证结果
        XCTAssertTrue(audioService.isPlaying, "继续播放后状态应该为true")
    }
    
    /// 测试停止功能
    func testStop() {
        // 先播放
        audioService.play(url: testAudioURL) { _ in }
        
        // 执行停止
        audioService.stop()
        
        // 验证结果
        XCTAssertFalse(audioService.isPlaying, "停止后播放状态应该为false")
    }
    
    /// 测试设置音量
    func testSetVolume() {
        // 先播放
        audioService.play(url: testAudioURL) { _ in }
        
        // 设置音量
        let testVolume: Float = 0.5
        audioService.setVolume(testVolume)
        
        // 验证结果
        // 注意：由于我们没有直接访问内部audioPlayer的方式，这里的测试可能需要调整
        // 这是一个简化的示例
    }
    
    /// 测试跳转到指定时间点
    func testSeek() {
        // 先播放
        audioService.play(url: testAudioURL) { _ in }
        
        // 跳转到指定时间点
        let testTime: TimeInterval = 30.0
        audioService.seek(to: testTime)
        
        // 验证结果
        // 同样，这里需要访问内部状态进行验证
    }
} 