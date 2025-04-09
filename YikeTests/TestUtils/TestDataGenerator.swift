import Foundation
@testable import Yike

/// 测试数据生成器
/// 提供生成各种测试数据的静态方法
class TestDataGenerator {
    
    // MARK: - 文本数据
    
    /// 生成测试标题
    /// - Parameter length: 标题长度
    /// - Returns: 生成的标题
    static func generateTitle(length: Int = 10) -> String {
        let characters = "测试标题内容示例文本"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// 生成测试内容
    /// - Parameter length: 内容长度
    /// - Returns: 生成的内容
    static func generateContent(length: Int = 50) -> String {
        let sentences = [
            "这是一段测试内容。",
            "用于验证应用的基本功能。",
            "包含多个中文句子。",
            "确保数据处理正确。"
        ]
        
        var content = ""
        while content.count < length {
            content += sentences.randomElement() ?? sentences[0]
        }
        return String(content.prefix(length))
    }
    
    // MARK: - 数值数据
    
    /// 生成测试积分
    /// - Parameter range: 积分范围
    /// - Returns: 生成的积分值
    static func generatePoints(in range: ClosedRange<Int> = 0...1000) -> Int {
        return Int.random(in: range)
    }
    
    /// 生成测试时间戳
    /// - Parameter range: 时间范围（相对于现在的天数）
    /// - Returns: 生成的时间戳
    static func generateTimestamp(daysRange range: ClosedRange<Int> = -7...7) -> Date {
        let randomDays = Double.random(in: Double(range.lowerBound)...Double(range.upperBound))
        return Date().addingTimeInterval(randomDays * 24 * 60 * 60)
    }
    
    // MARK: - 二进制数据
    
    /// 生成测试音频数据
    /// - Parameter size: 数据大小（字节）
    /// - Returns: 生成的音频数据
    static func generateAudioData(size: Int = 1024) -> Data {
        return Data((0..<size).map { _ in UInt8.random(in: 0...255) })
    }
} 