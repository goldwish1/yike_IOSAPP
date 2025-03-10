import Foundation

// 记忆项目模型
struct MemoryItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var progress: Double // 0.0 - 1.0
    var reviewStage: Int // 0: 未开始, 1-5: 艾宾浩斯复习阶段
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    
    var isNew: Bool {
        return reviewStage == 0
    }
    
    var isCompleted: Bool {
        return progress >= 1.0
    }
    
    var isInProgress: Bool {
        return !isNew && !isCompleted
    }
    
    var needsReviewToday: Bool {
        guard let nextReviewDate = nextReviewDate else { return false }
        return Calendar.current.isDateInToday(nextReviewDate)
    }
    
    var daysUntilNextReview: Int? {
        guard let nextReviewDate = nextReviewDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: nextReviewDate))
        return components.day
    }
}

// 积分记录模型
struct PointsRecord: Identifiable, Codable {
    var id: UUID
    var amount: Int // 正数为收入，负数为支出
    var reason: String
    var date: Date
    
    var isIncome: Bool {
        return amount > 0
    }
    
    var isExpense: Bool {
        return amount < 0
    }
    
    var absoluteAmount: Int {
        return abs(amount)
    }
}

// 用户设置模型
struct UserSettings: Codable, Equatable {
    // 播放设置
    var playbackVoiceType: VoiceType = .standard  // 新的音色类型，替代原来的性别和音色
    var playbackSpeed: Double = 1.0
    var playbackInterval: Int = 5 // 秒
    var enablePlaybackInterval: Bool = true
    
    // 提醒设置
    var enableDailyReminder: Bool = true
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20))!
    var reminderStyle: ReminderStyle = .notificationAndSound
    var reviewStrategy: ReviewStrategy = .standard
    
    enum VoiceType: String, Codable, CaseIterable, Equatable {
        case standard = "标准音色"
        case gentle = "轻柔音色"
        case deep = "浑厚音色"
    }
    
    enum ReminderStyle: String, Codable, CaseIterable, Equatable {
        case notificationOnly = "仅通知"
        case notificationAndSound = "通知+声音"
        case notificationAndVibration = "通知+震动"
    }
    
    enum ReviewStrategy: String, Codable, CaseIterable, Equatable {
        case simple = "简单"
        case standard = "标准"
        case intensive = "密集"
        
        var description: String {
            switch self {
            case .simple:
                return "简单: 第1天、第3天、第7天、第15天"
            case .standard:
                return "标准: 第1天、第2天、第4天、第7天、第15天"
            case .intensive:
                return "密集: 第1天、第2天、第3天、第5天、第8天、第13天"
            }
        }
        
        var intervals: [Int] {
            switch self {
            case .simple:
                return [1, 3, 7, 15]
            case .standard:
                return [1, 2, 4, 7, 15]
            case .intensive:
                return [1, 2, 3, 5, 8, 13]
            }
        }
    }
} 