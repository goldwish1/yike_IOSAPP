import XCTest
@testable import Yike

final class MockFileManagerTests: YikeBaseTests {
    
    // MARK: - 属性
    
    private var mockFileManager: MockFileManager!
    
    // MARK: - 生命周期
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
    }
    
    override func tearDown() {
        mockFileManager = nil
        super.tearDown()
    }
    
    // MARK: - 测试方法
    
    // MARK: 基本功能测试
    
    func test_Init_CreatesEmptyFileSystem() {
        // 验证初始状态
        XCTAssertEqual(mockFileManager.operations.count, 0)
        XCTAssertFalse(mockFileManager.fileExists(atPath: "/test"))
    }
    
    func test_Reset_ClearsAllData() {
        // 准备
        mockFileManager.addDirectory(at: "/test")
        mockFileManager.addFile(at: "/test/file.txt", data: Data("test".utf8))
        _ = mockFileManager.fileExists(atPath: "/test")
        
        // 执行
        mockFileManager.reset()
        
        // 验证
        XCTAssertEqual(mockFileManager.operations.count, 0)
        XCTAssertFalse(mockFileManager.fileExists(atPath: "/test"))
        XCTAssertEqual(mockFileManager.operations.count, 1) // 这里会增加一次操作
    }
    
    // MARK: 文件操作测试
    
    func test_FileExists_ReturnsTrueForExistingFile() {
        // 准备
        mockFileManager.addFile(at: "/test.txt", data: Data("test".utf8))
        
        // 执行
        let exists = mockFileManager.fileExists(atPath: "/test.txt")
        
        // 验证
        XCTAssertTrue(exists)
        XCTAssertEqual(mockFileManager.operations.count, 1)
        XCTAssertTrue(mockFileManager.hasOperation(.checkExists(path: "/test.txt")))
    }
    
    func test_FileExists_ReturnsFalseForNonExistingFile() {
        // 执行
        let exists = mockFileManager.fileExists(atPath: "/nonexistent.txt")
        
        // 验证
        XCTAssertFalse(exists)
        XCTAssertEqual(mockFileManager.operations.count, 1)
        XCTAssertTrue(mockFileManager.hasOperation(.checkExists(path: "/nonexistent.txt")))
    }
    
    func test_FileExists_WithIsDirectory_SetsCorrectFlag() {
        // 准备
        mockFileManager.addDirectory(at: "/testdir")
        mockFileManager.addFile(at: "/testfile", data: Data("test".utf8))
        
        // 执行 - 目录
        var isDirectory = ObjCBool(false)
        let dirExists = mockFileManager.fileExists(atPath: "/testdir", isDirectory: &isDirectory)
        
        // 验证 - 目录
        XCTAssertTrue(dirExists)
        XCTAssertTrue(isDirectory.boolValue)
        
        // 执行 - 文件
        isDirectory = ObjCBool(false)
        let fileExists = mockFileManager.fileExists(atPath: "/testfile", isDirectory: &isDirectory)
        
        // 验证 - 文件
        XCTAssertTrue(fileExists)
        XCTAssertFalse(isDirectory.boolValue)
    }
    
    func test_CreateDirectory_CreatesDirectory() throws {
        // 执行
        try mockFileManager.createDirectory(atPath: "/testdir", withIntermediateDirectories: false)
        
        // 验证
        XCTAssertTrue(mockFileManager.fileExists(atPath: "/testdir"))
        XCTAssertEqual(mockFileManager.operations.count, 2) // 创建 + 检查
        XCTAssertTrue(mockFileManager.hasOperation(.createDirectory(path: "/testdir", createIntermediates: false)))
    }
    
    func test_CreateDirectory_WithIntermediates_CreatesAllDirectories() throws {
        // 执行
        try mockFileManager.createDirectory(atPath: "/a/b/c", withIntermediateDirectories: true)
        
        // 验证 - 重置操作计数，以便于后续断言
        let operationsCount = mockFileManager.operations.count
        
        // 验证目录存在
        let aExists = mockFileManager.fileExists(atPath: "/a")
        let abExists = mockFileManager.fileExists(atPath: "/a/b")
        let abcExists = mockFileManager.fileExists(atPath: "/a/b/c")
        
        XCTAssertTrue(aExists, "Directory /a should exist")
        XCTAssertTrue(abExists, "Directory /a/b should exist")
        XCTAssertTrue(abcExists, "Directory /a/b/c should exist")
        
        // 验证操作记录
        XCTAssertEqual(mockFileManager.operations.count, operationsCount + 3) // 3次fileExists调用
    }
    
    func test_CreateDirectory_WithError_ThrowsError() {
        // 准备
        let expectedError = NSError(domain: "test", code: 123)
        mockFileManager.setError(expectedError)
        
        // 执行 & 验证
        XCTAssertThrowsError(try mockFileManager.createDirectory(atPath: "/testdir", withIntermediateDirectories: false)) { error in
            XCTAssertEqual((error as NSError).domain, expectedError.domain)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }
    
    func test_CopyItem_CopiesItem() throws {
        // 准备
        let testData = Data("test".utf8)
        mockFileManager.addFile(at: "/source.txt", data: testData)
        
        // 执行
        try mockFileManager.copyItem(atPath: "/source.txt", toPath: "/dest.txt")
        
        // 验证
        XCTAssertTrue(mockFileManager.fileExists(atPath: "/source.txt"))
        XCTAssertTrue(mockFileManager.fileExists(atPath: "/dest.txt"))
        XCTAssertEqual(mockFileManager.contents(atPath: "/dest.txt"), testData)
        XCTAssertTrue(mockFileManager.hasOperation(.copyItem(srcPath: "/source.txt", dstPath: "/dest.txt")))
    }
    
    func test_CopyItem_WithNonExistingSource_ThrowsError() {
        // 执行 & 验证
        XCTAssertThrowsError(try mockFileManager.copyItem(atPath: "/nonexistent.txt", toPath: "/dest.txt"))
    }
    
    func test_MoveItem_MovesItem() throws {
        // 准备
        let testData = Data("test".utf8)
        mockFileManager.addFile(at: "/source.txt", data: testData)
        
        // 执行
        try mockFileManager.moveItem(atPath: "/source.txt", toPath: "/dest.txt")
        
        // 验证
        XCTAssertFalse(mockFileManager.fileExists(atPath: "/source.txt"))
        XCTAssertTrue(mockFileManager.fileExists(atPath: "/dest.txt"))
        XCTAssertEqual(mockFileManager.contents(atPath: "/dest.txt"), testData)
        XCTAssertTrue(mockFileManager.hasOperation(.moveItem(srcPath: "/source.txt", dstPath: "/dest.txt")))
    }
    
    func test_RemoveItem_RemovesItem() throws {
        // 准备
        mockFileManager.addFile(at: "/test.txt", data: Data("test".utf8))
        
        // 执行
        try mockFileManager.removeItem(atPath: "/test.txt")
        
        // 验证
        XCTAssertFalse(mockFileManager.fileExists(atPath: "/test.txt"))
        XCTAssertTrue(mockFileManager.hasOperation(.removeItem(path: "/test.txt")))
    }
    
    func test_RemoveItem_WithNonExistingFile_ThrowsError() {
        // 执行 & 验证
        XCTAssertThrowsError(try mockFileManager.removeItem(atPath: "/nonexistent.txt"))
    }
    
    func test_Contents_ReturnsCorrectData() {
        // 准备
        let testData = Data("test".utf8)
        mockFileManager.addFile(at: "/test.txt", data: testData)
        
        // 执行
        let contents = mockFileManager.contents(atPath: "/test.txt")
        
        // 验证
        XCTAssertEqual(contents, testData)
        XCTAssertTrue(mockFileManager.hasOperation(.contentsOfFile(path: "/test.txt")))
    }
    
    func test_CreateFile_CreatesFile() {
        // 准备
        let testData = Data("test".utf8)
        
        // 执行
        let result = mockFileManager.createFile(atPath: "/test.txt", contents: testData)
        
        // 验证
        XCTAssertTrue(result)
        XCTAssertTrue(mockFileManager.fileExists(atPath: "/test.txt"))
        XCTAssertEqual(mockFileManager.contents(atPath: "/test.txt"), testData)
        XCTAssertTrue(mockFileManager.hasOperation(.createFile(path: "/test.txt")))
    }
    
    func test_ContentsOfDirectory_ReturnsCorrectContents() throws {
        // 准备
        mockFileManager.addDirectory(at: "/testdir")
        mockFileManager.addFile(at: "/testdir/file1.txt", data: Data("test1".utf8))
        mockFileManager.addFile(at: "/testdir/file2.txt", data: Data("test2".utf8))
        
        // 执行
        let contents = try mockFileManager.contentsOfDirectory(atPath: "/testdir")
        
        // 验证
        XCTAssertEqual(contents.count, 2, "Directory should contain 2 files")
        XCTAssertTrue(contents.contains("file1.txt"), "Directory should contain file1.txt")
        XCTAssertTrue(contents.contains("file2.txt"), "Directory should contain file2.txt")
        XCTAssertTrue(mockFileManager.hasOperation(.contentsOfDirectory(path: "/testdir")))
    }
    
    func test_AttributesOfItem_ReturnsAttributes() throws {
        // 准备
        mockFileManager.addFile(at: "/test.txt", data: Data("test".utf8))
        
        // 执行
        let attributes = try mockFileManager.attributesOfItem(atPath: "/test.txt")
        
        // 验证
        XCTAssertNotNil(attributes[.size])
        XCTAssertNotNil(attributes[.creationDate])
        XCTAssertNotNil(attributes[.modificationDate])
        XCTAssertEqual(attributes[.type] as? FileAttributeType, FileAttributeType.typeRegular)
        XCTAssertTrue(mockFileManager.hasOperation(.attributesOfItem(path: "/test.txt")))
    }
    
    // MARK: URL 版本测试
    
    func test_URLVersions_CallPathVersions() throws {
        // 准备
        let sourceURL = URL(fileURLWithPath: "/source.txt")
        let destURL = URL(fileURLWithPath: "/dest.txt")
        mockFileManager.addFile(at: "/source.txt", data: Data("test".utf8))
        
        // 执行
        try mockFileManager.createDirectory(at: URL(fileURLWithPath: "/testdir"), withIntermediateDirectories: false)
        try mockFileManager.copyItem(at: sourceURL, to: destURL)
        try mockFileManager.moveItem(at: destURL, to: URL(fileURLWithPath: "/moved.txt"))
        try mockFileManager.removeItem(at: URL(fileURLWithPath: "/moved.txt"))
        
        // 验证
        XCTAssertTrue(mockFileManager.hasOperation(.createDirectory(path: "/testdir", createIntermediates: false)))
        XCTAssertTrue(mockFileManager.hasOperation(.copyItem(srcPath: "/source.txt", dstPath: "/dest.txt")))
        XCTAssertTrue(mockFileManager.hasOperation(.moveItem(srcPath: "/dest.txt", dstPath: "/moved.txt")))
        XCTAssertTrue(mockFileManager.hasOperation(.removeItem(path: "/moved.txt")))
    }
    
    // MARK: 验证方法测试
    
    func test_HasOperation_ReturnsTrueForExistingOperation() {
        // 准备
        mockFileManager.addFile(at: "/test.txt", data: Data("test".utf8))
        _ = mockFileManager.fileExists(atPath: "/test.txt")
        
        // 执行 & 验证
        XCTAssertTrue(mockFileManager.hasOperation(.checkExists(path: "/test.txt")))
        XCTAssertFalse(mockFileManager.hasOperation(.checkExists(path: "/other.txt")))
    }
    
    func test_OperationCount_ReturnsCorrectCount() {
        // 准备
        mockFileManager.addFile(at: "/test.txt", data: Data("test".utf8))
        _ = mockFileManager.fileExists(atPath: "/test.txt")
        _ = mockFileManager.fileExists(atPath: "/test.txt")
        _ = mockFileManager.fileExists(atPath: "/other.txt")
        
        // 执行 & 验证
        XCTAssertEqual(mockFileManager.operationCount(ofType: .checkExists), 3)
        XCTAssertEqual(mockFileManager.operationCount(forPath: "/test.txt"), 2)
        XCTAssertEqual(mockFileManager.operationCount(forPath: "/other.txt"), 1)
    }
}
