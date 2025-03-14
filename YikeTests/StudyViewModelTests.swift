import XCTest
@testable import Yike

class StudyViewModelTests: XCTestCase {
    
    var viewModel: StudyViewModel!
    var mockDataManager: MockDataManager!
    
    override func setUp() {
        super.setUp()
        viewModel = StudyViewModel()
        mockDataManager = MockDataManager()
    }
    
    override func tearDown() {
        viewModel = nil
        mockDataManager = nil
        super.tearDown()
    }
    
    func testCalculateNextReviewDate() {
        // 第3阶段
        let stage3Date = viewModel.calculateNextReviewDate(forStage: 3, strategy: .standard)
        // 验证是第4天
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: Date(), to: stage3Date).day, 4)
        
        // 第4阶段
        let stage4Date = viewModel.calculateNextReviewDate(forStage: 4, strategy: .standard)
        // 验证是第7天
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: Date(), to: stage4Date).day, 7)
        
        // 第5阶段
        let stage5Date = viewModel.calculateNextReviewDate(forStage: 5, strategy: .standard)
        // 验证是第15天
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: Date(), to: stage5Date).day, 15)
    }
    
    func testDifferentReviewStrategies() {
        // 测试不同的复习策略
        
        // 简单策略（间隔更长）
        let easyDate = viewModel.calculateNextReviewDate(forStage: 2, strategy: .easy)
        // 标准策略
        let standardDate = viewModel.calculateNextReviewDate(forStage: 2, strategy: .standard)
        // 密集策略（间隔更短）
        let intensiveDate = viewModel.calculateNextReviewDate(forStage: 2, strategy: .intensive)
        
        // 验证简单策略的间隔比标准长
        XCTAssertGreaterThan(easyDate, standardDate)
        // 验证密集策略的间隔比标准短
        XCTAssertLessThan(intensiveDate, standardDate)
    }
    
    // MARK: - 测试学习进度计算
    
    func testCalculateOverallProgress() {
        // 加载测试数据
        viewModel.loadStatistics()
        
        // 计算总体进度
        let progress = viewModel.calculateOverallProgress()
        
        // 验证进度计算
        // 假设有2个完成项目，总共5个项目
        XCTAssertEqual(progress, 0.4)
    }
    
    func testUpdateItemProgress() {
        // 获取测试项目
        guard let item = mockDataManager.getAllMemoryItems().first else {
            XCTFail("没有测试项目")
            return
        }
        
        // 更新项目进度
        viewModel.updateItemProgress(itemId: item.id, newProgress: 0.75)
        
        // 验证进度已更新
        let updatedItem = mockDataManager.getMemoryItem(id: item.id)
        XCTAssertEqual(updatedItem?.progress, 0.75)
        
        // 重新加载统计
        viewModel.loadStatistics()
        
        // 验证总体统计已更新
        XCTAssertNotEqual(viewModel.calculateOverallProgress(), 0.4)
    }
}

// MARK: - 辅助类

/// 模拟数据管理器
class MockDataManager: DataManager {
    private var memoryItems: [MemoryItem] = []
    
    override func getAllMemoryItems() -> [MemoryItem] {
        return memoryItems
    }
    
    override func getMemoryItem(id: UUID) -> MemoryItem? {
        return memoryItems.first { $0.id == id }
    }
    
    override func updateMemoryItem(id: UUID, title: String? = nil, content: String? = nil, progress: Double? = nil, reviewStage: Int? = nil) -> Bool {
        if let index = memoryItems.firstIndex(where: { $0.id == id }) {
            var item = memoryItems[index]
            
            if let title = title {
                item.title = title
            }
            
            if let content = content {
                item.content = content
            }
            
            if let progress = progress {
                item.progress = progress
            }
            
            if let reviewStage = reviewStage {
                item.reviewStage = reviewStage
            }
            
            memoryItems[index] = item
            return true
        }
        return false
    }
    
    override func createMemoryItem(title: String, content: String) -> MemoryItem {
        let item = MemoryItem(id: UUID(), title: title, content: content, progress: 0.0, reviewStage: 0)
        memoryItems.append(item)
        return item
    }
    
    override func deleteMemoryItem(id: UUID) -> Bool {
        if let index = memoryItems.firstIndex(where: { $0.id == id }) {
            memoryItems.remove(at: index)
            return true
        }
        return false
    }
    
    override func deleteAllData() {
        memoryItems.removeAll()
    }
    
    func addTestMemoryItems() {
        // 添加测试数据
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        // 已完成项目
        memoryItems.append(
            MemoryItem(id: UUID(), title: "已完成项目1", content: "内容1", progress: 1.0, reviewStage: 5, 
                      createdAt: twoDaysAgo, lastReviewedAt: yesterday)
        )
        memoryItems.append(
            MemoryItem(id: UUID(), title: "已完成项目2", content: "内容2", progress: 1.0, reviewStage: 5, 
                      createdAt: twoDaysAgo, lastReviewedAt: yesterday)
        )
        
        // 进行中项目，待复习
        memoryItems.append(
            MemoryItem(id: UUID(), title: "待复习项目1", content: "内容3", progress: 0.6, reviewStage: 2, 
                      createdAt: twoDaysAgo, lastReviewedAt: twoDaysAgo)
        )
        memoryItems.append(
            MemoryItem(id: UUID(), title: "待复习项目2", content: "内容4", progress: 0.4, reviewStage: 1, 
                      createdAt: yesterday, lastReviewedAt: yesterday)
        )
        
        // 新添加项目
        memoryItems.append(
            MemoryItem(id: UUID(), title: "新项目", content: "内容5", progress: 0.0, reviewStage: 0, 
                      createdAt: now, lastReviewedAt: nil)
        )
    }
} 