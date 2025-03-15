import Foundation
import Vision
import ObjectiveC
@testable import Yike

/// 模拟 Vision 框架，用于测试 OCR 功能
class MockVisionFramework {
    
    // MARK: - 属性
    
    /// 记录的操作
    private(set) var operations: [Operation] = []
    
    /// 预设的识别结果
    private var recognitionResults: [String: [VNRecognizedTextObservation]] = [:]
    
    /// 默认识别结果
    private var defaultRecognitionResult: [VNRecognizedTextObservation] = []
    
    /// 模拟错误
    static var errorToThrow: Error?
    
    /// 模拟延迟（秒）
    var recognitionDelay: TimeInterval = 0.1
    
    // MARK: - 初始化
    
    /// 初始化
    init() {}
    
    // MARK: - 配置方法
    
    /// 设置特定图像的识别结果
    /// - Parameters:
    ///   - imageIdentifier: 图像标识符
    ///   - observations: 识别结果
    func setRecognitionResult(for imageIdentifier: String, observations: [VNRecognizedTextObservation]) {
        recognitionResults[imageIdentifier] = observations
    }
    
    /// 设置默认识别结果
    /// - Parameter observations: 识别结果
    func setDefaultRecognitionResult(_ observations: [VNRecognizedTextObservation]) {
        defaultRecognitionResult = observations
    }
    
    /// 创建模拟的文本识别请求
    /// - Parameters:
    ///   - imageIdentifier: 图像标识符（用于查找预设结果）
    ///   - completionHandler: 完成回调
    /// - Returns: 文本识别请求
    func createTextRecognitionRequest(for imageIdentifier: String, completionHandler: @escaping (VNRequest, Error?) -> Void) -> VNRecognizeTextRequest {
        operations.append(.createTextRecognitionRequest(imageIdentifier: imageIdentifier))
        
        let request = MockVNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            // 如果设置了错误，则返回错误
            if let error = MockVisionFramework.errorToThrow {
                completionHandler(request, error)
                return
            }
            
            // 获取预设结果或默认结果
            let observations = self.recognitionResults[imageIdentifier] ?? self.defaultRecognitionResult
            
            // 设置请求的结果
            if let mockRequest = request as? MockVNRecognizeTextRequest {
                mockRequest.mockResults = observations
            }
            
            // 延迟调用完成回调，模拟异步处理
            DispatchQueue.main.asyncAfter(deadline: .now() + self.recognitionDelay) {
                completionHandler(request, nil)
            }
        }
        
        return request
    }
    
    /// 执行请求
    /// - Parameters:
    ///   - requests: 请求数组
    ///   - imageData: 图像数据
    ///   - orientation: 图像方向
    ///   - options: 选项
    /// - Throws: 错误
    func perform(_ requests: [VNRequest], on imageData: Data, orientation: CGImagePropertyOrientation, options: [VNImageOption: Any] = [:]) throws {
        operations.append(.performRequests(imageData: imageData, orientation: orientation))
        
        // 如果设置了错误
        if let error = MockVisionFramework.errorToThrow {
            // 执行每个请求的完成回调，传递错误
            for request in requests {
                if let mockRequest = request as? MockVNRecognizeTextRequest {
                    mockRequest.mockCompletionHandler?(request, error)
                }
            }
            
            // 抛出错误
            throw error
        }
        
        // 执行每个请求的完成回调
        for request in requests {
            if let mockRequest = request as? MockVNRecognizeTextRequest {
                mockRequest.mockCompletionHandler?(request, nil)
            }
        }
    }
    
    // MARK: - 重置
    
    /// 重置所有状态和操作记录
    func reset() {
        operations.removeAll()
        recognitionResults.removeAll()
        defaultRecognitionResult.removeAll()
        MockVisionFramework.errorToThrow = nil
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
        case createTextRecognitionRequest
        case performRequests
    }
    
    /// 操作
    struct Operation {
        let type: OperationType
        let parameters: [String: Any]
        
        // 创建文本识别请求操作
        static func createTextRecognitionRequest(imageIdentifier: String) -> Operation {
            return Operation(type: .createTextRecognitionRequest, parameters: ["imageIdentifier": imageIdentifier])
        }
        
        // 执行请求操作
        static func performRequests(imageData: Data, orientation: CGImagePropertyOrientation) -> Operation {
            return Operation(type: .performRequests, parameters: ["imageData": imageData, "orientation": orientation])
        }
        
        // 通用初始化
        private init(type: OperationType, parameters: [String: Any] = [:]) {
            self.type = type
            self.parameters = parameters
        }
    }
}

