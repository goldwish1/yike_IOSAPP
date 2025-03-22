import Foundation
import Combine

@objc class DataManager: NSObject, ObservableObject {
    @objc static let shared = DataManager()
    
    @Published var memoryItems: [MemoryItem] = []
    @Published var points: Int = 100 // 新用户默认100积分
    @Published var pointsRecords: [PointsRecord] = []
    @Published var hasShownApiVoiceAlert: Bool = false // 是否已显示过在线语音提示
    
    // 用于测试的标志，指示是否使用持久化存储
    private var usePersistentStorage: Bool = true
    
    internal override init() {
        super.init()
        // 从本地加载数据
        loadData()
        
        // 添加一些测试数据
        if memoryItems.isEmpty {
            addSampleData()
        }
    }
    
    // 创建用于测试的实例
    static func createForTesting() -> DataManager {
        let manager = DataManager()
        manager.usePersistentStorage = false // 测试时不使用持久化存储
        manager.memoryItems = []
        manager.points = 100
        manager.pointsRecords = []
        manager.hasShownApiVoiceAlert = false
        return manager
    }
    
    // MARK: - Memory Items Methods
    
    func addMemoryItem(_ item: MemoryItem) {
        memoryItems.insert(item, at: 0) // 将新内容插入到数组开头
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
    
    // 获取所有记忆项目
    func getAllMemoryItems() -> [MemoryItem] {
        return memoryItems
    }
    
    // 根据ID获取记忆项目
    func getMemoryItem(id: UUID) -> MemoryItem? {
        return memoryItems.first(where: { $0.id == id })
    }
    
    // 创建新的记忆项目
    func createMemoryItem(title: String, content: String) -> MemoryItem {
        let item = MemoryItem(
            id: UUID(),
            title: title,
            content: content,
            progress: 0.0,
            reviewStage: 0,
            lastReviewDate: nil,
            nextReviewDate: nil,
            createdAt: Date(),
            lastReviewedAt: nil
        )
        addMemoryItem(item)
        return item
    }
    
    // 更新记忆项目的特定属性
    func updateMemoryItem(id: UUID, title: String? = nil, content: String? = nil, progress: Double? = nil, reviewStage: Int? = nil) -> Bool {
        guard let index = memoryItems.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
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
        saveData()
        return true
    }
    
    // 删除所有数据（用于测试）
    func deleteAllData() {
        memoryItems.removeAll()
        points = 100
        pointsRecords.removeAll()
        hasShownApiVoiceAlert = false
        saveData()
    }
    
    // MARK: - Points Management
    
    func addPoints(_ amount: Int, reason: String) {
        print("【积分日志】添加积分前: \(points)")
        points += amount
        let record = PointsRecord(id: UUID(), amount: amount, reason: reason, date: Date())
        pointsRecords.append(record)
        saveData()
        print("【积分日志】添加积分后: \(points)，添加金额: \(amount)，原因: \(reason)")
    }
    
    func deductPoints(_ amount: Int, reason: String) -> Bool {
        print("【积分日志】尝试扣除积分: \(amount)，当前积分: \(points)，原因: \(reason)")
        if points >= amount {
            points -= amount
            let record = PointsRecord(id: UUID(), amount: -amount, reason: reason, date: Date())
            pointsRecords.append(record)
            saveData()
            print("【积分日志】扣除积分成功，剩余积分: \(points)")
            return true
        }
        print("【积分日志】扣除积分失败，积分不足")
        return false
    }
    
    // 标记用户已经看过在线语音提示信息
    func markApiVoiceAlertAsShown() {
        hasShownApiVoiceAlert = true
        saveData()
    }
    
    // MARK: - Data Persistence
    
    func saveData() {
        // 如果是测试模式，不进行持久化存储
        if !usePersistentStorage {
            return
        }
        
        // 保存到UserDefaults，在实际项目中应考虑使用CoreData或文件系统
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(memoryItems) {
            UserDefaults.standard.set(encoded, forKey: "memoryItems")
        }
        
        UserDefaults.standard.set(points, forKey: "points")
        
        if let encoded = try? encoder.encode(pointsRecords) {
            UserDefaults.standard.set(encoded, forKey: "pointsRecords")
        }
        
        UserDefaults.standard.set(hasShownApiVoiceAlert, forKey: "hasShownApiVoiceAlert")
    }
    
    private func loadData() {
        // 如果是测试模式，不从持久化存储加载
        if !usePersistentStorage {
            return
        }
        
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
        
        hasShownApiVoiceAlert = UserDefaults.standard.bool(forKey: "hasShownApiVoiceAlert")
    }
    
    // 添加示例数据以便测试
    private func addSampleData() {
        let now = Date()
        
        let item1 = MemoryItem(
            id: UUID(),
            title: "静夜思",
            content: "床前明月光，疑是地上霜。举头望明月，低头思故乡。",
            progress: 0.4,
            reviewStage: 2,
            lastReviewDate: now,
            nextReviewDate: Calendar.current.date(byAdding: .day, value: 0, to: now)!,
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: now)!,
            lastReviewedAt: now
        )
        
        let item2 = MemoryItem(
            id: UUID(),
            title: "登鹳雀楼",
            content: "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。",
            progress: 0.6,
            reviewStage: 3,
            lastReviewDate: now,
            nextReviewDate: Calendar.current.date(byAdding: .day, value: 3, to: now)!,
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: now)!,
            lastReviewedAt: now
        )
        
        let item3 = MemoryItem(
            id: UUID(),
            title: "望庐山瀑布",
            content: "日照香炉生紫烟，遥看瀑布挂前川。飞流直下三千尺，疑是银河落九天。",
            progress: 0.0,
            reviewStage: 0,
            lastReviewDate: nil,
            nextReviewDate: nil,
            createdAt: now,
            lastReviewedAt: nil
        )
        
        let item4 = MemoryItem(
            id: UUID(),
            title: "春晓",
            content: "春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。",
            progress: 1.0,
            reviewStage: 5,
            lastReviewDate: now,
            nextReviewDate: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: now)!,
            lastReviewedAt: now
        )
        
        memoryItems = [item1, item2, item3, item4]
        
        // 添加一些积分记录
        let record1 = PointsRecord(
            id: UUID(),
            amount: 100,
            reason: "新用户奖励",
            date: Calendar.current.date(byAdding: .day, value: -30, to: now)!
        )
        
        // 只保留新用户奖励记录，不添加任何消费记录
        pointsRecords = [record1]
        
        saveData()
    }
} 