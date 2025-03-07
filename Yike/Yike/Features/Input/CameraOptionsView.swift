import SwiftUI
import UIKit
import AVFoundation

struct CameraOptionsView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var recognizedText: String
    @Binding var isRecognizing: Bool
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var imageSource: ImageSource = .camera
    @EnvironmentObject private var dataManager: DataManager
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    enum ImageSource {
        case camera
        case photoLibrary
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择图片来源")
                .font(.headline)
                .padding(.top)
            
            Button(action: {
                checkCameraPermission { granted in
                    if granted {
                        imageSource = .camera
                        showCameraPicker = true
                    } else {
                        alertTitle = "无法访问相机"
                        alertMessage = "请在设置中允许应用访问相机"
                        showAlert = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                    Text("拍照")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                imageSource = .photoLibrary
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20))
                    Text("从相册选择")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                isPresented = false
            }) {
                Text("取消")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .sheet(isPresented: $showImagePicker) {
            if #available(iOS 14, *) {
                PHImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker)
                    .onDisappear {
                        if let image = selectedImage {
                            processImage(image)
                        }
                    }
            } else {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker, sourceType: .photoLibrary)
                    .onDisappear {
                        if let image = selectedImage {
                            processImage(image)
                        }
                    }
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(selectedImage: $selectedImage, isPresented: $showCameraPicker, sourceType: .camera)
                .onDisappear {
                    if let image = selectedImage {
                        processImage(image)
                    }
                }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    private func processImage(_ image: UIImage) {
        // 检查积分是否足够
        if dataManager.points < 10 {
            alertTitle = "积分不足"
            alertMessage = "OCR识别需要10积分，当前积分余额不足"
            showAlert = true
            isPresented = false
            return
        }
        
        isRecognizing = true
        
        // 使用OCR服务识别文本
        OCRService.shared.recognizeText(in: image) { result in
            isRecognizing = false
            
            switch result {
            case .success(let text):
                recognizedText = text
                // 扣除积分
                let success = dataManager.deductPoints(10, reason: "OCR识别")
                if !success {
                    alertTitle = "积分扣除失败"
                    alertMessage = "请稍后重试"
                    showAlert = true
                }
                isPresented = false
                
            case .failure(let error):
                alertTitle = "识别失败"
                alertMessage = error.localizedDescription
                showAlert = true
                isPresented = false
            }
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
} 