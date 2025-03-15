import Foundation
@testable import Yike

/// 模拟UserDefaults，用于测试
class MockUserDefaults {
    
    /// 存储的值
    private var storage: [String: Any] = [:]
    
    /// 记录的操作
    private(set) var operations: [Operation] = []
    
    /// 初始化
    init() {}
    
    /// 清除所有数据和操作记录
    func reset() {
        storage.removeAll()
        operations.removeAll()
    }
    
    // MARK: - 存储操作
    
    /// 设置值
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
        operations.append(.set(key: key, value: value))
    }
    
    /// 移除值
    /// - Parameter key: 键
    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
        operations.append(.remove(key: key))
    }
    
    // MARK: - 读取操作
    
    /// 获取对象
    /// - Parameter key: 键
    /// - Returns: 对象
    func object(forKey key: String) -> Any? {
        operations.append(.get(key: key))
        return storage[key]
    }
    
    /// 获取字符串
    /// - Parameter key: 键
    /// - Returns: 字符串
    func string(forKey key: String) -> String? {
        operations.append(.get(key: key))
        return storage[key] as? String
    }
    
    /// 获取整数
    /// - Parameter key: 键
    /// - Returns: 整数
    func integer(forKey key: String) -> Int {
        operations.append(.get(key: key))
        return storage[key] as? Int ?? 0
    }
    
    /// 获取浮点数
    /// - Parameter key: 键
    /// - Returns: 浮点数
    func double(forKey key: String) -> Double {
        operations.append(.get(key: key))
        return storage[key] as? Double ?? 0.0
    }
    
    /// 获取布尔值
    /// - Parameter key: 键
    /// - Returns: 布尔值
    func bool(forKey key: String) -> Bool {
        operations.append(.get(key: key))
        return storage[key] as? Bool ?? false
    }
    
    /// 获取URL
    /// - Parameter key: 键
    /// - Returns: URL
    func url(forKey key: String) -> URL? {
        operations.append(.get(key: key))
        return storage[key] as? URL
    }
    
    /// 获取数组
    /// - Parameter key: 键
    /// - Returns: 数组
    func array(forKey key: String) -> [Any]? {
        operations.append(.get(key: key))
        return storage[key] as? [Any]
    }
    
    /// 获取字典
    /// - Parameter key: 键
    /// - Returns: 字典
    func dictionary(forKey key: String) -> [String: Any]? {
        operations.append(.get(key: key))
        return storage[key] as? [String: Any]
    }
    
    /// 获取数据
    /// - Parameter key: 键
    /// - Returns: 数据
    func data(forKey key: String) -> Data? {
        operations.append(.get(key: key))
        return storage[key] as? Data
    }
    
    /// 获取日期
    /// - Parameter key: 键
    /// - Returns: 日期
    func date(forKey key: String) -> Date? {
        operations.append(.get(key: key))
        return storage[key] as? Date
    }
    
    // MARK: - 验证方法
    
    /// 验证是否设置了键
    /// - Parameter key: 键
    /// - Returns: 是否设置
    func hasKey(_ key: String) -> Bool {
        return storage.keys.contains(key)
    }
    
    /// 验证是否有特定操作
    /// - Parameter operation: 操作
    /// - Returns: 是否有操作
    func hasOperation(_ operation: Operation) -> Bool {
        return operations.contains(operation)
    }
    
    /// 获取特定键的操作次数
    /// - Parameter key: 键
    /// - Returns: 操作次数
    func operationCount(forKey key: String) -> Int {
        return operations.filter { operation in
            switch operation {
            case .set(let k, _), .get(let k), .remove(let k):
                return k == key
            }
        }.count
    }
    
    /// 获取特定类型的操作次数
    /// - Parameter type: 操作类型
    /// - Returns: 操作次数
    func operationCount(ofType type: OperationType) -> Int {
        return operations.filter { operation in
            switch (operation, type) {
            case (.set, .set), (.get, .get), (.remove, .remove):
                return true
            default:
                return false
            }
        }.count
    }
    
    // MARK: - 操作类型和操作
    
    /// 操作类型
    enum OperationType {
        case set
        case get
        case remove
    }
    
    /// 操作
    enum Operation: Equatable {
        case set(key: String, value: Any?)
        case get(key: String)
        case remove(key: String)
        
        static func == (lhs: Operation, rhs: Operation) -> Bool {
            switch (lhs, rhs) {
            case (.set(let lhsKey, _), .set(let rhsKey, _)):
                return lhsKey == rhsKey
            case (.get(let lhsKey), .get(let rhsKey)):
                return lhsKey == rhsKey
            case (.remove(let lhsKey), .remove(let rhsKey)):
                return lhsKey == rhsKey
            default:
                return false
            }
        }
    }
}
