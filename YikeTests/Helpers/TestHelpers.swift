import XCTest
import Foundation
@testable import Yike

/// 测试辅助工具类，提供通用的测试功能
struct TestHelpers {
    
    // MARK: - 文件操作
    
    /// 创建临时文件
    /// - Parameters:
    ///   - name: 文件名
    ///   - data: 文件数据
    /// - Returns: 临时文件URL
    static func createTemporaryFile(withName name: String, data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(name)
        
        try? data.write(to: fileURL)
        return fileURL
    }
    
    /// 删除临时文件
    /// - Parameter url: 文件URL
    static func deleteTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// 创建临时目录
    /// - Parameter name: 目录名
    /// - Returns: 临时目录URL
    static func createTemporaryDirectory(withName name: String) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let directoryURL = tempDirectory.appendingPathComponent(name)
        
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        return directoryURL
    }
    
    /// 删除临时目录
    /// - Parameter url: 目录URL
    static func deleteTemporaryDirectory(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - 异步测试支持
    
    /// 等待条件满足，带超时
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - description: 等待描述，用于调试
    ///   - condition: 条件闭包，返回true表示条件满足
    /// - Returns: 条件是否在超时前满足
    static func waitForCondition(timeout: TimeInterval = 5.0, description: String = "等待条件满足", condition: @escaping () -> Bool) -> Bool {
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
    
    /// 模拟延迟执行
    /// - Parameters:
    ///   - seconds: 延迟秒数
    ///   - closure: 延迟后执行的闭包
    static func delay(_ seconds: TimeInterval, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
        }
    }
    
    // MARK: - 随机数据生成
    
    /// 生成随机字符串
    /// - Parameter length: 字符串长度
    /// - Returns: 随机字符串
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    /// 生成随机整数
    /// - Parameters:
    ///   - min: 最小值
    ///   - max: 最大值
    /// - Returns: 随机整数
    static func randomInt(min: Int, max: Int) -> Int {
        return Int.random(in: min...max)
    }
    
    /// 生成随机布尔值
    /// - Returns: 随机布尔值
    static func randomBool() -> Bool {
        return Bool.random()
    }
    
    /// 生成随机日期
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 随机日期
    static func randomDate(from startDate: Date, to endDate: Date) -> Date {
        let startSeconds = startDate.timeIntervalSince1970
        let endSeconds = endDate.timeIntervalSince1970
        let randomSeconds = Double.random(in: startSeconds...endSeconds)
        return Date(timeIntervalSince1970: randomSeconds)
    }
    
    // MARK: - 测试数据生成
    
    /// 生成测试文本内容
    /// - Parameter wordCount: 单词数量
    /// - Returns: 测试文本
    static func generateTestContent(wordCount: Int) -> String {
        let words = ["忆刻", "记忆", "学习", "背诵", "古诗", "文言文", "语文", "英语", "数学", "物理", "化学", "生物", "历史", "地理", "政治", "艺术", "音乐", "体育", "计算机", "编程", "科学", "技术", "工程", "数据", "分析", "研究", "实验", "理论", "实践", "应用", "创新", "发展", "进步", "未来", "智能", "人工智能", "机器学习", "深度学习", "神经网络", "算法", "模型", "系统", "架构", "设计", "开发", "测试", "部署", "维护", "升级", "优化"]
        
        var result = [String]()
        for _ in 0..<wordCount {
            result.append(words.randomElement()!)
        }
        
        return result.joined(separator: " ")
    }
    
    /// 生成测试标题
    /// - Returns: 测试标题
    static func generateTestTitle() -> String {
        let titles = ["古诗背诵", "文言文学习", "英语单词", "数学公式", "物理定律", "化学方程式", "生物概念", "历史事件", "地理知识", "政治理论", "艺术鉴赏", "音乐理论", "体育规则", "计算机基础", "编程语言", "科学原理", "技术应用", "工程实践", "数据结构", "分析方法"]
        
        return titles.randomElement()!
    }
}
