import XCTest
@testable import Yike

/// NetworkTestCase的测试类
final class NetworkTestCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: NetworkTestCase!
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        sut = NetworkTestCase()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// 测试网络服务初始化
    func test_mockNetworkService_initialization() {
        // When
        sut.setUp()
        
        // Then
        XCTAssertNotNil(sut.mockNetworkService)
        
        // When
        sut.tearDown()
        
        // Then
        XCTAssertNil(sut.mockNetworkService)
    }
    
    /// 测试网络延迟模拟
    func test_simulateNetworkDelay() {
        // Given
        let delayTime: TimeInterval = 0.1
        let startTime = Date()
        
        // When
        sut.simulateNetworkDelay(delayTime)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertGreaterThanOrEqual(elapsedTime, delayTime)
    }
    
    /// 测试请求验证功能
    func test_verifyRequest() {
        // Given
        sut.setUp()
        let endpoint = "test_endpoint"
        
        // When - 没有请求发生
        let noRequestResult = sut.verifyRequest(to: endpoint)
        
        // Then
        XCTAssertFalse(noRequestResult)
        
        // When - 发生请求
        sut.mockNetworkService.request(endpoint)
        let hasRequestResult = sut.verifyRequest(to: endpoint)
        
        // Then
        XCTAssertTrue(hasRequestResult)
    }
} 