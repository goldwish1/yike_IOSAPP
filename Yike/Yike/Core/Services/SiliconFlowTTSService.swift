import Foundation
import AVFoundation
import Combine
import SwiftUI
import CommonCrypto

/// 硅基流动文本转语音服务
@objc class SiliconFlowTTSService: NSObject {
    // 单例模式
    @objc static let shared = SiliconFlowTTSService()
    
    // API密钥
    private let apiKey: String
    private let baseURL = "https://api.siliconflow.cn/v1/audio/speech"
    
    // 音频缓存目录
    private let cacheFolderName = "SiliconFlowTTSCache"
    
    // 当前正在进行的请求
    private var currentTask: URLSessionTask?
    
    // 允许子类重写初始化方法
    internal override init() {
        // 从Secrets.plist读取API KEY
        let apiKeyFromPlist = SiliconFlowTTSService.getAPIKeyFromPlist()
        self.apiKey = apiKeyFromPlist ?? "sk-lutyvbdzpvahcfjktdvjlsoheraogfbvsdigfwligyrnlolv" // 如果读取失败，使用默认值作为后备
        
        super.init()
        // 创建缓存目录
        createCacheDirectoryIfNeeded()
    }
    
    /// 取消当前请求
    func cancelCurrentRequest() {
        if let task = currentTask {
            print("【调试】SiliconFlowTTSService: 取消当前API请求 - 时间: \(Date())")
            task.cancel()
            currentTask = nil
        } else {
            print("【调试】SiliconFlowTTSService: 没有活动的API请求需要取消 - 时间: \(Date())")
        }
    }
    
    /// 从Secrets.plist读取API KEY
    private static func getAPIKeyFromPlist() -> String? {
        guard let plistPath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plistDict = NSDictionary(contentsOfFile: plistPath),
              let apiKeys = plistDict["APIKeys"] as? [String: Any],
              let apiKey = apiKeys["SiliconFlowAPIKey"] as? String,
              !apiKey.isEmpty,
              apiKey != "YOUR_API_KEY_HERE" else {
            print("【警告】无法从Secrets.plist读取有效的API KEY")
            return nil
        }
        return apiKey
    }
    
    /// 生成语音
    /// - Parameters:
    ///   - text: 要转换的文本
    ///   - voice: 音色名称
    ///   - speed: 语速
    ///   - completion: 完成回调，返回本地音频文件URL或错误
    func generateSpeech(text: String, voice: String, speed: Float, completion: @escaping (URL?, Error?) -> Void) {
        // 预处理文本，优化停顿，根据速度调整停顿强度
        let processedText = preprocessText(text, speed: speed)
        
        print("【缓存日志】开始生成语音，文本长度: \(text.count)，音色: \(voice)，速度: \(speed)")
        
        // 取消任何正在进行的请求
        cancelCurrentRequest()
        
        // 检查缓存
        if let cachedAudioURL = getCachedAudioURL(for: processedText, voice: voice, speed: speed) {
            print("【缓存日志】找到缓存音频: \(cachedAudioURL.path)")
            completion(cachedAudioURL, nil)
            return
        }
        
        print("【缓存日志】未找到缓存，需要请求API")
        
        // 构建请求
        guard let url = URL(string: baseURL) else {
            print("【缓存日志】无效的URL")
            completion(nil, NSError(domain: "SiliconFlowTTSService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": "FunAudioLLM/CosyVoice2-0.5B",
            "input": processedText,
            "voice": "FunAudioLLM/CosyVoice2-0.5B:\(voice)",
            "speed": speed,
            "response_format": "mp3"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(nil, error)
            return
        }
        
        // 创建请求任务
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            // 清除当前任务引用
            DispatchQueue.main.async {
                self.currentTask = nil
            }
            
            // 如果请求被取消，直接返回
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                print("【调试】SiliconFlowTTSService: API请求已被取消 - 时间: \(Date())")
                completion(nil, error)
                return
            }
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "SiliconFlowTTSService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "无效的响应"]))
                return
            }
            
            guard httpResponse.statusCode == 200, let data = data else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "未知错误"
                completion(nil, NSError(domain: "SiliconFlowTTSService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                return
            }
            
            // 保存音频文件到缓存
            let audioURL = self.saveAudioToCache(data: data, text: processedText, voice: voice, speed: speed)
            completion(audioURL, nil)
        }
        
        // 存储当前请求任务
        self.currentTask = task
        print("【调试】SiliconFlowTTSService: 启动新的API请求 taskID=\(task.taskIdentifier) - 时间: \(Date())")
        
        // 开始任务
        task.resume()
    }
    
