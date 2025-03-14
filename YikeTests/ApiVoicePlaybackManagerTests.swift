//
//  ApiVoicePlaybackManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//

import XCTest
@testable import Yike

class ApiVoicePlaybackManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var playbackManager: ApiVoicePlaybackManager!
    
    override func setUp() {
        super.setUp()
        
        // 获取单例实例
        playbackManager = ApiVoicePlaybackManager.shared
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
    
    func testTogglePlayPause() {
        // 由于实际播放需要网络请求和音频播放，这里我们只测试状态变化
        // 初始状态
        XCTAssertFalse(playbackManager.isPlaying)
        
        // 尝试切换播放状态（由于没有实际音频，这可能不会改变状态）
        playbackManager.togglePlayPause(text: "测试文本", voice: "zh-CN-XiaoxiaoNeural", speed: 1.0)
        
        // 停止任何可能的播放
        playbackManager.stop()
        XCTAssertFalse(playbackManager.isPlaying)
    }
    
    // 注意：更多的测试可能需要模拟网络请求和音频播放，
    // 这需要更复杂的测试设置，如依赖注入和模拟对象
} 