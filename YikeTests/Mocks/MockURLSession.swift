import Foundation
@testable import Yike

/// 模拟 URLSession，用于测试网络请求
class MockURLSession {
    
    /// 记录的请求
    private(set) var requests: [URLRequest] = []
    
    /// 预设的响应
    private var responses: [URL: (data: Data?, response: HTTPURLResponse?, error: Error?)] = [:]
    
    /// 默认响应
    private var defaultResponse: (data: Data?, response: HTTPURLResponse?, error: Error?) = (nil, nil, nil)
    
    /// 延迟时间（秒）
    var responseDelay: TimeInterval = 0
    
    /// 初始化
    init() {}
    
    /// 清除所有数据和请求记录
    func reset() {
        requests.removeAll()
        responses.removeAll()
        defaultResponse = (nil, nil, nil)
        responseDelay = 0
    }
    
    // MARK: - 配置响应
    
    /// 设置特定URL的响应
    /// - Parameters:
    ///   - url: 请求URL
    ///   - data: 响应数据
    ///   - statusCode: HTTP状态码
    ///   - error: 错误
    func setResponse(for url: URL, data: Data? = nil, statusCode: Int = 200, error: Error? = nil) {
        let response = error == nil ? HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ) : nil
        responses[url] = (data, response, error)
    }
    
    /// 设置特定URL的JSON响应
    /// - Parameters:
    ///   - url: 请求URL
    ///   - json: JSON对象
    ///   - statusCode: HTTP状态码
    ///   - error: 错误
    func setJSONResponse(for url: URL, json: Any, statusCode: Int = 200, error: Error? = nil) throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        setResponse(for: url, data: data, statusCode: statusCode, error: error)
    }
    
    /// 设置默认响应
    /// - Parameters:
    ///   - data: 响应数据
    ///   - statusCode: HTTP状态码
    ///   - error: 错误
    func setDefaultResponse(data: Data? = nil, statusCode: Int = 200, error: Error? = nil) {
        let response = HTTPURLResponse(
            url: URL(string: "https://default.example.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        defaultResponse = (data, response, error)
    }
    
    /// 设置默认JSON响应
    /// - Parameters:
    ///   - json: JSON对象
    ///   - statusCode: HTTP状态码
    ///   - error: 错误
    func setDefaultJSONResponse(json: Any, statusCode: Int = 200, error: Error? = nil) throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        setDefaultResponse(data: data, statusCode: statusCode, error: error)
    }
    
    // MARK: - 数据任务
    
    /// 创建数据任务
    /// - Parameters:
    ///   - request: 请求
    ///   - completionHandler: 完成回调
    /// - Returns: 数据任务
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requests.append(request)
        
        let response = responses[request.url!] ?? defaultResponse
        
        return MockURLSessionDataTask { [weak self] in
            guard let self = self else { return }
            
            if self.responseDelay > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + self.responseDelay) {
                    completionHandler(response.data, response.response, response.error)
                }
            } else {
                completionHandler(response.data, response.response, response.error)
            }
        }
    }
    
    /// 创建数据任务
    /// - Parameters:
    ///   - url: URL
    ///   - completionHandler: 完成回调
    /// - Returns: 数据任务
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let request = URLRequest(url: url)
        return dataTask(with: request, completionHandler: completionHandler)
    }
    
    // MARK: - 验证方法
    
    /// 验证是否有特定URL的请求
    /// - Parameter url: URL
    /// - Returns: 是否有请求
    func hasRequest(for url: URL) -> Bool {
        return requests.contains { $0.url == url }
    }
    
    /// 验证是否有特定URL路径的请求
    /// - Parameter path: URL路径
    /// - Returns: 是否有请求
    func hasRequest(withPath path: String) -> Bool {
        return requests.contains { $0.url?.path == path }
    }
    
    /// 获取特定URL的请求次数
    /// - Parameter url: URL
    /// - Returns: 请求次数
    func requestCount(for url: URL) -> Int {
        return requests.filter { $0.url == url }.count
    }
    
    /// 获取特定HTTP方法的请求次数
    /// - Parameter method: HTTP方法
    /// - Returns: 请求次数
    func requestCount(forMethod method: String) -> Int {
        return requests.filter { $0.httpMethod == method }.count
    }
    
    /// 获取最后一个请求
    /// - Returns: 最后一个请求
    func lastRequest() -> URLRequest? {
        return requests.last
    }
}

/// 模拟 URLSessionDataTask
class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void
    private(set) var resumeCallCount = 0
    private(set) var cancelCallCount = 0
    
    init(closure: @escaping () -> Void) {
        self.closure = closure
        super.init()
    }
    
    override func resume() {
        resumeCallCount += 1
        closure()
    }
    
    override func cancel() {
        cancelCallCount += 1
    }
}

/// URLSession 扩展，用于测试
extension URLSession {
    /// 创建模拟会话
    static func makeMockSession() -> MockURLSession {
        return MockURLSession()
    }
}
