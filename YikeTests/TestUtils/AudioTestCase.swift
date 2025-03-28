import XCTest
@testable import Yike

/// 音频测试基类
/// 提供音频相关测试的基础设施
class AudioTestCase: YikeBaseTests {
    
    // MARK: - Properties
    
    /// Mock音频服务
    var mockAudioService: MockAudioService!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        mockAudioService = MockAudioService()
    }
    
    override func tearDown() {
        mockAudioService = nil
        super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    /// 验证音频播放状态
    /// - Returns: 是否正在播放
    func verifyIsPlaying() -> Bool {
        return mockAudioService.isPlaying
    }
    
    /// 验证当前播放的音频数据
    /// - Parameter data: 预期的音频数据，如果为nil则验证当前是否没有音频在播放
    /// - Returns: 是否匹配
    func verifyCurrentAudio(_ data: Data?) -> Bool {
        if data == nil {
            return mockAudioService.currentAudio == nil
        }
        return mockAudioService.currentAudio == data
    }
} 