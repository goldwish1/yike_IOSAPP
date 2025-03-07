import Vision
import UIKit

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    // 识别图片中的文本
    func recognizeText(in image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // 将UIImage转换为CIImage
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.imageConversionFailed))
            return
        }
        
        // 创建文字识别请求
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 处理识别结果
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            // 提取识别到的文本
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if recognizedText.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                completion(.success(recognizedText))
            }
        }
        
        // 配置请求
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"] // 支持中文和英文
        request.usesLanguageCorrection = true
        
        // 创建图像处理请求处理器
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 执行请求
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    // OCR错误类型
    enum OCRError: Error, LocalizedError {
        case imageConversionFailed
        case noTextFound
        
        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "图片转换失败，请重试"
            case .noTextFound:
                return "未识别到任何文本，请尝试使用更清晰的图片"
            }
        }
    }
} 