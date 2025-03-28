import XCTest
@testable import Yike

/// 忆刻应用的基础测试类
/// 提供所有测试用例的共享设置和基础功能
class YikeBaseTests: XCTestCase {
    
    // MARK: - 测试数据
    
    /// 基础测试数据结构
    struct TestData {
        /// 测试标题
        static let testTitle = "测试标题"
        /// 测试内容
        static let testContent = "这是一段测试内容，用于验证应用基本功能。"
        /// 默认积分
        static let defaultPoints = 100
    }
    
    // MARK: - 生命周期
    
    /// 运行测试前的设置
    override func setUp() {
        super.setUp()
        setupTestEnvironment()
    }
    
    /// 运行测试后的清理
    override func tearDown() {
        cleanupTestEnvironment()
        super.tearDown()
    }
    
    // MARK: - 环境管理
    
    /// 设置测试环境
    private func setupTestEnvironment() {
        // 设置测试环境标识
        UserDefaults.standard.set(true, forKey: "IsRunningTests")
        
        // 重置测试环境
        resetTestEnvironment()
    }
    
    /// 重置测试环境
    func resetTestEnvironment() {
        cleanupTestEnvironment()
        setupInitialTestData()
    }
    
    /// 设置初始测试数据
    private func setupInitialTestData() {
        // 子类可以重写此方法以设置特定的测试数据
    }
    
    /// 清理测试环境
    private func cleanupTestEnvironment() {
        // 子类可以重写此方法以清理特定的测试数据
    }
    
    // MARK: - 辅助方法
    
    /// 等待条件满足
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - condition: 需要满足的条件
    /// - Returns: 是否在超时前满足条件
    func waitForCondition(timeout: TimeInterval = 5.0, condition: @escaping () -> Bool) -> Bool {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                return false // 超时
            }
            
            // 等待一小段时间
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
        return true // 条件满足
    }
    
    /// 模拟网络状态更改
    /// - Parameter connected: 是否连接
    func simulateNetworkState(connected: Bool) {
        NotificationCenter.default.post(
            name: Notification.Name(connected ? "UITestNetworkConnected" : "UITestNetworkDisconnected"),
            object: nil
        )
    }
    
    // MARK: - 异步测试支持
    
    /// 创建异步测试期望
    /// - Parameter description: 期望描述
    /// - Returns: XCTestExpectation实例
    override func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
    
    /// 等待所有期望完成
    /// - Parameters:
    ///   - expectations: 期望数组
    ///   - timeout: 超时时间（秒）
    override func wait(for expectations: [XCTestExpectation], timeout: TimeInterval = 5.0) {
        super.wait(for: expectations, timeout: timeout)
    }
    
    // MARK: - 性能测试支持
    
    /// 测量代码执行时间
    /// - Parameters:
    ///   - name: 测试名称
    ///   - block: 要测量的代码块
    func measure(name: String, block: @escaping () -> Void) {
        measure(metrics: [XCTClockMetric()], options: XCTMeasureOptions()) {
            block()
        }
    }
} 