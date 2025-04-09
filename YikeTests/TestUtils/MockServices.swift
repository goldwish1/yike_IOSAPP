import Foundation
@testable import Yike

/// Mock服务基类
/// 提供基本的Mock功能和状态管理
class BaseMockService {
    /// 是否已调用特定方法
    private var calledMethods: [String: Int] = [:]
    
    /// 记录方法调用
    /// - Parameter method: 方法名
    func recordCall(_ method: String) {
        calledMethods[method, default: 0] += 1
    }
    
    /// 验证方法是否被调用
    /// - Parameters:
    ///   - method: 方法名
    ///   - times: 期望的调用次数
    /// - Returns: 是否符合期望的调用次数
    func verifyCall(_ method: String, times: Int = 1) -> Bool {
        return calledMethods[method, default: 0] == times
    }
    
    /// 重置所有调用记录
    func resetCalls() {
        calledMethods.removeAll()
    }
}

/// 网络服务Mock
class MockNetworkService: BaseMockService {
    /// 预设的响应数据
    private var mockResponses: [String: Result<Data, Error>] = [:]
    
    /// 设置Mock响应
    /// - Parameters:
    ///   - endpoint: API端点
    ///   - data: 响应数据
    func mockResponse(for endpoint: String, data: Data) {
        mockResponses[endpoint] = .success(data)
    }
    
    /// 设置Mock错误
    /// - Parameters:
    ///   - endpoint: API端点
    ///   - error: 错误信息
    func mockError(for endpoint: String, error: Error) {
        mockResponses[endpoint] = .failure(error)
    }
    
    /// 模拟请求
    /// - Parameter endpoint: API端点
    /// - Returns: 响应结果
    func request(_ endpoint: String) -> Result<Data, Error>? {
        recordCall("request_\(endpoint)")
        return mockResponses[endpoint]
    }
}

/// 存储服务Mock
class MockStorageService: BaseMockService {
    /// 存储的数据
    private var storage: [String: Any] = [:]
    
    /// 存储数据
    /// - Parameters:
    ///   - value: 要存储的值
    ///   - key: 存储键
    func store(_ value: Any, for key: String) {
        recordCall("store_\(key)")
        storage[key] = value
    }
    
    /// 读取数据
    /// - Parameter key: 存储键
    /// - Returns: 存储的值
    func retrieve(_ key: String) -> Any? {
        recordCall("retrieve_\(key)")
        return storage[key]
    }
    
    /// 删除数据
    /// - Parameter key: 存储键
    func remove(_ key: String) {
        recordCall("remove_\(key)")
        storage.removeValue(forKey: key)
    }
    
    /// 清除所有数据
    func clear() {
        recordCall("clear")
        storage.removeAll()
    }
}

/// 音频服务Mock
class MockAudioService: BaseMockService {
    /// 播放状态
    private(set) var isPlaying = false
    /// 当前音频数据
    private(set) var currentAudio: Data?
    
    /// 模拟播放
    /// - Parameter audio: 音频数据
    func play(_ audio: Data) {
        recordCall("play")
        currentAudio = audio
        isPlaying = true
    }
    
    /// 模拟暂停
    func pause() {
        recordCall("pause")
        isPlaying = false
    }
    
    /// 模拟停止
    func stop() {
        recordCall("stop")
        isPlaying = false
        currentAudio = nil
    }
} 