import Foundation
import AVFoundation

/// 硅基流动文本转语音服务
class SiliconFlowTTSService {
    // 单例模式
    static let shared = SiliconFlowTTSService()
    
    // API密钥
    private let apiKey = "sk-lutyvbdzpvahcfjktdvjlsoheraogfbvsdigfwligyrnlolv"
    private let baseURL = "https://api.siliconflow.cn/v1/audio/speech"
    
    // 音频缓存目录
    private let cacheFolderName = "SiliconFlowTTSCache"
    
    private init() {
        // 创建缓存目录
        createCacheDirectoryIfNeeded()
    }
    
    /// 生成语音
    /// - Parameters:
    ///   - text: 要转换的文本
    ///   - voice: 音色名称
    ///   - speed: 语速
    ///   - completion: 完成回调，返回本地音频文件URL或错误
    func generateSpeech(text: String, voice: String, speed: Float, completion: @escaping (URL?, Error?) -> Void) {
        // 检查缓存
        if let cachedAudioURL = getCachedAudioURL(for: text, voice: voice, speed: speed) {
            print("找到缓存音频: \(cachedAudioURL.path)")
            completion(cachedAudioURL, nil)
            return
        }
        
        // 构建请求
        guard let url = URL(string: baseURL) else {
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
            "input": text,
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
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
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
            let audioURL = self.saveAudioToCache(data: data, text: text, voice: voice, speed: speed)
            completion(audioURL, nil)
        }
        
        task.resume()
    }
    
    /// 获取缓存的音频URL
    private func getCachedAudioURL(for text: String, voice: String, speed: Float) -> URL? {
        let cacheFileName = generateCacheFileName(text: text, voice: voice, speed: speed)
        let cacheURL = getCacheDirectory().appendingPathComponent(cacheFileName)
        
        return FileManager.default.fileExists(atPath: cacheURL.path) ? cacheURL : nil
    }
    
    /// 保存音频到缓存
    private func saveAudioToCache(data: Data, text: String, voice: String, speed: Float) -> URL {
        let cacheFileName = generateCacheFileName(text: text, voice: voice, speed: speed)
        let fileURL = getCacheDirectory().appendingPathComponent(cacheFileName)
        
        do {
            try data.write(to: fileURL)
            print("音频已缓存: \(fileURL.path)")
        } catch {
            print("缓存音频失败: \(error.localizedDescription)")
        }
        
        return fileURL
    }
    
    /// 生成缓存文件名
    private func generateCacheFileName(text: String, voice: String, speed: Float) -> String {
        // 使用文本、音色和速度的哈希值作为文件名
        let textHash = text.hash
        let voiceHash = voice.hash
        let speedString = String(format: "%.1f", speed)
        
        return "tts_\(textHash)_\(voiceHash)_\(speedString).mp3"
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
        return getCachedAudioURL(for: text, voice: voice, speed: speed) != nil
    }
} 