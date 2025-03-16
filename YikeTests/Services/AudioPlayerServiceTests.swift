import XCTest
import AVFoundation
@testable import Yike

class AudioPlayerServiceTests: YikeBaseTests {
    
    // MARK: - 属性
    
    var audioPlayerService: AudioPlayerService!
    var mockAudioPlayer: MockAVAudioPlayer!
    var testAudioURL: URL!
    
    // MARK: - 测试生命周期
    
    override func setUp() {
        super.setUp()
        
        // 创建测试音频文件
        testAudioURL = createTestAudioFile()
        
        // 获取 AudioPlayerService 单例
        audioPlayerService = AudioPlayerService.shared
        
        // 创建 MockAVAudioPlayer 实例
        mockAudioPlayer = MockAVAudioPlayer.mockInit()
        
        // 设置 AVAudioPlayer 的 mock
        swizzleAVAudioPlayerInitializer()
    }
    
    override func tearDown() {
        // 恢复原始的 AVAudioPlayer 初始化方法
        restoreAVAudioPlayerInitializer()
        
        // 删除测试音频文件
        deleteTestAudioFile()
        
        audioPlayerService = nil
        mockAudioPlayer = nil
        testAudioURL = nil
        
        super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    /// 创建测试音频文件
    private func createTestAudioFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_audio.mp3")
        
        // 创建一个简单的测试音频文件
        let testData = Data(repeating: 0, count: 1000)
        try? testData.write(to: fileURL)
        
        return fileURL
    }
    
