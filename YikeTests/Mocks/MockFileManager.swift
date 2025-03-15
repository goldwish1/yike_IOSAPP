import Foundation
@testable import Yike

/// 模拟FileManager，用于测试
class MockFileManager {
    
    /// 文件系统结构
    private var fileSystem: [String: Any] = [:]
    
    /// 记录的操作
    private(set) var operations: [Operation] = []
    
    /// 模拟错误
    var errorToThrow: Error?
    
    /// 临时目录URL
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
    
    /// 文档目录URL
    let documentDirectoryURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    
    /// 初始化
    init() {}
    
    /// 清除所有数据和操作记录
    func reset() {
        fileSystem.removeAll()
        operations.removeAll()
        errorToThrow = nil
    }
    
    // MARK: - 文件操作
    
    /// 检查文件是否存在
    /// - Parameter path: 文件路径
    /// - Returns: 是否存在
    func fileExists(atPath path: String) -> Bool {
        operations.append(.checkExists(path: path))
        return fileSystem[path] != nil
    }
    
    /// 检查文件是否存在，并判断是否是目录
    /// - Parameters:
    ///   - path: 文件路径
    ///   - isDirectory: 是否是目录的引用
    /// - Returns: 是否存在
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        operations.append(.checkExists(path: path))
        
        guard let value = fileSystem[path] else {
            return false
        }
        
        if let isDir = isDirectory {
            isDir.pointee = ObjCBool(value is [String: Any])
        }
        
