import XCTest
@testable import Yike

final class TestDataGeneratorTests: XCTestCase {
    
    func test_generateTitle_validLength() {
        let title = TestDataGenerator.generateTitle(length: 10)
        XCTAssertEqual(title.count, 10)
    }
    
    func test_generateTitle_defaultLength() {
        let title = TestDataGenerator.generateTitle()
        XCTAssertEqual(title.count, 10)
    }
    
    func test_generateContent_validLength() {
        let content = TestDataGenerator.generateContent(length: 50)
        XCTAssertEqual(content.count, 50)
    }
    
    func test_generateContent_defaultLength() {
        let content = TestDataGenerator.generateContent()
        XCTAssertEqual(content.count, 50)
    }
    
    func test_generatePoints_inRange() {
        let points = TestDataGenerator.generatePoints(in: 100...200)
        XCTAssertTrue((100...200).contains(points))
    }
    
    func test_generatePoints_defaultRange() {
        let points = TestDataGenerator.generatePoints()
        XCTAssertTrue((0...1000).contains(points))
    }
    
    func test_generateTimestamp_validRange() {
        let date = TestDataGenerator.generateTimestamp(daysRange: -7...7)
        let now = Date()
        XCTAssertTrue(abs(date.timeIntervalSince(now)) <= 7 * 24 * 60 * 60)
    }
    
    func test_generateTimestamp_defaultRange() {
        let date = TestDataGenerator.generateTimestamp()
        let now = Date()
        XCTAssertTrue(abs(date.timeIntervalSince(now)) <= 7 * 24 * 60 * 60)
    }
    
    func test_generateAudioData_validSize() {
        let size = 1024
        let data = TestDataGenerator.generateAudioData(size: size)
        XCTAssertEqual(data.count, size)
    }
    
    func test_generateAudioData_defaultSize() {
        let data = TestDataGenerator.generateAudioData()
        XCTAssertEqual(data.count, 1024)
    }
} 