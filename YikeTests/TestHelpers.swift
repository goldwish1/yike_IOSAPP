//
//  TestHelpers.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//

import Foundation
import XCTest
@testable import Yike

// MARK: - 测试辅助工具

/// 测试辅助工具类
class TestHelpers {
    
    /// 创建临时文件
    static func createTemporaryFile(withName name: String, data: Data) -> URL? {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("创建临时文件失败: \(error)")
            return nil
        }
    }
    
    /// 删除临时文件
    static func deleteTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("删除临时文件失败: \(error)")
        }
    }
    
    /// 等待条件满足
    static func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval = 5.0) -> Bool {
        let expectation = XCTestExpectation(description: "等待条件满足")
        
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
    
    /// 模拟延迟执行
    static func delay(_ seconds: TimeInterval, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}

// MARK: - 模拟对象

/// 模拟用户默认设置
class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    override func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }
    
    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    override func stringArray(forKey defaultName: String) -> [String]? {
        return storage[defaultName] as? [String]
    }
    
    override func double(forKey defaultName: String) -> Double {
        return storage[defaultName] as? Double ?? 0.0
    }
    
    override func float(forKey defaultName: String) -> Float {
        return storage[defaultName] as? Float ?? 0.0
    }
    
    func reset() {
        storage.removeAll()
    }
}

/// 模拟文件管理器
class MockFileManager: FileManager {
    private var files: [String: Data] = [:]
    
    override func fileExists(atPath path: String) -> Bool {
        return files[path] != nil
    }
    
    override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        let exists = files[path] != nil
        if let isDirectory = isDirectory {
            isDirectory.pointee = ObjCBool(false)
        }
        return exists
    }
    
    override func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        if let data = data {
            files[path] = data
            return true
        }
        return false
    }
    
    override func contents(atPath path: String) -> Data? {
        return files[path]
    }
    
    override func removeItem(atPath path: String) throws {
        if files[path] != nil {
            files.removeValue(forKey: path)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
    }
    
    func reset() {
        files.removeAll()
    }
}

// MARK: - 测试扩展

extension XCTestCase {
    
    /// 等待指定时间
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "等待\(duration)秒")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: duration + 0.5)
    }
    
    /// 断言两个浮点数近似相等
    func XCTAssertApproximatelyEqual(_ expression1: Double, _ expression2: Double, accuracy: Double = 0.0001, _ message: String = "") {
        XCTAssertTrue(abs(expression1 - expression2) <= accuracy, message)
    }
    
    /// 断言两个浮点数近似相等（Float版本）
    func XCTAssertApproximatelyEqualFloat(_ expression1: Float, _ expression2: Float, accuracy: Float = 0.0001, _ message: String = "") {
        XCTAssertTrue(abs(expression1 - expression2) <= accuracy, message)
    }
} 