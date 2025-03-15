import Foundation
@testable import Yike

/// 测试数据提供者，生成测试所需的示例数据
struct TestDataProvider {
    
    // MARK: - 内容数据
    
    /// 生成测试内容数据
    /// - Parameters:
    ///   - count: 内容数量
    ///   - withRandomData: 是否使用随机数据
    /// - Returns: 测试内容数组
    static func generateTestContents(count: Int, withRandomData: Bool = true) -> [Content] {
        var contents = [Content]()
        
        for i in 0..<count {
            let title = withRandomData ? TestHelpers.generateTestTitle() : "测试内容 \(i+1)"
            let text = withRandomData ? TestHelpers.generateTestContent(wordCount: 20) : "这是测试内容 \(i+1) 的正文，用于单元测试。"
            let createdAt = withRandomData ? TestHelpers.randomDate(from: Date().addingTimeInterval(-30*24*60*60), to: Date()) : Date()
            let updatedAt = createdAt
            
            let content = Content(id: UUID(), title: title, text: text, createdAt: createdAt, updatedAt: updatedAt)
            contents.append(content)
        }
        
        return contents
    }
    
    /// 生成单个测试内容
    /// - Parameter withRandomData: 是否使用随机数据
    /// - Returns: 测试内容
    static func generateTestContent(withRandomData: Bool = true) -> Content {
        return generateTestContents(count: 1, withRandomData: withRandomData)[0]
    }
    
    // MARK: - 积分数据
    
    /// 生成测试积分记录
    /// - Parameters:
    ///   - count: 记录数量
    ///   - withRandomData: 是否使用随机数据
    /// - Returns: 测试积分记录数组
    static func generateTestPointRecords(count: Int, withRandomData: Bool = true) -> [PointRecord] {
        var records = [PointRecord]()
        
        let types: [PointRecordType] = [.consumption, .recharge, .reward]
        let descriptions: [String] = ["在线语音合成", "积分充值", "新用户奖励", "OCR文本识别", "语音试听"]
        
        for i in 0..<count {
            let type = withRandomData ? types.randomElement()! : (i % 3 == 0 ? .recharge : .consumption)
            let amount = withRandomData ? TestHelpers.randomInt(min: 1, max: 100) * (type == .consumption ? -1 : 1) : (type == .consumption ? -5 : 100)
            let description = withRandomData ? descriptions.randomElement()! : (type == .consumption ? "在线语音合成" : "积分充值")
            let createdAt = withRandomData ? TestHelpers.randomDate(from: Date().addingTimeInterval(-30*24*60*60), to: Date()) : Date()
            
            let record = PointRecord(id: UUID(), type: type, amount: amount, description: description, createdAt: createdAt)
            records.append(record)
        }
        
        return records
    }
    
    /// 生成单个测试积分记录
    /// - Parameter withRandomData: 是否使用随机数据
    /// - Returns: 测试积分记录
    static func generateTestPointRecord(withRandomData: Bool = true) -> PointRecord {
        return generateTestPointRecords(count: 1, withRandomData: withRandomData)[0]
    }
    
    // MARK: - 学习数据
    
    /// 生成测试学习记录
    /// - Parameters:
    ///   - count: 记录数量
    ///   - withRandomData: 是否使用随机数据
    /// - Returns: 测试学习记录数组
    static func generateTestStudyRecords(count: Int, withRandomData: Bool = true) -> [StudyRecord] {
        var records = [StudyRecord]()
        
        for i in 0..<count {
            let contentId = UUID()
            let duration = withRandomData ? TimeInterval(TestHelpers.randomInt(min: 60, max: 600)) : TimeInterval(300)
            let completedAt = withRandomData ? TestHelpers.randomDate(from: Date().addingTimeInterval(-30*24*60*60), to: Date()) : Date()
            
            let record = StudyRecord(id: UUID(), contentId: contentId, duration: duration, completedAt: completedAt)
            records.append(record)
        }
        
        return records
    }
    
    /// 生成单个测试学习记录
    /// - Parameter withRandomData: 是否使用随机数据
    /// - Returns: 测试学习记录
    static func generateTestStudyRecord(withRandomData: Bool = true) -> StudyRecord {
        return generateTestStudyRecords(count: 1, withRandomData: withRandomData)[0]
    }
    
    // MARK: - 模型结构
    
    /// 内容模型
    struct Content: Identifiable, Codable {
        let id: UUID
        var title: String
        var text: String
        let createdAt: Date
        var updatedAt: Date
    }
    
    /// 积分记录类型
    enum PointRecordType: String, Codable {
        case consumption = "consumption"
        case recharge = "recharge"
        case reward = "reward"
    }
    
    /// 积分记录模型
    struct PointRecord: Identifiable, Codable {
        let id: UUID
        let type: PointRecordType
        let amount: Int
        let description: String
        let createdAt: Date
    }
    
    /// 学习记录模型
    struct StudyRecord: Identifiable, Codable {
        let id: UUID
        let contentId: UUID
        let duration: TimeInterval
        let completedAt: Date
    }
}
