import XCTest
@testable import Yike

/// 网络测试基类
/// 提供网络相关测试的基础设施
class NetworkTestCase: YikeBaseTests {
    
    // MARK: - Properties
    
    /// Mock网络服务
    var mockNetworkService: MockNetworkService!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
    }
    
    override func tearDown() {
        mockNetworkService = nil
        super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    /// 模拟网络请求延迟
    /// - Parameter seconds: 延迟秒数
    func simulateNetworkDelay(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
    
    /// 验证网络请求是否发生
    /// - Parameter endpoint: 接口地址
    /// - Returns: 是否发生请求
    func verifyRequest(to endpoint: String) -> Bool {
        return mockNetworkService.verifyCall("request_\(endpoint)")
    }
} 