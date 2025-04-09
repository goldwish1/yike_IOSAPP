import XCTest
@testable import Yike

/// YikeBaseTests的测试类
final class YikeBaseTestsTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: YikeBaseTests!
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        sut = YikeBaseTests()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// 测试环境初始化
    func test_setupEnvironment() {
        // Given
        let defaults = UserDefaults.standard
        
        // When
        sut.setUp()
        
        // Then
        XCTAssertTrue(defaults.bool(forKey: "IsRunningTests"))
    }
    
    /// 测试条件等待功能
    func test_waitForCondition() {
        // Given
        var flag = false
        
        // When - 条件满足的情况
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flag = true
        }
        let successResult = sut.waitForCondition(timeout: 1.0) { flag }
        
        // Then
        XCTAssertTrue(successResult)
        
        // When - 条件超时的情况
        flag = false
        let timeoutResult = sut.waitForCondition(timeout: 0.1) { flag }
        
        // Then
        XCTAssertFalse(timeoutResult)
    }
    
    /// 测试网络状态模拟
    func test_simulateNetworkState() {
        // Given
        let expectation = self.expectation(description: "Network state change")
        var receivedNotification = false
        
        NotificationCenter.default.addObserver(forName: Notification.Name("UITestNetworkConnected"), object: nil, queue: nil) { _ in
            receivedNotification = true
            expectation.fulfill()
        }
        
        // When
        sut.simulateNetworkState(connected: true)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification)
    }
    
    /// 测试性能测量功能
    func test_measurePerformance() {
        // Given
        let testBlock = { Thread.sleep(forTimeInterval: 0.1) }
        
        // When & Then
        sut.measure(name: "Test measurement") {
            testBlock()
        }
    }
} 