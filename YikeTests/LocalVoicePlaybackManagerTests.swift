//
//  LocalVoicePlaybackManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//  Updated on 2025/3/21.
//

import XCTest
import AVFoundation
@testable import Yike

class LocalVoicePlaybackManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var playbackManager: LocalVoicePlaybackManager!
    
    // 模拟语音合成器
    var mockSynthesizer: MockAVSpeechSynthesizer!
    
    override func setUp() {
        super.setUp()
        
        // 创建模拟语音合成器
        mockSynthesizer = MockAVSpeechSynthesizer()
        
        // 替换实际的语音合成器
        playbackManager = LocalVoicePlaybackManager(synthesizer: mockSynthesizer)
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
        
        // 验证准备状态
        XCTAssertEqual(mockSynthesizer.pendingUtterances.count, 1)
        
        // 重置
        playbackManager.reset()
        
        // 验证状态已重置
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(playbackManager.progress, 0.0)
        XCTAssertEqual(mockSynthesizer.stopSpeakingCallCount, 1)
    }
    
    // MARK: - 测试播放控制
    
    func testTogglePlayPause() {
        // 准备播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 初始状态
        XCTAssertFalse(playbackManager.isPlaying)
        
        // 开始播放
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 验证播放状态
        XCTAssertTrue(playbackManager.isPlaying)
        XCTAssertEqual(mockSynthesizer.speakCallCount, 1)
        
        // 再次切换（暂停）
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 验证暂停状态
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(mockSynthesizer.pauseSpeakingCallCount, 1)
        
        // 再次切换（继续）
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 验证继续播放状态
        XCTAssertTrue(playbackManager.isPlaying)
        XCTAssertEqual(mockSynthesizer.continueSpeakingCallCount, 1)
    }
    
    func testStop() {
        // 准备并开始播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 验证播放状态
        XCTAssertTrue(playbackManager.isPlaying)
        
        // 停止播放
        playbackManager.stop()
        
        // 验证状态
        XCTAssertFalse(playbackManager.isPlaying)
        XCTAssertEqual(playbackManager.progress, 0.0)
        XCTAssertEqual(mockSynthesizer.stopSpeakingCallCount, 1)
    }
    
    func testSetSpeed() {
        // 准备播放
        playbackManager.prepare(text: "这是测试文本", speed: 1.0, intervalSeconds: 5)
        
        // 设置速度
        playbackManager.setSpeed(1.5)
        
        // 开始播放
        playbackManager.togglePlayPause(text: "这是测试文本", speed: 1.5, intervalSeconds: 5)
        
        // 验证速度设置
        XCTAssertEqual(mockSynthesizer.lastUtterance?.rate, AVSpeechUtteranceDefaultSpeechRate * Float(1.5))
    }
    
    // MARK: - 测试分段播放
    
    func testSplitTextIntoSegments() {
        // 测试文本分段
        let text = "第一句。第二句。第三句。"
        let segments = playbackManager.splitTextIntoSegments(text)
        
        // 验证分段结果
        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments[0], "第一句。")
        XCTAssertEqual(segments[1], "第二句。")
        XCTAssertEqual(segments[2], "第三句。")
    }
    
    func testPlayWithInterval() {
        // 准备多段文本
        let text = "第一句。第二句。第三句。"
        let intervalSeconds = 2
        
        // 开始播放
        playbackManager.togglePlayPause(text: text, speed: 1.0, intervalSeconds: intervalSeconds)
        
        // 验证播放状态
        XCTAssertTrue(playbackManager.isPlaying)
        
        // 验证语音合成器收到的话语
        XCTAssertEqual(mockSynthesizer.pendingUtterances.count, 1)
        XCTAssertEqual(mockSynthesizer.pendingUtterances.first?.speechString, "第一句。")
        
        // 模拟第一段播放完成
        mockSynthesizer.simulateDidFinish(mockSynthesizer.pendingUtterances.first!)
        
        // 等待间隔
        wait(for: TimeInterval(intervalSeconds) + 0.1)
        
        // 验证第二段开始播放
        XCTAssertEqual(mockSynthesizer.speakCallCount, 2)
    }
    
    // MARK: - 测试进度更新
    
    func testProgressUpdate() {
        // 准备播放
        let text = "测试进度更新。"
        playbackManager.togglePlayPause(text: text, speed: 1.0, intervalSeconds: 5)
        
        // 获取语音实例
        guard let utterance = mockSynthesizer.pendingUtterances.first else {
            XCTFail("没有创建语音实例")
            return
        }
        
        // 模拟进度更新
        mockSynthesizer.simulateDidStart(utterance)
        mockSynthesizer.simulateWillSpeakRangeOfSpeechString(utterance, range: NSRange(location: 0, length: 2), characterRange: NSRange(location: 0, length: 2))
        
        // 验证进度已更新
        XCTAssertGreaterThan(playbackManager.progress, 0.0)
    }
}

// MARK: - 辅助类

/// 模拟语音合成器
class MockAVSpeechSynthesizer: AVSpeechSynthesizer {
    var pendingUtterances: [AVSpeechUtterance] = []
    var lastUtterance: AVSpeechUtterance?
    
    var speakCallCount = 0
    var pauseSpeakingCallCount = 0
    var continueSpeakingCallCount = 0
    var stopSpeakingCallCount = 0
    
    var mockIsSpeaking: Bool = false
    var mockIsPaused: Bool = false
    
    override var isSpeaking: Bool {
        return mockIsSpeaking
    }
    
    override var isPaused: Bool {
        return mockIsPaused
    }
    
    override func speak(_ utterance: AVSpeechUtterance) {
        speakCallCount += 1
        pendingUtterances.append(utterance)
        lastUtterance = utterance
        mockIsSpeaking = true
        mockIsPaused = false
    }
    
    override func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        pauseSpeakingCallCount += 1
        mockIsSpeaking = true
        mockIsPaused = true
        return true
    }
    
    override func continueSpeaking() -> Bool {
        continueSpeakingCallCount += 1
        mockIsSpeaking = true
        mockIsPaused = false
        return true
    }
    
    override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopSpeakingCallCount += 1
        mockIsSpeaking = false
        mockIsPaused = false
        pendingUtterances.removeAll()
        return true
    }
    
    // 模拟语音合成器委托方法
    
    func simulateDidStart(_ utterance: AVSpeechUtterance) {
        if let delegate = delegate as? AVSpeechSynthesizerDelegate {
            delegate.speechSynthesizer?(self, didStart: utterance)
        }
    }
    
    func simulateDidFinish(_ utterance: AVSpeechUtterance) {
        if let index = pendingUtterances.firstIndex(where: { $0 === utterance }) {
            pendingUtterances.remove(at: index)
        }
        
        mockIsSpeaking = false
        
        if let delegate = delegate as? AVSpeechSynthesizerDelegate {
            delegate.speechSynthesizer?(self, didFinish: utterance)
        }
    }
    
    func simulateWillSpeakRangeOfSpeechString(_ utterance: AVSpeechUtterance, range: NSRange, characterRange: NSRange) {
        if let delegate = delegate as? AVSpeechSynthesizerDelegate {
            delegate.speechSynthesizer?(self, willSpeakRangeOfSpeechString: range, utterance: utterance)
        }
    }
} 