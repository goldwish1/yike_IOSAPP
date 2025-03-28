import XCTest
@testable import Yike

/// StorageTestCase的测试类
final class StorageTestCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: StorageTestCase!
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        sut = StorageTestCase()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// 测试存储服务初始化
    func test_mockStorageService_initialization() {
        // When
        sut.setUp()
        
        // Then
        XCTAssertNotNil(sut.mockStorageService)
        
        // When
        sut.tearDown()
        
        // Then
        XCTAssertNil(sut.mockStorageService)
    }
    
    /// 测试存储操作验证
    func test_verifyStore() {
        // Given
        sut.setUp()
        let key = "test_key"
        let value = "test_value"
        
        // When - 没有存储操作
        let noStoreResult = sut.verifyStore(for: key)
        
        // Then
        XCTAssertFalse(noStoreResult)
        
        // When - 发生存储操作
        sut.mockStorageService.store(value, for: key)
        let hasStoreResult = sut.verifyStore(for: key)
        
        // Then
        XCTAssertTrue(hasStoreResult)
    }
    
    /// 测试检索操作验证
    func test_verifyRetrieve() {
        // Given
        sut.setUp()
        let key = "test_key"
        
        // When - 没有检索操作
        let noRetrieveResult = sut.verifyRetrieve(for: key)
        
        // Then
        XCTAssertFalse(noRetrieveResult)
        
        // When - 发生检索操作
        _ = sut.mockStorageService.retrieve(key)
        let hasRetrieveResult = sut.verifyRetrieve(for: key)
        
        // Then
        XCTAssertTrue(hasRetrieveResult)
    }
} 