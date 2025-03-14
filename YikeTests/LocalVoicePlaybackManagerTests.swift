//
//  LocalVoicePlaybackManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//

import XCTest
@testable import Yike

class LocalVoicePlaybackManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var playbackManager: LocalVoicePlaybackManager!
    
    override func setUp() {
        super.setUp()
        
        // 获取单例实例
        playbackManager = LocalVoicePlaybackManager.shared
    }
    
    override func tearDown() {
        // 停止任何正在进行的播放
        playbackManager.stop()
        super.tearDown()
    }
    
    // MARK: - 测试基本功能
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(playbackManager.progress, 0.0)
        XCTAssertEqual(playbackManager.currentTime, "00:00")
        XCTAssertEqual(playbackManager.totalTime, "00:00")
    }
    
    func testPrepareAndReset() {
        // 准备播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 重置
        playbackManager.reset()
        
        // 验证状态已重置
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(playbackManager.progress, 0.0)
    }
    
    func testSetSpeed() {
        // 准备播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 设置速度
        playbackManager.setSpeed(1.5)
        
        // 重置
        playbackManager.reset()
    }
    
    func testTogglePlayPause() {
        // 准备播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 切换播放状态
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 停止播放
        playbackManager.stop()
    }
    
    // 注意：由于语音合成涉及系统API调用，完整测试可能需要模拟AVSpeechSynthesizer
} 