        return true
    }
    
    /// 创建目录
    /// - Parameters:
    ///   - path: 目录路径
    ///   - createIntermediates: 是否创建中间目录
    ///   - attributes: 属性
    /// - Throws: 错误
    func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        operations.append(.createDirectory(path: path, createIntermediates: createIntermediates))
        
        if let error = errorToThrow {
            throw error
        }
        
        // 标准化路径，确保以 / 开头
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        
        if createIntermediates {
            let components = normalizedPath.components(separatedBy: "/").filter { !$0.isEmpty }
            var currentPath = ""
            
            for component in components {
                currentPath += "/\(component)"
                
                if fileSystem[currentPath] == nil {
                    fileSystem[currentPath] = [String: Any]()
                }
            }
        } else {
            fileSystem[normalizedPath] = [String: Any]()
        }
    }
    
    /// 创建目录
    /// - Parameters:
    ///   - url: 目录URL
    ///   - createIntermediates: 是否创建中间目录
    ///   - attributes: 属性
    /// - Throws: 错误
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        try createDirectory(atPath: url.path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    
    /// 复制文件
    /// - Parameters:
    ///   - srcPath: 源路径
    ///   - dstPath: 目标路径
    /// - Throws: 错误
    func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        operations.append(.copyItem(srcPath: srcPath, dstPath: dstPath))
        
        if let error = errorToThrow {
            throw error
        }
        
        guard let item = fileSystem[srcPath] else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        
        fileSystem[dstPath] = item
    }
    
    /// 复制文件
    /// - Parameters:
    ///   - srcURL: 源URL
    ///   - dstURL: 目标URL
    /// - Throws: 错误
    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try copyItem(atPath: srcURL.path, toPath: dstURL.path)
    }
    
    /// 移动文件
    /// - Parameters:
    ///   - srcPath: 源路径
    ///   - dstPath: 目标路径
    /// - Throws: 错误
    func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
        operations.append(.moveItem(srcPath: srcPath, dstPath: dstPath))
        
        if let error = errorToThrow {
            throw error
        }
        
        guard let item = fileSystem[srcPath] else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        
        fileSystem[dstPath] = item
        fileSystem.removeValue(forKey: srcPath)
    }
    
    /// 移动文件
    /// - Parameters:
    ///   - srcURL: 源URL
    ///   - dstURL: 目标URL
    /// - Throws: 错误
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try moveItem(atPath: srcURL.path, toPath: dstURL.path)
    }
    
    /// 删除文件
    /// - Parameter path: 文件路径
    /// - Throws: 错误
    func removeItem(atPath path: String) throws {
        operations.append(.removeItem(path: path))
        
        if let error = errorToThrow {
            throw error
        }
        
        guard fileSystem[path] != nil else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        
        fileSystem.removeValue(forKey: path)
    }
    
    /// 删除文件
    /// - Parameter url: 文件URL
    /// - Throws: 错误
    func removeItem(at url: URL) throws {
        try removeItem(atPath: url.path)
    }
    
    /// 获取文件内容
    /// - Parameter path: 文件路径
    /// - Returns: 文件内容
    func contents(atPath path: String) -> Data? {
        operations.append(.contentsOfFile(path: path))
        
        guard let item = fileSystem[path], !(item is [String: Any]) else {
            return nil
        }
        
        if let data = item as? Data {
            return data
        }
        
        if let string = item as? String {
            return string.data(using: .utf8)
        }
        
        return nil
    }
    
    /// 写入文件内容
    /// - Parameters:
    ///   - path: 文件路径
    ///   - data: 文件内容
    /// - Returns: 是否成功
    @discardableResult
    func createFile(atPath path: String, contents data: Data?, attributes: [FileAttributeKey: Any]? = nil) -> Bool {
        operations.append(.createFile(path: path))
        
        if errorToThrow != nil {
            return false
        }
        
        fileSystem[path] = data
        return true
    }
    
    /// 获取目录内容
    /// - Parameter path: 目录路径
    /// - Returns: 目录内容
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        operations.append(.contentsOfDirectory(path: path))
        
        if let error = errorToThrow {
            throw error
        }
        
        guard let _ = fileSystem[path] else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        
        // 查找以该路径为前缀的所有文件和目录
        let prefix = path.hasSuffix("/") ? path : path + "/"
        let contents = fileSystem.keys.compactMap { key in
            if key.hasPrefix(prefix) {
                let relativePath = key.dropFirst(prefix.count)
                // 只返回直接子项，不包括更深层次的路径
                if !relativePath.isEmpty && !relativePath.contains("/") {
                    return String(relativePath)
                }
            }
            return nil
        }
        
        return contents
    }
    
    /// 获取目录内容
    /// - Parameter url: 目录URL
    /// - Returns: 目录内容
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        let paths = try contentsOfDirectory(atPath: url.path)
        return paths.map { url.appendingPathComponent($0) }
    }
    
    /// 获取文件属性
    /// - Parameter path: 文件路径
    /// - Returns: 文件属性
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        operations.append(.attributesOfItem(path: path))
        
        if let error = errorToThrow {
            throw error
        }
        
        guard fileSystem[path] != nil else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        
        // 返回一些基本属性
        return [
            .size: 1024,
            .creationDate: Date(),
            .modificationDate: Date(),
            .type: fileSystem[path] is [String: Any] ? FileAttributeType.typeDirectory : FileAttributeType.typeRegular
        ]
    }
    
    // MARK: - 辅助方法
    
    /// 添加文件
    /// - Parameters:
    ///   - path: 文件路径
    ///   - data: 文件内容
    func addFile(at path: String, data: Data) {
        // 确保父目录存在
        let components = path.components(separatedBy: "/")
        if components.count > 1 {
            let directoryPath = components.dropLast().joined(separator: "/")
            if !directoryPath.isEmpty && fileSystem[directoryPath] == nil {
                addDirectory(at: directoryPath)
            }
        }
        
        fileSystem[path] = data
    }
    
    /// 添加目录
    /// - Parameter path: 目录路径
    func addDirectory(at path: String) {
        // 确保父目录存在
        let components = path.components(separatedBy: "/")
        if components.count > 1 {
            var currentPath = ""
            
            for component in components.dropLast() {
                if component.isEmpty { continue }
                
                if !currentPath.isEmpty {
                    currentPath += "/"
                }
                currentPath += component
                
                if !currentPath.isEmpty && fileSystem[currentPath] == nil {
                    fileSystem[currentPath] = [String: Any]()
                }
            }
        }
        
        fileSystem[path] = [String: Any]()
    }
    
    /// 设置错误
    /// - Parameter error: 错误
    func setError(_ error: Error) {
        errorToThrow = error
    }
    
    // MARK: - 验证方法
    
    /// 验证是否有特定操作
    /// - Parameter operation: 操作
    /// - Returns: 是否有操作
    func hasOperation(_ operation: Operation) -> Bool {
        return operations.contains { $0.matches(operation) }
    }
    
    /// 获取特定类型的操作次数
    /// - Parameter type: 操作类型
    /// - Returns: 操作次数
    func operationCount(ofType type: OperationType) -> Int {
        return operations.filter { $0.type == type }.count
    }
    
    /// 获取特定路径的操作次数
    /// - Parameter path: 路径
    /// - Returns: 操作次数
    func operationCount(forPath path: String) -> Int {
        return operations.filter { $0.path == path }.count
    }
    
    // MARK: - 操作类型和操作
    
    /// 操作类型
    enum OperationType {
        case checkExists
        case createDirectory
        case copyItem
        case moveItem
        case removeItem
        case contentsOfFile
        case createFile
        case contentsOfDirectory
        case attributesOfItem
    }
    
    /// 操作
    enum Operation {
        case checkExists(path: String)
        case createDirectory(path: String, createIntermediates: Bool)
        case copyItem(srcPath: String, dstPath: String)
        case moveItem(srcPath: String, dstPath: String)
        case removeItem(path: String)
        case contentsOfFile(path: String)
        case createFile(path: String)
        case contentsOfDirectory(path: String)
        case attributesOfItem(path: String)
        
        /// 获取操作类型
        var type: OperationType {
            switch self {
            case .checkExists: return .checkExists
            case .createDirectory: return .createDirectory
            case .copyItem: return .copyItem
            case .moveItem: return .moveItem
            case .removeItem: return .removeItem
            case .contentsOfFile: return .contentsOfFile
            case .createFile: return .createFile
            case .contentsOfDirectory: return .contentsOfDirectory
            case .attributesOfItem: return .attributesOfItem
            }
        }
        
        /// 获取操作路径
        var path: String {
            switch self {
            case .checkExists(let path): return path
            case .createDirectory(let path, _): return path
            case .copyItem(let srcPath, _): return srcPath
            case .moveItem(let srcPath, _): return srcPath
            case .removeItem(let path): return path
            case .contentsOfFile(let path): return path
            case .createFile(let path): return path
            case .contentsOfDirectory(let path): return path
            case .attributesOfItem(let path): return path
            }
        }
        
        /// 匹配操作
        func matches(_ other: Operation) -> Bool {
            if self.type != other.type { return false }
            
            switch (self, other) {
            case (.checkExists(let path1), .checkExists(let path2)):
                return path1 == path2
            case (.createDirectory(let path1, _), .createDirectory(let path2, _)):
                return path1 == path2
            case (.copyItem(let srcPath1, let dstPath1), .copyItem(let srcPath2, let dstPath2)):
                return srcPath1 == srcPath2 && dstPath1 == dstPath2
            case (.moveItem(let srcPath1, let dstPath1), .moveItem(let srcPath2, let dstPath2)):
                return srcPath1 == srcPath2 && dstPath1 == dstPath2
            case (.removeItem(let path1), .removeItem(let path2)):
                return path1 == path2
            case (.contentsOfFile(let path1), .contentsOfFile(let path2)):
                return path1 == path2
            case (.createFile(let path1), .createFile(let path2)):
                return path1 == path2
            case (.contentsOfDirectory(let path1), .contentsOfDirectory(let path2)):
                return path1 == path2
            case (.attributesOfItem(let path1), .attributesOfItem(let path2)):
                return path1 == path2
            default:
                return false
            }
        }
    }
}
