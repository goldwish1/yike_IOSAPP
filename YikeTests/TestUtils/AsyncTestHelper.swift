import XCTest
@testable import Yike

/// 异步测试助手
/// 提供异步测试相关的辅助方法
class AsyncTestHelper {
    
    /// 默认超时时间（秒）
    static let defaultTimeout: TimeInterval = 5.0
    
    /// 等待异步操作完成
    /// - Parameters:
    ///   - timeout: 超时时间
    ///   - description: 等待描述
    ///   - operation: 异步操作
    static func wait(
        timeout: TimeInterval = defaultTimeout,
        description: String,
        operation: @escaping (XCTestExpectation) -> Void
    ) {
        let expectation = XCTestExpectation(description: description)
        operation(expectation)
        XCTWaiter().wait(for: [expectation], timeout: timeout)
    }
    
    /// 等待多个异步操作完成
    /// - Parameters:
    ///   - timeout: 超时时间
    ///   - descriptions: 等待描述数组
    ///   - operations: 异步操作数组
    static func waitAll(
        timeout: TimeInterval = defaultTimeout,
        descriptions: [String],
        operations: [(XCTestExpectation) -> Void]
    ) {
        let expectations = descriptions.map { XCTestExpectation(description: $0) }
        zip(expectations, operations).forEach { expectation, operation in
            operation(expectation)
        }
        XCTWaiter().wait(for: expectations, timeout: timeout)
    }
    
    /// 等待直到条件满足
    /// - Parameters:
    ///   - timeout: 超时时间
    ///   - interval: 检查间隔
    ///   - condition: 条件闭包
    /// - Returns: 是否在超时前满足条件
    @discardableResult
    static func waitUntil(
        timeout: TimeInterval = defaultTimeout,
        interval: TimeInterval = 0.1,
        condition: @escaping () -> Bool
    ) -> Bool {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                return false
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
        }
        
        return true
    }
    
    /// 执行异步操作并期望成功
    /// - Parameters:
    ///   - timeout: 超时时间
    ///   - operation: 异步操作
    ///   - validation: 结果验证闭包
    static func expectSuccess<T>(
        timeout: TimeInterval = defaultTimeout,
        operation: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
        validation: @escaping (T) -> Bool = { _ in true }
    ) {
        wait(timeout: timeout, description: "Expecting success") { expectation in
            operation { result in
                switch result {
                case .success(let value):
                    XCTAssertTrue(validation(value), "Validation failed for value: \(value)")
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
                }
                expectation.fulfill()
            }
        }
    }
    
    /// 执行异步操作并期望失败
    /// - Parameters:
    ///   - timeout: 超时时间
    ///   - operation: 异步操作
    ///   - errorType: 期望的错误类型
    static func expectFailure<T, E: Error>(
        timeout: TimeInterval = defaultTimeout,
        operation: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
        errorType: E.Type
    ) {
        wait(timeout: timeout, description: "Expecting failure") { expectation in
            operation { result in
                switch result {
                case .success(let value):
                    XCTFail("Expected failure but got success: \(value)")
                case .failure(let error):
                    XCTAssertTrue(error is E, "Expected error of type \(E.self) but got \(type(of: error))")
                }
                expectation.fulfill()
            }
        }
    }
} 