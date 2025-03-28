import XCTest
@testable import Yike

final class MockServicesTests: XCTestCase {
    
    // MARK: - BaseMockService Tests
    
    func test_baseMockService_recordAndVerify() {
        let service = BaseMockService()
        
        service.recordCall("testMethod")
        XCTAssertTrue(service.verifyCall("testMethod"))
        XCTAssertFalse(service.verifyCall("nonexistentMethod"))
    }
    
    func test_baseMockService_multipleCallsAndReset() {
        let service = BaseMockService()
        
        service.recordCall("testMethod")
        service.recordCall("testMethod")
        XCTAssertTrue(service.verifyCall("testMethod", times: 2))
        
        service.resetCalls()
        XCTAssertFalse(service.verifyCall("testMethod"))
    }
    
    // MARK: - MockNetworkService Tests
    
    func test_mockNetworkService_request() {
        let service = MockNetworkService()
        let testData = "test".data(using: .utf8)!
        
        service.mockResponse(for: "test_endpoint", data: testData)
        let result = service.request("test_endpoint")
        
        XCTAssertEqual(try? result?.get(), testData)
        XCTAssertTrue(service.verifyCall("request_test_endpoint"))
    }
    
    func test_mockNetworkService_error() {
        let service = MockNetworkService()
        let testError = NSError(domain: "test", code: -1)
        
        service.mockError(for: "test_endpoint", error: testError)
        let result = service.request("test_endpoint")
        
        XCTAssertThrowsError(try result?.get())
        XCTAssertTrue(service.verifyCall("request_test_endpoint"))
    }
    
    // MARK: - MockStorageService Tests
    
    func test_mockStorageService_storeAndRetrieve() {
        let service = MockStorageService()
        let testValue = "test_value"
        
        service.store(testValue, for: "test_key")
        let retrieved = service.retrieve("test_key") as? String
        
        XCTAssertEqual(retrieved, testValue)
        XCTAssertTrue(service.verifyCall("store_test_key"))
        XCTAssertTrue(service.verifyCall("retrieve_test_key"))
    }
    
    func test_mockStorageService_remove() {
        let service = MockStorageService()
        let testValue = "test_value"
        
        service.store(testValue, for: "test_key")
        service.remove("test_key")
        
        XCTAssertNil(service.retrieve("test_key"))
        XCTAssertTrue(service.verifyCall("remove_test_key"))
    }
    
    func test_mockStorageService_clear() {
        let service = MockStorageService()
        
        service.store("value1", for: "key1")
        service.store("value2", for: "key2")
        service.clear()
        
        XCTAssertNil(service.retrieve("key1"))
        XCTAssertNil(service.retrieve("key2"))
        XCTAssertTrue(service.verifyCall("clear"))
    }
    
    // MARK: - MockAudioService Tests
    
    func test_mockAudioService_playAndPause() {
        let service = MockAudioService()
        let testData = Data([1, 2, 3])
        
        service.play(testData)
        XCTAssertTrue(service.isPlaying)
        XCTAssertEqual(service.currentAudio, testData)
        
        service.pause()
        XCTAssertFalse(service.isPlaying)
        XCTAssertEqual(service.currentAudio, testData)
    }
    
    func test_mockAudioService_stop() {
        let service = MockAudioService()
        let testData = Data([1, 2, 3])
        
        service.play(testData)
        service.stop()
        
        XCTAssertFalse(service.isPlaying)
        XCTAssertNil(service.currentAudio)
        XCTAssertTrue(service.verifyCall("stop"))
    }
} 