    /// 预处理文本，优化停顿
    /// - Parameters:
    ///   - text: 原始文本
    ///   - speed: 播放速度，用于调整停顿强度
    /// - Returns: 处理后的文本
    private func preprocessText(_ text: String, speed: Float = 1.0) -> String {
        // 检测文本是否为古诗文格式
        let isClassicalPoem = isClassicalChinesePoem(text)
        
        // 如果不是古诗文，则返回原文本
        if !isClassicalPoem {
            return text
        }
        
        var processedText = text
        
        // 根据速度调整停顿标记
        let pauseMark = getPauseMarkForSpeed(speed)
        
        // 1. 增强标点符号的停顿效果
        // 在标点符号前添加停顿标记，使停顿更明显
        processedText = processedText.replacingOccurrences(of: "，", with: "\(pauseMark)，")
        processedText = processedText.replacingOccurrences(of: "。", with: "\(pauseMark)。")
        processedText = processedText.replacingOccurrences(of: "？", with: "\(pauseMark)？")
        processedText = processedText.replacingOccurrences(of: "?", with: "\(pauseMark)?")
        processedText = processedText.replacingOccurrences(of: "！", with: "\(pauseMark)！")
        processedText = processedText.replacingOccurrences(of: "!", with: "\(pauseMark)!")
        
        // 2. 处理古诗文中的行末停顿
        // 在每行末尾添加停顿标记
        let lines = processedText.components(separatedBy: "\n")
        processedText = lines.map { line -> String in
            var processedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !processedLine.isEmpty {
                // 如果行末没有标点，添加停顿标记
                if !["，", "。", "、", "；", "！", "？", "：", "!", "?"].contains(String(processedLine.last!)) {
                    processedLine += pauseMark
                }
            }
            return processedLine
        }.joined(separator: "\n")
        
        // 3. 清理重复的停顿标记
        processedText = processedText.replacingOccurrences(of: "、、", with: "、")
        processedText = processedText.replacingOccurrences(of: "，、", with: "，")
        processedText = processedText.replacingOccurrences(of: "。、", with: "。")
        processedText = processedText.replacingOccurrences(of: "？、", with: "？")
        processedText = processedText.replacingOccurrences(of: "?、", with: "?")
        processedText = processedText.replacingOccurrences(of: "！、", with: "！")
        processedText = processedText.replacingOccurrences(of: "!、", with: "!")
        
        return processedText
    }
    
    /// 根据播放速度获取适当的停顿标记
    /// - Parameter speed: 播放速度
    /// - Returns: 停顿标记
    private func getPauseMarkForSpeed(_ speed: Float) -> String {
        // 低速播放时使用更强的停顿标记
        if speed <= 0.8 {
            return "，" // 低速时使用逗号作为停顿标记，效果更强
        } else if speed < 1.2 {
            return "、，" // 中速时使用顿号+逗号
        } else {
            return "、" // 高速时使用顿号即可
        }
    }
    
    /// 判断文本是否为古诗文格式
    /// - Parameter text: 要判断的文本
    /// - Returns: 是否为古诗文
    private func isClassicalChinesePoem(_ text: String) -> Bool {
        // 简单判断是否为古诗文的规则：
        // 1. 行数大于1
        // 2. 每行字数相近（5-7字为主）
        // 3. 包含古诗文常见标点
        
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 至少有两行
        if lines.count < 2 {
            return false
        }
        
        // 检查行长度
        let lineLengths = lines.map { $0.count }
        let averageLength = lineLengths.reduce(0, +) / lineLengths.count
        
        // 古诗文通常每行5-7字，允许有标点符号，所以范围稍宽松
        let isRegularLength = averageLength >= 4 && averageLength <= 12
        
        // 检查是否包含古诗文常见标点
        let hasClassicalPunctuation = text.contains("，") || text.contains("。") || text.contains("、") || text.contains("；")
        
        // 检查是否包含古诗文常见词语
        let hasClassicalWords = text.contains("若") || text.contains("于") || text.contains("之") || 
                               text.contains("乎") || text.contains("也") || text.contains("兮")
        
        return isRegularLength && (hasClassicalPunctuation || hasClassicalWords)
    }
    
    /// 获取缓存的音频URL
    private func getCachedAudioURL(for text: String, voice: String, speed: Float) -> URL? {
        let cacheFileName = generateCacheFileName(text: text, voice: voice, speed: speed)
        let cacheURL = getCacheDirectory().appendingPathComponent(cacheFileName)
        
        let exists = FileManager.default.fileExists(atPath: cacheURL.path)
        print("【缓存日志】检查缓存文件: \(cacheFileName), 是否存在: \(exists)")
        
        if exists {
            print("【缓存日志】找到缓存文件: \(cacheURL.path)")
        } else {
            print("【缓存日志】未找到缓存文件: \(cacheURL.path)")
        }
        
        return exists ? cacheURL : nil
    }
    
    /// 保存音频到缓存
    private func saveAudioToCache(data: Data, text: String, voice: String, speed: Float) -> URL {
        let cacheFileName = generateCacheFileName(text: text, voice: voice, speed: speed)
        let fileURL = getCacheDirectory().appendingPathComponent(cacheFileName)
        
        do {
            try data.write(to: fileURL)
            print("【缓存日志】音频已缓存: \(fileURL.path)")
        } catch {
            print("【缓存日志】缓存音频失败: \(error.localizedDescription)")
        }
        
        return fileURL
    }
    
