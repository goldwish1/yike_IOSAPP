import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var memoryItems: [MemoryItem] = []
    @Published var points: Int = 100 // 新用户默认100积分
    @Published var pointsRecords: [PointsRecord] = []
    
    private init() {
        // 从本地加载数据
        loadData()
        
        // 添加一些测试数据
        if memoryItems.isEmpty {
            addSampleData()
        }
    }
    
    // MARK: - Memory Items Methods
    
    func addMemoryItem(_ item: MemoryItem) {
        memoryItems.append(item)
        saveData()
    }
    
    func updateMemoryItem(_ item: MemoryItem) {
        if let index = memoryItems.firstIndex(where: { $0.id == item.id }) {
            memoryItems[index] = item
            saveData()
        }
    }
    
    func deleteMemoryItem(id: UUID) {
        memoryItems.removeAll(where: { $0.id == id })
        saveData()
    }
    
    func deleteMemoryItem(_ item: MemoryItem) {
        deleteMemoryItem(id: item.id)
    }
    
    // MARK: - Points Management
    
    func addPoints(_ amount: Int, reason: String) {
        points += amount
        let record = PointsRecord(id: UUID(), amount: amount, reason: reason, date: Date())
        pointsRecords.append(record)
        saveData()
    }
    
    func deductPoints(_ amount: Int, reason: String) -> Bool {
        if points >= amount {
            points -= amount
            let record = PointsRecord(id: UUID(), amount: -amount, reason: reason, date: Date())
            pointsRecords.append(record)
            saveData()
            return true
        }
        return false
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        // 保存到UserDefaults，在实际项目中应考虑使用CoreData或文件系统
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(memoryItems) {
            UserDefaults.standard.set(encoded, forKey: "memoryItems")
        }
        
        UserDefaults.standard.set(points, forKey: "points")
        
        if let encoded = try? encoder.encode(pointsRecords) {
            UserDefaults.standard.set(encoded, forKey: "pointsRecords")
        }
    }
    
    private func loadData() {
        // 从UserDefaults加载，在实际项目中应考虑使用CoreData或文件系统
        let decoder = JSONDecoder()
        
        if let data = UserDefaults.standard.data(forKey: "memoryItems"),
           let decoded = try? decoder.decode([MemoryItem].self, from: data) {
            memoryItems = decoded
        }
        
        points = UserDefaults.standard.integer(forKey: "points")
        if points == 0 {
            points = 100 // 默认值
        }
        
        if let data = UserDefaults.standard.data(forKey: "pointsRecords"),
           let decoded = try? decoder.decode([PointsRecord].self, from: data) {
            pointsRecords = decoded
        }
    }
    
    // 添加示例数据以便测试
    private func addSampleData() {
        let item1 = MemoryItem(
            id: UUID(),
            title: "静夜思",
            content: "床前明月光，疑是地上霜。举头望明月，低头思故乡。",
            progress: 0.4,
            reviewStage: 2,
            lastReviewDate: Date(),
            nextReviewDate: Calendar.current.date(byAdding: .day, value: 0, to: Date())!
        )
        
        let item2 = MemoryItem(
            id: UUID(),
            title: "登鹳雀楼",
            content: "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。",
            progress: 0.6,
            reviewStage: 3,
            lastReviewDate: Date(),
            nextReviewDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        )
        
        let item3 = MemoryItem(
            id: UUID(),
            title: "望庐山瀑布",
            content: "日照香炉生紫烟，遥看瀑布挂前川。飞流直下三千尺，疑是银河落九天。",
            progress: 0.0,
            reviewStage: 0,
            lastReviewDate: nil,
            nextReviewDate: nil
        )
        
        let item4 = MemoryItem(
            id: UUID(),
            title: "春晓",
            content: "春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。",
            progress: 1.0,
            reviewStage: 5,
            lastReviewDate: Date(),
            nextReviewDate: nil
        )
        
        memoryItems = [item1, item2, item3, item4]
        
        // 添加一些积分记录
        let record1 = PointsRecord(
            id: UUID(),
            amount: 100,
            reason: "新用户奖励",
            date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )
        
        let record2 = PointsRecord(
            id: UUID(),
            amount: -10,
            reason: "OCR识别",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        )
        
        pointsRecords = [record1, record2]
        
        saveData()
    }
} 