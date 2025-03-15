import XCTest
@testable import Yike

/// 基础测试类，提供通用的测试环境设置和清理功能
/// 所有测试类都应继承自此类
class YikeBaseTests: XCTestCase {
    
    /// 在每个测试方法执行前调用
    override func setUp() {
        super.setUp()
        // 设置通用的测试环境
        setupTestEnvironment()
    }
    
    /// 在每个测试方法执行后调用
    override func tearDown() {
        // 清理通用的测试环境
        cleanupTestEnvironment()
        super.tearDown()
    }
    
    /// 设置测试环境
    private func setupTestEnvironment() {
        // 可以在这里添加通用的测试环境设置
        // 例如：重置单例、设置模拟对象等
    }
    
    /// 清理测试环境
    private func cleanupTestEnvironment() {
        // 可以在这里添加通用的测试环境清理
        // 例如：清理临时文件、重置状态等
    }
    
    // MARK: - 辅助方法
    
    /// 等待条件满足，带超时
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - description: 等待描述，用于调试
    ///   - condition: 条件闭包，返回true表示条件满足
    /// - Returns: 条件是否在超时前满足
    func waitForCondition(timeout: TimeInterval = 5.0, description: String = "等待条件满足", condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTestExpectation(description: description)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
        timer.invalidate()
        return result
    }
    
    /// 创建临时文件
    /// - Parameters:
    ///   - name: 文件名
    ///   - data: 文件数据
    /// - Returns: 临时文件URL
    func createTemporaryFile(withName name: String, data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(name)
        
        try? data.write(to: fileURL)
        return fileURL
    }
    
    /// 删除临时文件
    /// - Parameter url: 文件URL
    func deleteTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// 模拟延迟执行
    /// - Parameters:
    ///   - seconds: 延迟秒数
    ///   - closure: 延迟后执行的闭包
    func delay(_ seconds: TimeInterval, closure: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: "延迟\(seconds)秒")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: seconds + 1.0)
    }
}