// MARK: - 模拟 VNRecognizeTextRequest

/// 模拟 VNRecognizeTextRequest
class MockVNRecognizeTextRequest: VNRecognizeTextRequest {
    
    /// 模拟结果
    var mockResults: [VNRecognizedTextObservation] = []
    
    /// 模拟完成回调
    var mockCompletionHandler: ((VNRequest, Error?) -> Void)?
    
    /// 初始化
    /// - Parameter completionHandler: 完成回调
    override init(completionHandler: ((VNRequest, Error?) -> Void)? = nil) {
        self.mockCompletionHandler = completionHandler
        super.init(completionHandler: completionHandler)
    }
    
    /// 必需的初始化器
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取结果
    override var results: [VNRecognizedTextObservation]? {
        return mockResults
    }
}

// MARK: - 模拟 VNRecognizedTextObservation

/// 模拟 VNRecognizedTextObservation
class MockVNRecognizedTextObservation: VNRecognizedTextObservation {
    
    /// 模拟的识别文本
    private var mockRecognizedTexts: [MockVNRecognizedText] = []
    
    /// 模拟的边界框
    private var mockBoundingBox: CGRect = .zero
    
    /// 初始化
    /// - Parameters:
    ///   - text: 文本
    ///   - confidence: 置信度
    ///   - boundingBox: 边界框
    init(text: String, confidence: Float = 0.9, boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) {
        super.init()
        self.mockRecognizedTexts = [MockVNRecognizedText(text: text, confidence: confidence)]
        self.mockBoundingBox = boundingBox
    }
    
    /// 必需的初始化器
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取边界框
    override var boundingBox: CGRect {
        return mockBoundingBox
    }
    
    /// 获取候选文本
    /// - Parameter maxCandidates: 最大候选数量
    /// - Returns: 候选文本数组
    override func topCandidates(_ maxCandidates: Int) -> [VNRecognizedText] {
        return Array(mockRecognizedTexts.prefix(maxCandidates))
    }
}

// MARK: - 辅助方法

extension MockVisionFramework {
    
    /// 创建模拟的文本观察结果
    /// - Parameters:
    ///   - text: 识别的文本
    ///   - confidence: 置信度
    ///   - boundingBox: 边界框
    /// - Returns: 文本观察结果
    static func createTextObservation(text: String, confidence: Float = 0.9, boundingBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> VNRecognizedTextObservation {
        return MockVNRecognizedTextObservation(text: text, confidence: confidence, boundingBox: boundingBox)
    }
    
    /// 使用运行时设置对象的属性值
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    ///   - object: 对象
    private static func setValue(_ value: Any, forKey key: String, in object: AnyObject) {
        // 使用 KVC 设置属性
        object.setValue(value, forKey: key)
    }
}

// MARK: - 模拟 VNRecognizedText

/// 模拟 VNRecognizedText
class MockVNRecognizedText: VNRecognizedText {
    
    /// 模拟文本
    private let mockText: String
    
    /// 模拟置信度
    private let mockConfidence: Float
    
    /// 初始化
    /// - Parameters:
    ///   - text: 文本
    ///   - confidence: 置信度
    init(text: String, confidence: Float) {
        self.mockText = text
        self.mockConfidence = confidence
        super.init()
    }
    
    /// 必需的初始化器
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取文本
    override var string: String {
        return mockText
    }
    
    /// 获取置信度
    override var confidence: Float {
        return mockConfidence
    }
}
