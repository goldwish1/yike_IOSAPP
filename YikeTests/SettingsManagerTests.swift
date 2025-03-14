//
//  SettingsManagerTests.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/21.
//

import XCTest
@testable import Yike

class SettingsManagerTests: YikeBaseTests {
    
    // 被测试的管理器
    var settingsManager: SettingsManager!
    
    // 模拟UserDefaults
    var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // 初始化模拟UserDefaults
        mockUserDefaults = MockUserDefaults()
        
        // 初始化设置管理器，使用模拟的UserDefaults
        settingsManager = SettingsManager(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        // 重置模拟UserDefaults
        mockUserDefaults.reset()
        
        super.tearDown()
    }
    
    // MARK: - 测试播放设置
    
    func testDefaultPlaybackSettings() {
        // 验证默认播放设置
        XCTAssertEqual(settingsManager.getPlaybackSpeed(), 1.0)
        XCTAssertEqual(settingsManager.getPlaybackInterval(), 5)
        XCTAssertEqual(settingsManager.getVoiceType(), .standard)
    }
    
    func testSetPlaybackSpeed() {
        // 设置播放速度
        settingsManager.setPlaybackSpeed(1.5)
        
        // 验证设置已保存
        XCTAssertEqual(settingsManager.getPlaybackSpeed(), 1.5)
        XCTAssertEqual(mockUserDefaults.double(forKey: SettingsManager.Keys.playbackSpeed.rawValue), 1.5)
    }
    
    func testSetPlaybackInterval() {
        // 设置播放间隔
        settingsManager.setPlaybackInterval(10)
        
        // 验证设置已保存
        XCTAssertEqual(settingsManager.getPlaybackInterval(), 10)
        XCTAssertEqual(mockUserDefaults.integer(forKey: SettingsManager.Keys.playbackInterval.rawValue), 10)
    }
    
    func testSetVoiceType() {
        // 设置语音类型
        settingsManager.setVoiceType(.gentle)
        
        // 验证设置已保存
        XCTAssertEqual(settingsManager.getVoiceType(), .gentle)
        XCTAssertEqual(mockUserDefaults.integer(forKey: SettingsManager.Keys.voiceType.rawValue), VoiceType.gentle.rawValue)
    }
    
    // MARK: - 测试提醒设置
    
    func testDefaultReminderSettings() {
        // 验证默认提醒设置
        XCTAssertTrue(settingsManager.isReminderEnabled())
        XCTAssertEqual(settingsManager.getReminderStrategy(), .standard)
        XCTAssertEqual(settingsManager.getReminderTime(), 9 * 3600) // 默认9:00 AM
    }
    
    func testSetReminderEnabled() {
        // 设置提醒开关
        settingsManager.setReminderEnabled(false)
        
        // 验证设置已保存
        XCTAssertFalse(settingsManager.isReminderEnabled())
        XCTAssertFalse(mockUserDefaults.bool(forKey: SettingsManager.Keys.reminderEnabled.rawValue))
    }
    
    func testSetReminderStrategy() {
        // 设置提醒策略
        settingsManager.setReminderStrategy(.intensive)
        
        // 验证设置已保存
        XCTAssertEqual(settingsManager.getReminderStrategy(), .intensive)
        XCTAssertEqual(mockUserDefaults.integer(forKey: SettingsManager.Keys.reminderStrategy.rawValue), ReminderStrategy.intensive.rawValue)
    }
    
    func testSetReminderTime() {
        // 设置提醒时间（20:00）
        let secondsSinceMidnight = 20 * 3600
        settingsManager.setReminderTime(secondsSinceMidnight)
        
        // 验证设置已保存
        XCTAssertEqual(settingsManager.getReminderTime(), secondsSinceMidnight)
        XCTAssertEqual(mockUserDefaults.integer(forKey: SettingsManager.Keys.reminderTime.rawValue), secondsSinceMidnight)
    }
    
    // MARK: - 测试设置变更通知
    
    func testSettingsChangeNotification() {
        // 设置期望
        let expectation = self.expectation(description: "设置变更通知")
        
        // 注册通知观察者
        let notificationName = NSNotification.Name(SettingsManager.Keys.settingsChanged.rawValue)
        let token = NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: .main) { notification in
            // 验证通知数据
            if let key = notification.userInfo?["key"] as? String,
               key == SettingsManager.Keys.playbackSpeed.rawValue {
                expectation.fulfill()
            }
        }
        
        // 更改设置
        settingsManager.setPlaybackSpeed(1.8)
        
        // 等待通知
        waitForExpectations(timeout: 1, handler: nil)
        
        // 移除观察者
        NotificationCenter.default.removeObserver(token)
    }
} 