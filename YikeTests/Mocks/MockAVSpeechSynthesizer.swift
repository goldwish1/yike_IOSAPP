import Foundation
import AVFoundation
@testable import Yike

/// 模拟 AVSpeechSynthesizer，用于测试语音合成功能
class MockAVSpeechSynthesizer {
    
    // MARK: - 属性
    
    /// 当前正在说话的状态
    private(set) var isSpeakingMock = false
    
    /// 当前正在暂停的状态
    private(set) var isPausedMock = false
    
    /// 当前的语音合成发声
    private(set) var currentUtterance: AVSpeechUtterance?
    
    /// 代理
    weak var delegate: AVSpeechSynthesizerDelegate?
    
    /// 记录的操作
    private(set) var operations: [Operation] = []
    
    /// 模拟错误
    static var errorToThrow: Error?
    
    /// 模拟延迟（秒）
    var synthesisDelay: TimeInterval = 0.1
    
    // MARK: - 初始化
    
    /// 初始化
    init() {}
    
    // MARK: - 操作方法
    
    /// 开始说话
    /// - Parameter utterance: 语音合成发声
    /// - Returns: 是否成功
    func speak(_ utterance: AVSpeechUtterance) {
        operations.append(.speak(utterance))
        
        if let error = MockAVSpeechSynthesizer.errorToThrow {
            delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didFinish: utterance)
            return
        }
        
        currentUtterance = utterance
        isSpeakingMock = true
        isPausedMock = false
        
        // 通知代理开始说话
        delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didStart: utterance)
        
        // 模拟说话过程
        DispatchQueue.main.asyncAfter(deadline: .now() + synthesisDelay) { [weak self] in
            guard let self = self, self.currentUtterance == utterance, self.isSpeakingMock else { return }
            
            // 通知代理说话完成
            self.isSpeakingMock = false
            self.currentUtterance = nil
            self.delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didFinish: utterance)
        }
    }
    
    /// 暂停说话
    /// - Parameter boundary: 暂停边界
    /// - Returns: 是否成功
    @discardableResult
    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        operations.append(.pauseSpeaking(boundary))
        
        if let _ = MockAVSpeechSynthesizer.errorToThrow {
            return false
        }
        
        if isSpeakingMock && !isPausedMock {
            isPausedMock = true
            isSpeakingMock = false
            
            // 通知代理暂停说话
            if let utterance = currentUtterance {
                delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didPause: utterance)
            }
            
            return true
        }
        
        return false
    }
    
    /// 继续说话
    /// - Parameter boundary: 继续边界
    /// - Returns: 是否成功
    @discardableResult
    func continueSpeaking() -> Bool {
        operations.append(.continueSpeaking)
        
        if let _ = MockAVSpeechSynthesizer.errorToThrow {
            return false
        }
        
        if isPausedMock && !isSpeakingMock {
            isPausedMock = false
            isSpeakingMock = true
            
            // 通知代理继续说话
            if let utterance = currentUtterance {
                delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didContinue: utterance)
            }
            
            return true
        }
        
        return false
    }
    
    /// 停止说话
    /// - Parameter boundary: 停止边界
    /// - Returns: 是否成功
    @discardableResult
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        operations.append(.stopSpeaking(boundary))
        
        if let _ = MockAVSpeechSynthesizer.errorToThrow {
            return false
        }
        
        if isSpeakingMock || isPausedMock {
            isSpeakingMock = false
            isPausedMock = false
            
            // 通知代理停止说话
            if let utterance = currentUtterance {
                delegate?.speechSynthesizer?(AVSpeechSynthesizer(), didCancel: utterance)
                currentUtterance = nil
            }
            
            return true
        }
        
        return false
    }
    
    // MARK: - 状态查询
    
    /// 是否正在说话
    var isSpeaking: Bool {
        operations.append(.getIsSpeaking)
        return isSpeakingMock
    }
    
    /// 是否已暂停
    var isPaused: Bool {
        operations.append(.getIsPaused)
        return isPausedMock
    }
    
    // MARK: - 重置
    
    /// 重置所有状态和操作记录
    func reset() {
        operations.removeAll()
        isSpeakingMock = false
        isPausedMock = false
        currentUtterance = nil
        MockAVSpeechSynthesizer.errorToThrow = nil
    }
    
    // MARK: - 验证方法
    
    /// 验证是否有特定操作
    /// - Parameter operationType: 操作类型
    /// - Returns: 是否有操作
    func hasOperation(ofType operationType: OperationType) -> Bool {
        return operations.contains { $0.type == operationType }
    }
    
    /// 获取特定类型的操作次数
    /// - Parameter type: 操作类型
    /// - Returns: 操作次数
    func operationCount(ofType type: OperationType) -> Int {
        return operations.filter { $0.type == type }.count
    }
    
    // MARK: - 操作类型和操作
    
    /// 操作类型
    enum OperationType {
        case speak
        case pauseSpeaking
        case continueSpeaking
        case stopSpeaking
        case getIsSpeaking
        case getIsPaused
    }
    
    /// 操作
    struct Operation {
        let type: OperationType
        let parameters: [String: Any]
        
        // 说话操作
        static func speak(_ utterance: AVSpeechUtterance) -> Operation {
            return Operation(type: .speak, parameters: ["utterance": utterance])
        }
        
        // 暂停操作
        static func pauseSpeaking(_ boundary: AVSpeechBoundary) -> Operation {
            return Operation(type: .pauseSpeaking, parameters: ["boundary": boundary])
        }
        
        // 继续操作
        static let continueSpeaking = Operation(type: .continueSpeaking)
        
        // 停止操作
        static func stopSpeaking(_ boundary: AVSpeechBoundary) -> Operation {
            return Operation(type: .stopSpeaking, parameters: ["boundary": boundary])
        }
        
        // 状态查询操作
        static let getIsSpeaking = Operation(type: .getIsSpeaking)
        static let getIsPaused = Operation(type: .getIsPaused)
        
        // 通用初始化
        private init(type: OperationType, parameters: [String: Any] = [:]) {
            self.type = type
            self.parameters = parameters
        }
    }
}

// MARK: - AVSpeechSynthesizer 协议兼容

extension MockAVSpeechSynthesizer: AVSpeechSynthesizerProtocol {}

// MARK: - AVSpeechSynthesizer 协议

/// AVSpeechSynthesizer 协议，用于依赖注入
protocol AVSpeechSynthesizerProtocol {
    var delegate: AVSpeechSynthesizerDelegate? { get set }
    var isSpeaking: Bool { get }
    var isPaused: Bool { get }
    
    func speak(_ utterance: AVSpeechUtterance)
    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool
    func continueSpeaking() -> Bool
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
}

// MARK: - AVSpeechSynthesizer 包装类

/// 包装 AVSpeechSynthesizer 的类，使其符合 AVSpeechSynthesizerProtocol
class RealAVSpeechSynthesizer: AVSpeechSynthesizerProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    
    var delegate: AVSpeechSynthesizerDelegate? {
        get { return synthesizer.delegate }
        set { synthesizer.delegate = newValue }
    }
    
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }
    
    var isPaused: Bool {
        return synthesizer.isPaused
    }
    
    func speak(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }
    
    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        return synthesizer.pauseSpeaking(at: boundary)
    }
    
    func continueSpeaking() -> Bool {
        return synthesizer.continueSpeaking()
    }
    
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        return synthesizer.stopSpeaking(at: boundary)
    }
}
