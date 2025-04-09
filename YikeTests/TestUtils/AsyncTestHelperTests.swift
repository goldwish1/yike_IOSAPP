import XCTest
@testable import Yike

final class AsyncTestHelperTests: XCTestCase {
    
    func test_wait_singleOperation() {
        let expectation = expectation(description: "Test wait")
        
        AsyncTestHelper.wait(description: "Test wait") { exp in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                exp.fulfill()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_waitAll_multipleOperations() {
        let expectation = expectation(description: "Test waitAll")
        
        AsyncTestHelper.waitAll(
            descriptions: ["Op1", "Op2"],
            operations: [
                { exp in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        exp.fulfill()
                    }
                },
                { exp in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        exp.fulfill()
                        expectation.fulfill()
                    }
                }
            ]
        )
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_waitUntil_condition() {
        let expectation = expectation(description: "Test waitUntil")
        var flag = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flag = true
            expectation.fulfill()
        }
        
        let result = AsyncTestHelper.waitUntil { flag }
        XCTAssertTrue(result)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_waitUntil_timeout() {
        let result = AsyncTestHelper.waitUntil(timeout: 0.1) { false }
        XCTAssertFalse(result)
    }
    
    func test_expectSuccess() {
        let expectation = expectation(description: "Test expectSuccess")
        
        let operation: (@escaping (Result<String, Error>) -> Void) -> Void = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(.success("test"))
                expectation.fulfill()
            }
        }
        
        AsyncTestHelper.expectSuccess(operation: operation)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_expectSuccess_withValidation() {
        let expectation = expectation(description: "Test expectSuccess with validation")
        
        let operation: (@escaping (Result<Int, Error>) -> Void) -> Void = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(.success(10))
                expectation.fulfill()
            }
        }
        
        AsyncTestHelper.expectSuccess(
            operation: operation,
            validation: { $0 > 5 }
        )
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_expectFailure() {
        let expectation = expectation(description: "Test expectFailure")
        let testError = NSError(domain: "test", code: -1)
        
        let operation: (@escaping (Result<String, Error>) -> Void) -> Void = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(.failure(testError))
                expectation.fulfill()
            }
        }
        
        AsyncTestHelper.expectFailure(
            operation: operation,
            errorType: NSError.self
        )
        
        wait(for: [expectation], timeout: 1.0)
    }
} 