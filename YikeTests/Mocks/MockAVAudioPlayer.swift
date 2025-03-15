import Foundation
import AVFoundation
@testable import Yike

/// 模拟 AVAudioPlayer，用于测试音频播放功能
class MockAVAudioPlayer {
    
    // MARK: - 属性
    
    /// 音频数据
    private let audioData: Data?
    
    /// 音频URL
    private let audioURL: URL?
    
    /// 播放状态
    private(set) var isPlayingMock = false
    
    /// 当前播放时间
    private(set) var currentTimeMock: TimeInterval = 0
    
    /// 音频持续时间
    private(set) var durationMock: TimeInterval = 60.0 // 默认为60秒
    
    /// 音量
    private(set) var volumeMock: Float = 1.0
    
    /// 播放速率
    private(set) var rateMock: Float = 1.0
    
    /// 循环次数
    private(set) var numberOfLoopsMock: Int = 0
    
    /// 是否启用测量
    private(set) var isMeteringEnabledMock = false
    
    /// 播放完成回调
    var mockCompletionHandler: (() -> Void)?
    
    /// 记录的操作
    private(set) var operations: [Operation] = []
    
    /// 模拟错误
    static var errorToThrow: Error?
    
    // MARK: - 初始化
    
    /// 创建一个空的模拟播放器（仅用于测试）
    static func mockInit() -> MockAVAudioPlayer {
        do {
            return try MockAVAudioPlayer(data: Data(), fileTypeHint: nil)
        } catch {
            fatalError("Failed to initialize MockAVAudioPlayer: \(error)")
        }
    }
    
    /// 使用数据初始化
    /// - Parameters:
    ///   - data: 音频数据
    ///   - fileTypeHint: 文件类型提示
    /// - Throws: 错误
    init(data: Data, fileTypeHint: String?) throws {
        // 先检查是否需要抛出错误
        if let error = MockAVAudioPlayer.errorToThrow {
            throw error
        }
        
        self.audioData = data
        self.audioURL = nil
        operations.append(.init(data, fileTypeHint))
    }
    
    /// 使用URL初始化
    /// - Parameters:
    ///   - url: 音频URL
    ///   - fileTypeHint: 文件类型提示
    /// - Throws: 错误
    init(contentsOf url: URL, fileTypeHint: String?) throws {
        // 先检查是否需要抛出错误
        if let error = MockAVAudioPlayer.errorToThrow {
            throw error
        }
        
        self.audioData = nil
        self.audioURL = url
        operations.append(.init(url, fileTypeHint))
    }
    
    /// 清除所有数据和操作记录
    func reset() {
        operations.removeAll()
        isPlayingMock = false
        currentTimeMock = 0
        volumeMock = 1.0
        rateMock = 1.0
        numberOfLoopsMock = 0
        isMeteringEnabledMock = false
        MockAVAudioPlayer.errorToThrow = nil
    }
    
    // MARK: - 播放控制
    
    /// 准备播放
    /// - Returns: 是否成功
    func prepareToPlay() -> Bool {
        operations.append(.prepareToPlay)
        
        if let _ = MockAVAudioPlayer.errorToThrow {
            return false
        }
        
        return true
    }
    
    /// 播放
    /// - Returns: 是否成功
    func play() -> Bool {
        operations.append(.play)
        
        if let _ = MockAVAudioPlayer.errorToThrow {
            return false
        }
        
        isPlayingMock = true
        
        // 模拟播放完成
        if currentTimeMock >= durationMock {
            currentTimeMock = 0
        }
        
        // 如果设置了完成回调，在适当的时间调用它
        if let completionHandler = mockCompletionHandler {
            // 使用更短的延迟时间以加快测试速度
            let delay = (durationMock - currentTimeMock) / Double(rateMock)
            let testDelay = min(delay, 0.1) // 在测试中使用较短的延迟
            
            DispatchQueue.main.asyncAfter(deadline: .now() + testDelay) { [weak self] in
                guard let self = self else { return }
                
                if self.numberOfLoopsMock == 0 {
                    self.isPlayingMock = false
                    self.currentTimeMock = 0
                    completionHandler()
                } else if self.numberOfLoopsMock > 0 {
                    self.numberOfLoopsMock -= 1
                    self.currentTimeMock = 0
                    completionHandler() // 每次循环都调用回调
                    if self.numberOfLoopsMock >= 0 {
                        _ = self.play() // 重新播放
                    }
                }
                // 如果 numberOfLoopsMock < 0，则无限循环，不需要处理
            }
        }
        
        return true
    }
    
    /// 从特定时间开始播放
    /// - Parameter time: 开始时间
    /// - Returns: 是否成功
    func play(atTime time: TimeInterval) -> Bool {
        operations.append(.playAtTime(time))
        
        if let _ = MockAVAudioPlayer.errorToThrow {
            return false
        }
        
        currentTimeMock = time
        return play()
    }
    
    /// 暂停
    func pause() {
        operations.append(.pause)
        isPlayingMock = false
    }
    
    /// 停止
    func stop() {
        operations.append(.stop)
        isPlayingMock = false
        currentTimeMock = 0
    }
    
    // MARK: - 属性
    
    /// 是否正在播放
    var isPlaying: Bool {
        return isPlayingMock
    }
    
