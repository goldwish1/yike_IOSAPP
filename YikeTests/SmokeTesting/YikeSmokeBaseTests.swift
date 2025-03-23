import XCTest
@testable import Yike

/// 忆刻应用冒烟测试的基础测试类
/// 提供所有冒烟测试用例的共享设置和功能
class YikeSmokeBaseTests: XCTestCase {
    
    // 常用测试数据
    struct TestData {
        static let testTitle = "测试标题"
        static let testContent = "这是一段测试内容，用于验证应用基本功能。"
        static let defaultPoints = 100
    }
    
    // 共享的数据管理器实例
    var dataManager: DataManager!
    
    // 共享的设置管理器实例
    var settingsManager: SettingsManager!
    
    // 运行测试前的设置
    override func setUp() {
        super.setUp()
        
        // 初始化必要的服务
        dataManager = DataManager.shared
        settingsManager = SettingsManager.shared
        
        // 设置测试环境
        setupTestEnvironment()
    }
    
    // 运行测试后的清理
    override func tearDown() {
        // 清理测试数据
        cleanupTestData()
        
        // 清空引用
        dataManager = nil
        settingsManager = nil
        
        super.tearDown()
    }
    
    // 设置测试环境
    private func setupTestEnvironment() {
        // 确保使用测试数据存储
        UserDefaults.standard.set(true, forKey: "IsRunningTests")
        
        // 重置数据以确保一致的测试环境
        resetTestData()
    }
    
    // 重置测试数据为初始状态
    func resetTestData() {
        // 清除现有数据
        cleanupTestData()
        
        // 创建测试内容数据
        createTestMemoryItems()
        
        // 设置初始积分
        setInitialPoints()
    }
    
    // 创建测试用的记忆项目
    private func createTestMemoryItems() {
        // 创建3个测试记忆项
        for i in 1...3 {
            let title = "\(TestData.testTitle) \(i)"
            let content = "\(TestData.testContent) 项目编号：\(i)"
            
            // 使用DataManager创建内容
            dataManager.createMemoryItem(title: title, content: content)
        }
    }
    
    // 设置初始积分
    private func setInitialPoints() {
        // 清空当前积分记录
        dataManager.deleteAllData()
        
        // 添加初始积分记录
        dataManager.addPoints(TestData.defaultPoints, reason: "测试初始积分")
    }
    
    // 清理测试数据
    private func cleanupTestData() {
        // 使用DataManager的删除所有数据方法
        dataManager.deleteAllData()
    }
    
    // MARK: - 辅助方法
    
    // 模拟网络状态更改
    func simulateNetworkState(connected: Bool) {
        #if DEBUG
        // 仅在测试环境中修改NetworkMonitor状态
        if ProcessInfo.processInfo.arguments.contains("--UITesting") {
            NotificationCenter.default.post(
                name: Notification.Name(connected ? "UITestNetworkConnected" : "UITestNetworkDisconnected"),
                object: nil
            )
        }
        #endif
    }
    
    // 等待条件满足（带超时）
    func waitForCondition(timeout: TimeInterval = 5.0, condition: @escaping () -> Bool) -> Bool {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                return false // 超时
            }
            
            // 等待一小段时间
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
        return true // 条件满足
    }
    
    // 验证内存项是否存在
    func verifyMemoryItemExists(withTitle title: String) -> Bool {
        // 使用DataManager获取所有记忆项，然后筛选
        return dataManager.getAllMemoryItems().contains { $0.title.contains(title) }
    }
    
    // 验证积分记录是否存在
    func verifyPointsRecordExists(withReason reason: String) -> Bool {
        // 使用DataManager获取所有积分记录，然后筛选
        return dataManager.pointsRecords.contains { $0.reason.contains(reason) }
    }
    
    // 获取当前积分余额
    func getCurrentPoints() -> Int {
        return dataManager.points
    }
} 