    /// 生成缓存文件名
    private func generateCacheFileName(text: String, voice: String, speed: Float) -> String {
        // 使用稳定的哈希算法，而不是Swift的String.hash属性
        let textData = text.data(using: .utf8) ?? Data()
        let voiceData = voice.data(using: .utf8) ?? Data()
        let speedString = String(format: "%.1f", speed)
        
        // 使用SHA256哈希算法
        let textHash = sha256Hash(data: textData)
        let voiceHash = sha256Hash(data: voiceData)
        
        let fileName = "tts_\(textHash)_\(voiceHash)_\(speedString).mp3"
        print("【缓存日志】生成缓存文件名: \(fileName) 用于文本: \(text.prefix(20))...")
        
        return fileName
    }
    
    /// 计算SHA256哈希值
    private func sha256Hash(data: Data) -> String {
        // 使用CommonCrypto计算SHA256
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        
        // 将字节数组转换为十六进制字符串
        let hexString = digest.map { String(format: "%02x", $0) }.joined()
        return hexString
    }
    
    /// 获取缓存目录
    private func getCacheDirectory() -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent(cacheFolderName)
    }
    
    /// 创建缓存目录
    private func createCacheDirectoryIfNeeded() {
        let cacheDir = getCacheDirectory()
        
        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                print("创建缓存目录: \(cacheDir.path)")
            } catch {
                print("创建缓存目录失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 清理过期缓存
    func cleanExpiredCache(olderThan days: Int = 30) {
        let cacheDir = getCacheDirectory()
        let fileManager = FileManager.default
        
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        for fileURL in fileURLs {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attributes[.creationDate] as? Date else {
                continue
            }
            
            let components = calendar.dateComponents([.day], from: creationDate, to: currentDate)
            
            if let daysOld = components.day, daysOld > days {
                try? fileManager.removeItem(at: fileURL)
                print("删除过期缓存: \(fileURL.path)")
            }
        }
    }
    
    /// 检查音频是否已缓存
    /// - Parameters:
    ///   - text: 文本内容
    ///   - voice: 音色名称
    ///   - speed: 语速
    /// - Returns: 是否已缓存
    func isCached(text: String, voice: String, speed: Float) -> Bool {
        print("【缓存日志】检查缓存状态 - 原始文本: \"\(text.prefix(20))...\"")
        
        // 检查原始文本和预处理后的文本是否有缓存
        let processedText = preprocessText(text, speed: speed)
        
        // 生成缓存文件名
        let originalFileName = generateCacheFileName(text: text, voice: voice, speed: speed)
        let processedFileName = generateCacheFileName(text: processedText, voice: voice, speed: speed)
        
        // 获取缓存文件路径
        let originalCacheURL = getCacheDirectory().appendingPathComponent(originalFileName)
        let processedCacheURL = getCacheDirectory().appendingPathComponent(processedFileName)
        
        // 检查文件是否存在
        let originalExists = FileManager.default.fileExists(atPath: originalCacheURL.path)
        let processedExists = (processedText != text) && FileManager.default.fileExists(atPath: processedCacheURL.path)
        
        print("【缓存日志】检查缓存状态 - 原始文本缓存: \(originalExists), 文件: \(originalFileName)")
        if processedText != text {
            print("【缓存日志】检查缓存状态 - 处理后文本缓存: \(processedExists), 文件: \(processedFileName)")
        }
        
        return originalExists || processedExists
    }
    
    /// 清除特定文本内容的所有缓存
    /// - Parameter text: 要清除缓存的文本内容
    func clearCache(for text: String) {
        let cacheDir = getCacheDirectory()
        let fileManager = FileManager.default
        
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return
        }
        
        // 获取原始文本的哈希值
        let textHash = text.hash
        
        // 获取不同速度下预处理文本的哈希值
        let slowProcessedTextHash = preprocessText(text, speed: 0.5).hash
        let normalProcessedTextHash = preprocessText(text, speed: 1.0).hash
        let fastProcessedTextHash = preprocessText(text, speed: 1.5).hash
        
        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
            // 检查文件名是否包含原始文本或任何速度下预处理后文本的哈希值
            if fileName.contains("tts_\(textHash)_") || 
               fileName.contains("tts_\(slowProcessedTextHash)_") ||
               fileName.contains("tts_\(normalProcessedTextHash)_") ||
               fileName.contains("tts_\(fastProcessedTextHash)_") {
                try? fileManager.removeItem(at: fileURL)
                print("已删除缓存: \(fileURL.path)")
            }
        }
    }
    
    /// 清除所有缓存
    func clearAllCache() {
        let cacheDir = getCacheDirectory()
        let fileManager = FileManager.default
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
                print("【缓存日志】已删除缓存: \(fileURL.path)")
            }
            
            print("【缓存日志】已清除所有缓存文件")
        } catch {
            print("【缓存日志】清除缓存失败: \(error.localizedDescription)")
        }
    }
} 