    /// 删除测试音频文件
    private func deleteTestAudioFile() {
        if let url = testAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// 替换 AVAudioPlayer 初始化方法
    private func swizzleAVAudioPlayerInitializer() {
        // 保存对 MockAVAudioPlayer 的引用
        AudioPlayerServiceTests.currentMockPlayer = mockAudioPlayer
        
        // 交换初始化方法
        let originalMethod = class_getClassMethod(AVAudioPlayer.self, #selector(AVAudioPlayer.init(contentsOf:fileTypeHint:)))!
        let swizzledMethod = class_getClassMethod(AudioPlayerServiceTests.self, #selector(AudioPlayerServiceTests.mockAVAudioPlayerInit(contentsOf:fileTypeHint:)))!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    /// 恢复 AVAudioPlayer 初始化方法
    private func restoreAVAudioPlayerInitializer() {
        // 恢复初始化方法
        let originalMethod = class_getClassMethod(AVAudioPlayer.self, #selector(AVAudioPlayer.init(contentsOf:fileTypeHint:)))!
        let swizzledMethod = class_getClassMethod(AudioPlayerServiceTests.self, #selector(AudioPlayerServiceTests.mockAVAudioPlayerInit(contentsOf:fileTypeHint:)))!
        method_exchangeImplementations(swizzledMethod, originalMethod)
        
        // 清除引用
        AudioPlayerServiceTests.currentMockPlayer = nil
    }
    
    // 保存当前的 MockAVAudioPlayer 实例
    static var currentMockPlayer: MockAVAudioPlayer?
    
    // 模拟 AVAudioPlayer 初始化方法
    @objc class func mockAVAudioPlayerInit(contentsOf url: URL, fileTypeHint: String?) throws -> AVAudioPlayer {
        // 使用测试音频文件而不是尝试加载 silence.mp3
        // 创建一个临时的音频数据
        let tempData = Data(repeating: 0, count: 1000)
        
        // 使用数据初始化 AVAudioPlayer
        let player = try AVAudioPlayer(data: tempData)
        
        // 返回真实的 AVAudioPlayer 实例
        return player
    }
    
    // MARK: - 测试方法
    
    /// 测试播放功能
    func test_Play_WithValidURL_StartsPlayback() {
        // 设置期望
        let expectation = self.expectation(description: "播放完成回调被调用")
        
        // 设置模拟播放器的完成回调
        mockAudioPlayer.mockCompletionHandler = {
            expectation.fulfill()
        }
        
        // 执行播放
        audioPlayerService.play(url: testAudioURL)
        
        // 验证播放状态
        XCTAssertTrue(audioPlayerService.isPlaying)
        XCTAssertTrue(mockAudioPlayer.isPlaying)
        XCTAssertEqual(mockAudioPlayer.operations.count, 2) // prepareToPlay + play
        XCTAssertTrue(mockAudioPlayer.hasOperation(ofType: .prepareToPlay))
        XCTAssertTrue(mockAudioPlayer.hasOperation(ofType: .play))
        
        // 模拟播放完成
        mockAudioPlayer.play() // 这会触发完成回调
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证播放完成后的状态
        XCTAssertFalse(audioPlayerService.isPlaying)
    }
    
    /// 测试暂停功能
    func test_Pause_WhenPlaying_PausesPlayback() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 确认播放状态
        XCTAssertTrue(audioPlayerService.isPlaying)
        XCTAssertTrue(mockAudioPlayer.isPlaying)
        
        // 执行暂停
        audioPlayerService.pause()
        
        // 验证暂停状态
        XCTAssertFalse(audioPlayerService.isPlaying)
        XCTAssertFalse(mockAudioPlayer.isPlaying)
        XCTAssertTrue(mockAudioPlayer.hasOperation(ofType: .pause))
    }
    
    /// 测试继续播放功能
    func test_Resume_WhenPaused_ResumesPlayback() {
        // 先开始播放然后暂停
        audioPlayerService.play(url: testAudioURL)
        audioPlayerService.pause()
        
        // 确认暂停状态
        XCTAssertFalse(audioPlayerService.isPlaying)
        XCTAssertFalse(mockAudioPlayer.isPlaying)
        
        // 重置操作记录
        let operationsCount = mockAudioPlayer.operations.count
        
        // 执行继续播放
        audioPlayerService.resume()
        
        // 验证继续播放状态
        XCTAssertTrue(audioPlayerService.isPlaying)
        XCTAssertTrue(mockAudioPlayer.isPlaying)
        XCTAssertTrue(mockAudioPlayer.hasOperation(ofType: .play))
    }
    
    /// 测试停止功能
    func test_Stop_WhenPlaying_StopsPlayback() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 确认播放状态
        XCTAssertTrue(audioPlayerService.isPlaying)
        
        // 执行停止
        audioPlayerService.stop()
        
        // 验证停止状态
        XCTAssertFalse(audioPlayerService.isPlaying)
        XCTAssertTrue(mockAudioPlayer.hasOperation(ofType: .stop))
    }
    
    /// 测试设置音量
    func test_SetVolume_SetsPlayerVolume() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 设置音量
        audioPlayerService.setVolume(0.5)
        
        // 验证音量设置
        XCTAssertEqual(mockAudioPlayer.volume, 0.5)
    }
    
    /// 测试获取当前时间
    func test_CurrentTime_ReturnsPlayerCurrentTime() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 设置模拟播放器的当前时间
        mockAudioPlayer.currentTime = 10.0
        
        // 验证当前时间
        XCTAssertEqual(audioPlayerService.currentTime, 10.0)
    }
    
    /// 测试获取总时长
    func test_Duration_ReturnsPlayerDuration() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 设置模拟播放器的总时长
        mockAudioPlayer.setDuration(60.0)
        
        // 验证总时长
        XCTAssertEqual(audioPlayerService.duration, 60.0)
    }
    
    /// 测试跳转到指定时间
    func test_Seek_SetsPlayerCurrentTime() {
        // 先开始播放
        audioPlayerService.play(url: testAudioURL)
        
        // 设置模拟播放器的总时长
        mockAudioPlayer.setDuration(60.0)
        
        // 执行跳转
        audioPlayerService.seek(to: 30.0)
        
        // 验证当前时间
        XCTAssertEqual(mockAudioPlayer.currentTime, 30.0)
    }
    
    /// 测试播放错误处理
    func test_PlayError_CallsCompletionHandler() {
        // 设置期望
        let expectation = self.expectation(description: "错误回调被调用")
        
        // 设置模拟播放器抛出错误
        MockAVAudioPlayer.errorToThrow = NSError(domain: "AVFoundationErrorDomain", code: -1, userInfo: nil)
        
        // 执行播放
        audioPlayerService.play(url: testAudioURL) {
            expectation.fulfill()
        }
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证播放状态
        XCTAssertFalse(audioPlayerService.isPlaying)
        
        // 清除错误
        MockAVAudioPlayer.errorToThrow = nil
    }
    
    /// 测试解码错误处理
    func test_DecodeError_CallsCompletionHandler() {
        // 设置期望
        let expectation = self.expectation(description: "解码错误回调被调用")
        
        // 设置模拟播放器的完成回调
        mockAudioPlayer.mockCompletionHandler = {
            expectation.fulfill()
        }
        
        // 执行播放
        audioPlayerService.play(url: testAudioURL)
        
        // 设置错误并触发播放（会导致错误回调）
        MockAVAudioPlayer.errorToThrow = NSError(domain: "AVFoundationErrorDomain", code: -1, userInfo: nil)
        mockAudioPlayer.play()
        
        // 等待期望完成
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // 验证播放状态
        XCTAssertFalse(audioPlayerService.isPlaying)
        
        // 清除错误
        MockAVAudioPlayer.errorToThrow = nil
    }
}
