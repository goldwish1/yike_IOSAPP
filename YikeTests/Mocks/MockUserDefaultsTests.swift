import XCTest
@testable import Yike

/// 测试MockUserDefaults类
class MockUserDefaultsTests: YikeBaseTests {
    
    /// 被测试的MockUserDefaults实例
    var mockUserDefaults: MockUserDefaults!
    
    /// 在每个测试方法执行前调用
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
    }
    
    /// 在每个测试方法执行后调用
    override func tearDown() {
        mockUserDefaults = nil
        super.tearDown()
    }
    
    /// 测试设置和获取字符串
    func test_StringValue_SetAndGet_ReturnsCorrectValue() {
        // 准备
        let key = "testString"
        let value = "Hello, World!"
        
        // 执行
        mockUserDefaults.set(value, forKey: key)
        let result = mockUserDefaults.string(forKey: key)
        
        // 验证
        XCTAssertEqual(result, value, "应该返回正确的字符串值")
        XCTAssertTrue(mockUserDefaults.hasKey(key), "应该包含设置的键")
        XCTAssertEqual(mockUserDefaults.operationCount(forKey: key), 2, "应该有两次操作：一次设置，一次获取")
    }
    
    /// 测试设置和获取整数
    func test_IntegerValue_SetAndGet_ReturnsCorrectValue() {
        // 准备
        let key = "testInteger"
        let value = 42
        
        // 执行
        mockUserDefaults.set(value, forKey: key)
        let result = mockUserDefaults.integer(forKey: key)
        
        // 验证
        XCTAssertEqual(result, value, "应该返回正确的整数值")
        XCTAssertTrue(mockUserDefaults.hasKey(key), "应该包含设置的键")
        XCTAssertEqual(mockUserDefaults.operationCount(forKey: key), 2, "应该有两次操作：一次设置，一次获取")
    }
    
    /// 测试设置和获取布尔值
    func test_BoolValue_SetAndGet_ReturnsCorrectValue() {
        // 准备
        let key = "testBool"
        let value = true
        
        // 执行
        mockUserDefaults.set(value, forKey: key)
        let result = mockUserDefaults.bool(forKey: key)
        
        // 验证
        XCTAssertEqual(result, value, "应该返回正确的布尔值")
        XCTAssertTrue(mockUserDefaults.hasKey(key), "应该包含设置的键")
        XCTAssertEqual(mockUserDefaults.operationCount(forKey: key), 2, "应该有两次操作：一次设置，一次获取")
    }
    
    /// 测试移除值
    func test_RemoveObject_KeyExists_RemovesValue() {
        // 准备
        let key = "testRemove"
        let value = "Value to remove"
        mockUserDefaults.set(value, forKey: key)
        
        // 执行
        mockUserDefaults.removeObject(forKey: key)
        let result = mockUserDefaults.string(forKey: key)
        
        // 验证
        XCTAssertNil(result, "移除后应该返回nil")
        XCTAssertFalse(mockUserDefaults.hasKey(key), "移除后不应该包含该键")
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .remove), 1, "应该有一次移除操作")
    }
    
    /// 测试重置
    func test_Reset_AfterOperations_ClearsAllData() {
        // 准备
        mockUserDefaults.set("value1", forKey: "key1")
        mockUserDefaults.set(42, forKey: "key2")
        _ = mockUserDefaults.bool(forKey: "key3")
        
        // 执行
        mockUserDefaults.reset()
        
        // 验证
        XCTAssertNil(mockUserDefaults.string(forKey: "key1"), "重置后应该返回nil")
        XCTAssertEqual(mockUserDefaults.integer(forKey: "key2"), 0, "重置后应该返回默认值0")
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .set), 0, "重置后操作记录应该为空")
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .get), 2, "重置后应该只有重置后的两次获取操作")
    }
    
    /// 测试操作记录
    func test_Operations_MultipleOperations_RecordsCorrectly() {
        // 准备 & 执行
        mockUserDefaults.set("value1", forKey: "key1")
        mockUserDefaults.set(42, forKey: "key2")
        _ = mockUserDefaults.string(forKey: "key1")
        _ = mockUserDefaults.integer(forKey: "key2")
        mockUserDefaults.removeObject(forKey: "key1")
        
        // 验证
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .set), 2, "应该有两次设置操作")
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .get), 2, "应该有两次获取操作")
        XCTAssertEqual(mockUserDefaults.operationCount(ofType: .remove), 1, "应该有一次移除操作")
        XCTAssertEqual(mockUserDefaults.operationCount(forKey: "key1"), 3, "key1应该有三次操作")
        XCTAssertEqual(mockUserDefaults.operationCount(forKey: "key2"), 2, "key2应该有两次操作")
    }
}