    /// 当前播放时间
    var currentTime: TimeInterval {
        get {
            operations.append(.getCurrentTime)
            return currentTimeMock
        }
        set {
            operations.append(.setCurrentTime(newValue))
            currentTimeMock = newValue
        }
    }
    
    /// 音频持续时间
    var duration: TimeInterval {
        operations.append(.getDuration)
        return durationMock
    }
    
    /// 设置音频持续时间（仅用于测试）
    func setDuration(_ duration: TimeInterval) {
        durationMock = duration
    }
    
    /// 音量
    var volume: Float {
        get {
            operations.append(.getVolume)
            return volumeMock
        }
        set {
            operations.append(.setVolume(newValue))
            volumeMock = newValue
        }
    }
    
    /// 播放速率
    var rate: Float {
        get {
            operations.append(.getRate)
            return rateMock
        }
        set {
            operations.append(.setRate(newValue))
            rateMock = newValue
        }
    }
    
    /// 循环次数
    var numberOfLoops: Int {
        get {
            operations.append(.getNumberOfLoops)
            return numberOfLoopsMock
        }
        set {
            operations.append(.setNumberOfLoops(newValue))
            numberOfLoopsMock = newValue
        }
    }
    
    /// 是否启用测量
    var isMeteringEnabled: Bool {
        get {
            operations.append(.getIsMeteringEnabled)
            return isMeteringEnabledMock
        }
        set {
            operations.append(.setIsMeteringEnabled(newValue))
            isMeteringEnabledMock = newValue
        }
    }
    
    // MARK: - 测量相关
    
    /// 更新测量
    func updateMeters() {
        operations.append(.updateMeters)
    }
    
    /// 获取平均功率
    /// - Parameter channelNumber: 通道号
    /// - Returns: 平均功率
    func averagePower(forChannel channelNumber: Int) -> Float {
        operations.append(.getAveragePower(channelNumber))
        return -50.0 + Float(channelNumber) * 10.0 // 模拟值
    }
    
    /// 获取峰值功率
    /// - Parameter channelNumber: 通道号
    /// - Returns: 峰值功率
    func peakPower(forChannel channelNumber: Int) -> Float {
        operations.append(.getPeakPower(channelNumber))
        return -30.0 + Float(channelNumber) * 10.0 // 模拟值
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
        case initWithData
        case initWithURL
        case prepareToPlay
        case play
        case playAtTime
        case pause
        case stop
        case getCurrentTime
        case setCurrentTime
        case getDuration
        case getVolume
        case setVolume
        case getRate
        case setRate
        case getNumberOfLoops
        case setNumberOfLoops
        case getIsMeteringEnabled
        case setIsMeteringEnabled
        case updateMeters
        case getAveragePower
        case getPeakPower
    }
    
    /// 操作
    struct Operation {
        let type: OperationType
        let parameters: [String: Any]
        
        // 初始化操作
        init(_ data: Data, _ fileTypeHint: String?) {
            self.type = .initWithData
            var params: [String: Any] = ["data": data]
            if let hint = fileTypeHint {
                params["fileTypeHint"] = hint
            }
            self.parameters = params
        }
        
        init(_ url: URL, _ fileTypeHint: String?) {
            self.type = .initWithURL
            var params: [String: Any] = ["url": url]
            if let hint = fileTypeHint {
                params["fileTypeHint"] = hint
            }
            self.parameters = params
        }
        
        // 播放控制操作
        static let prepareToPlay = Operation(type: .prepareToPlay)
        static let play = Operation(type: .play)
        static func playAtTime(_ time: TimeInterval) -> Operation {
            return Operation(type: .playAtTime, parameters: ["time": time])
        }
        static let pause = Operation(type: .pause)
        static let stop = Operation(type: .stop)
        
        // 属性操作
        static let getCurrentTime = Operation(type: .getCurrentTime)
        static func setCurrentTime(_ time: TimeInterval) -> Operation {
            return Operation(type: .setCurrentTime, parameters: ["time": time])
        }
        static let getDuration = Operation(type: .getDuration)
        static let getVolume = Operation(type: .getVolume)
        static func setVolume(_ volume: Float) -> Operation {
            return Operation(type: .setVolume, parameters: ["volume": volume])
        }
        static let getRate = Operation(type: .getRate)
        static func setRate(_ rate: Float) -> Operation {
            return Operation(type: .setRate, parameters: ["rate": rate])
        }
        static let getNumberOfLoops = Operation(type: .getNumberOfLoops)
        static func setNumberOfLoops(_ loops: Int) -> Operation {
            return Operation(type: .setNumberOfLoops, parameters: ["loops": loops])
        }
        static let getIsMeteringEnabled = Operation(type: .getIsMeteringEnabled)
        static func setIsMeteringEnabled(_ enabled: Bool) -> Operation {
            return Operation(type: .setIsMeteringEnabled, parameters: ["enabled": enabled])
        }
        
        // 测量操作
        static let updateMeters = Operation(type: .updateMeters)
        static func getAveragePower(_ channel: Int) -> Operation {
            return Operation(type: .getAveragePower, parameters: ["channel": channel])
        }
        static func getPeakPower(_ channel: Int) -> Operation {
            return Operation(type: .getPeakPower, parameters: ["channel": channel])
        }
        
        // 通用初始化
        private init(type: OperationType, parameters: [String: Any] = [:]) {
            self.type = type
            self.parameters = parameters
        }
    }
}
