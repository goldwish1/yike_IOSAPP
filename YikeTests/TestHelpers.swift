//
//  TestHelpers.swift
//  YikeTests
//
//  Created by 测试 on 2025/3/14.
//  Updated on 2025/3/21.
//

import Foundation
import XCTest
import AVFoundation
import Vision
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
    
    /// 创建带有文本的测试图像
    static func createTestImage(withText text: String, size: CGSize = CGSize(width: 300, height: 100)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 设置背景为白色
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // 绘制文本
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(origin: CGPoint(x: 0, y: 40), size: size)
        text.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 创建测试音频数据
    static func createTestAudioData(duration: TimeInterval = 3.0) -> Data {
        // 创建简单的WAVE格式音频数据（无实际声音）
        let sampleRate: Int = 44100
        let channels: Int = 2
        let bitsPerSample: Int = 16
        let bytesPerSample = bitsPerSample / 8
        let bytesPerFrame = channels * bytesPerSample
        let numSamples = Int(duration * Double(sampleRate))
        let dataSize = numSamples * bytesPerFrame
        
        // WAVE文件头
        var header = Data()
        
        // RIFF块
        header.append(contentsOf: "RIFF".utf8)
        let fileSize = 36 + dataSize
        header.append(UInt32(fileSize).littleEndianData)
        header.append(contentsOf: "WAVE".utf8)
        
        // 格式块
        header.append(contentsOf: "fmt ".utf8)
        header.append(UInt32(16).littleEndianData)           // 格式块大小
        header.append(UInt16(1).littleEndianData)            // 编码格式（1为PCM）
        header.append(UInt16(channels).littleEndianData)     // 通道数
        header.append(UInt32(sampleRate).littleEndianData)   // 采样率
        header.append(UInt32(sampleRate * bytesPerFrame).littleEndianData) // 每秒字节数
        header.append(UInt16(bytesPerFrame).littleEndianData) // 每帧字节数
        header.append(UInt16(bitsPerSample).littleEndianData) // 每样本比特数
        
        // 数据块
        header.append(contentsOf: "data".utf8)
        header.append(UInt32(dataSize).littleEndianData)     // 数据大小
        
        // 创建实际的音频数据（静音）
        var audioData = header
        let sampleValue: UInt16 = 0 // 静音
        
        for _ in 0..<numSamples {
            for _ in 0..<channels {
                audioData.append(sampleValue.littleEndianData)
            }
        }
        
        return audioData
    }
    
    /// 生成测试记忆项目
    static func generateTestMemoryItems(count: Int = 10) -> [MemoryItem] {
        var items: [MemoryItem] = []
        
        let now = Date()
        let calendar = Calendar.current
        
        for i in 0..<count {
            let id = UUID()
            let title = "测试项目\(i+1)"
            let content = "这是第\(i+1)个测试内容，用于测试应用功能。"
            let progress = Double.random(in: 0...1)
            let reviewStage = Int.random(in: 0...5)
            
            // 随机创建日期（过去30天内）
            let daysAgo = Int.random(in: 0...30)
            let createdAt = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            
            // 随机最后复习日期（创建日期之后）
            let lastReviewedAt: Date?
            if reviewStage > 0 {
                let daysAfterCreation = Int.random(in: 0...(daysAgo-1))
                lastReviewedAt = calendar.date(byAdding: .day, value: daysAfterCreation, to: createdAt)
            } else {
                lastReviewedAt = nil
            }
            
            let item = MemoryItem(
                id: id,
                title: title,
                content: content,
                progress: progress,
                reviewStage: reviewStage,
                createdAt: createdAt,
                lastReviewedAt: lastReviewedAt
            )
            
            items.append(item)
        }
        
        return items
    }
    
    /// 生成测试积分记录
    static func generateTestPointsRecords(count: Int = 20) -> [PointsRecord] {
        var records: [PointsRecord] = []
        
        let now = Date()
        let calendar = Calendar.current
        
        for i in 0..<count {
            let id = UUID()
            
            // 随机类型
            let typeRandom = Int.random(in: 0...100)
            let type: PointsRecordType
            let amount: Int
            let reason: String
            
            if typeRandom < 30 {
                // 30%的概率是充值
                type = .recharge
                amount = [100, 300, 600, 1000][Int.random(in: 0...3)]
                reason = "充值\(amount)积分"
            } else if typeRandom < 90 {
                // 60%的概率是消费
                type = .consume
                amount = -Int.random(in: 1...10) * 5 // 5的倍数，最多-50
                reason = ["在线语音", "特殊功能", "高级服务"][Int.random(in: 0...2)]
            } else {
                // 10%的概率是系统赠送
                type = .system
                amount = Int.random(in: 1...5) * 20 // 20的倍数，最多100
                reason = ["新用户奖励", "活动奖励", "签到奖励"][Int.random(in: 0...2)]
            }
            
            // 随机日期（过去60天内）
            let daysAgo = Int.random(in: 0...60)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            
            let record = PointsRecord(
                id: id,
                amount: amount,
                type: type,
                reason: reason,
                date: date
            )
            
            records.append(record)
        }
        
        // 按日期排序（从新到旧）
        records.sort { $0.date > $1.date }
        
        return records
    }
    
    /// 对URL Session进行模拟
    static func swizzleURLSession() {
        // 使用方法交换替换URLSession的dataTask方法
        // 这是一个复杂的例子，需要根据具体测试场景定制
    }
}

// MARK: - 扩展类型

extension UInt16 {
    /// 转换为小端字节序数据
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
}

extension UInt32 {
    /// 转换为小端字节序数据
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
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
    
    override func removeItem(at url: URL) throws {
        try removeItem(atPath: url.path)
    }
    
    func reset() {
        files.removeAll()
    }
}

/// 模拟Vision请求处理
class MockVisionTextRecognitionRequest: VNRecognizeTextRequest {
    var mockResults: [VNRecognizedTextObservation]?
    var mockError: Error?
    
    override func perform(requests: [VNRequest], on imageData: Data, orientation: CGImagePropertyOrientation) throws -> Void {
        if let error = mockError {
            throw error
        }
        
        // 设置模拟结果
        if let mockResults = mockResults {
            for request in requests {
                if let textRequest = request as? VNRecognizeTextRequest {
                    textRequest.results = mockResults
                }
            }
        }
    }
}

/// 模拟通知中心
class MockNotificationCenter: NotificationCenter {
    var postedNotifications: [(name: NSNotification.Name, object: Any?, userInfo: [AnyHashable: Any]?)] = []
    
    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        postedNotifications.append((name: aName, object: anObject, userInfo: aUserInfo))
        super.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
    
    func reset() {
        postedNotifications.removeAll()
    }
    
    func wasNotificationPosted(name: NSNotification.Name) -> Bool {
        return postedNotifications.contains { $0.name == name }
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
    
    /// 断言一个集合包含特定元素
    func XCTAssertCollectionContains<T: Equatable>(_ collection: [T], _ element: T, _ message: String = "") {
        XCTAssertTrue(collection.contains(element), message)
    }
    
    /// 断言一个集合不包含特定元素
    func XCTAssertCollectionNotContains<T: Equatable>(_ collection: [T], _ element: T, _ message: String = "") {
        XCTAssertFalse(collection.contains(element), message)
    }
    
    /// 断言一个集合是另一个集合的子集
    func XCTAssertIsSubset<T: Equatable>(_ subset: [T], _ superset: [T], _ message: String = "") {
        for element in subset {
            XCTAssertTrue(superset.contains(element), message)
        }
    }
} 