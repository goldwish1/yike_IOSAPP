import XCTest
@testable import Yike

class MockURLSessionTests: XCTestCase {
    
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
    }
    
    override func tearDown() {
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - 基本功能测试
    
    func test_Init_CreatesEmptySession() {
        XCTAssertEqual(mockSession.requests.count, 0)
    }
    
    func test_Reset_ClearsAllData() {
        // 准备
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // 执行一些操作
        _ = mockSession.dataTask(with: request) { _, _, _ in }
        mockSession.setResponse(for: url, data: Data())
        mockSession.responseDelay = 1.0
        
        // 重置
        mockSession.reset()
        
        // 验证
        XCTAssertEqual(mockSession.requests.count, 0)
        XCTAssertEqual(mockSession.responseDelay, 0)
        
        // 验证响应被清除 - 通过尝试使用它
        let expectation = self.expectation(description: "Default response should be used")
        
        let task = mockSession.dataTask(with: url) { data, response, error in
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 响应配置测试
    
    func test_SetResponse_ConfiguresCorrectResponse() {
        // 准备
        let url = URL(string: "https://example.com")!
        let testData = Data("test data".utf8)
        
        // 设置响应
        mockSession.setResponse(for: url, data: testData, statusCode: 201)
        
        // 执行请求
        let expectation = self.expectation(description: "Response should be returned")
        
        let task = mockSession.dataTask(with: url) { data, response, error in
            // 验证
            XCTAssertEqual(data, testData)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 201)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    func test_SetJSONResponse_ConfiguresCorrectJSONResponse() throws {
        // 准备
        let url = URL(string: "https://example.com")!
        let json = ["key": "value"]
        
        // 设置JSON响应
        try mockSession.setJSONResponse(for: url, json: json)
        
        // 执行请求
        let expectation = self.expectation(description: "JSON response should be returned")
        
        let task = mockSession.dataTask(with: url) { data, response, error in
            // 验证
            XCTAssertNotNil(data)
            
            if let data = data {
                do {
                    let decodedJson = try JSONSerialization.jsonObject(with: data) as? [String: String]
                    XCTAssertEqual(decodedJson?["key"], "value")
                } catch {
                    XCTFail("Failed to decode JSON: \(error)")
                }
            }
            
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    func test_SetDefaultResponse_UsedWhenNoSpecificResponse() {
        // 准备
        let url = URL(string: "https://example.com")!
        let testData = Data("default data".utf8)
        
        // 设置默认响应
        mockSession.setDefaultResponse(data: testData, statusCode: 404)
        
        // 执行请求
        let expectation = self.expectation(description: "Default response should be used")
        
        let task = mockSession.dataTask(with: url) { data, response, error in
            // 验证
            XCTAssertEqual(data, testData)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    func test_SetError_ReturnsError() {
        // 准备
        let url = URL(string: "https://example.com")!
        let testError = NSError(domain: "test", code: 123, userInfo: nil)
        
        // 设置错误响应
        mockSession.setResponse(for: url, error: testError)
        
        // 执行请求
        let expectation = self.expectation(description: "Error should be returned")
        
        let task = mockSession.dataTask(with: url) { data, response, error in
            // 验证
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertEqual((error as NSError?)?.domain, "test")
            XCTAssertEqual((error as NSError?)?.code, 123)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 请求跟踪测试
    
    func test_DataTask_RecordsRequest() {
        // 准备
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // 执行
        _ = mockSession.dataTask(with: request) { _, _, _ in }
        
        // 验证
        XCTAssertEqual(mockSession.requests.count, 1)
        XCTAssertEqual(mockSession.requests.first?.url, url)
    }
    
    func test_HasRequest_ReturnsCorrectResult() {
        // 准备
        let url1 = URL(string: "https://example.com/path1")!
        let url2 = URL(string: "https://example.com/path2")!
        
        // 执行
        _ = mockSession.dataTask(with: url1) { _, _, _ in }.resume()
        
        // 验证
        XCTAssertTrue(mockSession.hasRequest(for: url1))
        XCTAssertFalse(mockSession.hasRequest(for: url2))
        XCTAssertTrue(mockSession.hasRequest(withPath: "/path1"))
        XCTAssertFalse(mockSession.hasRequest(withPath: "/path2"))
    }
    
    func test_RequestCount_ReturnsCorrectCount() {
        // 准备
        let url1 = URL(string: "https://example.com/path1")!
        let url2 = URL(string: "https://example.com/path2")!
        
        var request = URLRequest(url: url1)
        request.httpMethod = "POST"
        
        // 执行
        _ = mockSession.dataTask(with: url1) { _, _, _ in }.resume()
        _ = mockSession.dataTask(with: request) { _, _, _ in }.resume()
        _ = mockSession.dataTask(with: url2) { _, _, _ in }.resume()
        
        // 验证
        XCTAssertEqual(mockSession.requestCount(for: url1), 2)
        XCTAssertEqual(mockSession.requestCount(for: url2), 1)
        XCTAssertEqual(mockSession.requestCount(forMethod: "POST"), 1)
        XCTAssertEqual(mockSession.requestCount(forMethod: "GET"), 2) // 默认是GET
    }
    
    func test_LastRequest_ReturnsCorrectRequest() {
        // 准备
        let url1 = URL(string: "https://example.com/path1")!
        let url2 = URL(string: "https://example.com/path2")!
        
        // 执行
        _ = mockSession.dataTask(with: url1) { _, _, _ in }.resume()
        _ = mockSession.dataTask(with: url2) { _, _, _ in }.resume()
        
        // 验证
        XCTAssertEqual(mockSession.lastRequest()?.url, url2)
    }
    
    // MARK: - 延迟响应测试
    
    func test_ResponseDelay_DelaysResponse() {
        // 准备
        let url = URL(string: "https://example.com")!
        mockSession.responseDelay = 0.5
        
        // 执行
        let expectation = self.expectation(description: "Response should be delayed")
        let startTime = Date()
        
        let task = mockSession.dataTask(with: url) { _, _, _ in
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsedTime, 0.5)
            expectation.fulfill()
        }
        
        task.resume()
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - 数据任务测试
    
    func test_DataTask_CanBeCancelled() {
        // 准备
        let url = URL(string: "https://example.com")!
        
        // 执行
        let task = mockSession.dataTask(with: url) { _, _, _ in } as! MockURLSessionDataTask
        task.cancel()
        
        // 验证
        XCTAssertEqual(task.cancelCallCount, 1)
    }
    
    func test_DataTask_TracksResumeCalls() {
        // 准备
        let url = URL(string: "https://example.com")!
        
        // 执行
        let task = mockSession.dataTask(with: url) { _, _, _ in } as! MockURLSessionDataTask
        task.resume()
        task.resume() // 再次调用
        
        // 验证
        XCTAssertEqual(task.resumeCallCount, 2)
    }
}
