import XCTest
@testable import Yike

/// 存储测试基类
/// 提供数据存储相关测试的基础设施
class StorageTestCase: YikeBaseTests {
    
    // MARK: - Properties
    
    /// Mock存储服务
    var mockStorageService: MockStorageService!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
    }
    
    override func tearDown() {
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    /// 验证数据存储操作是否发生
    /// - Parameter key: 存储键值
    /// - Returns: 是否发生存储操作
    func verifyStore(for key: String) -> Bool {
        return mockStorageService.verifyCall("store_\(key)")
    }
    
    /// 验证数据检索操作是否发生
    /// - Parameter key: 存储键值
    /// - Returns: 是否发生检索操作
    func verifyRetrieve(for key: String) -> Bool {
        return mockStorageService.verifyCall("retrieve_\(key)")
    }
} 