import SwiftUI
import UIKit

struct InputSelectionView: View {
    @State private var selectedMethod: InputMethod = .manual
    @State private var showCamera = false
    @State private var recognizedText = ""
    @State private var manualText = ""
    @State private var wordCount = 0
    @State private var navigateToPreview = false
    @State private var shouldPopToRoot = false
    @State private var selectedImage: UIImage? = nil
    @State private var isRecognizing = false
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.presentationMode) var presentationMode
    
    enum InputMethod {
        case camera, manual
    }
    
    var body: some View {
        ZStack {
            // 使用兼容 iOS 16 以下版本的导航链接
            adaptiveNavigationLink
            
            VStack(spacing: 20) {
                // 输入方式选择
                HStack(spacing: 10) {
                    InputMethodButton(
                        title: "拍照输入",
                        systemImage: "camera",
                        isSelected: selectedMethod == .camera,
                        action: { 
                            selectedMethod = .camera
                            showCamera = true
                        }
                    )
                    
                    InputMethodButton(
                        title: "手动输入",
                        systemImage: "square.and.pencil",
                        isSelected: selectedMethod == .manual,
                        action: { selectedMethod = .manual }
                    )
                }
                .padding(.horizontal)
                
                // 字数统计
                HStack {
                    Spacer()
                    Text("\(wordCount)/250")
                        .font(.footnote)
                        .foregroundColor(wordCount > 250 ? .red : .secondary)
                }
                .padding(.horizontal)
                
                // 文本输入区域
                ZStack(alignment: .topLeading) {
                    if selectedMethod == .manual {
                        TextEditor(text: $manualText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(minHeight: 200)
                            .onChange(of: manualText) { oldValue, newValue in
                                wordCount = newValue.count
                            }
                        
                        if manualText.isEmpty {
                            Text("请输入要背诵的内容（250字以内）")
                                .foregroundColor(.gray)
                                .padding(16)
                        }
                    } else {
                        TextEditor(text: $recognizedText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(minHeight: 200)
                            .onChange(of: recognizedText) { oldValue, newValue in
                                wordCount = newValue.count
                            }
                        
                        if recognizedText.isEmpty {
                            Text(isRecognizing ? "正在识别文字..." : "请通过拍照或从相册选择图片进行OCR识别")
                                .foregroundColor(.gray)
                                .padding(16)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 下一步按钮
                Button(action: {
                    print("点击下一步按钮，当前文本长度: \(selectedMethod == .manual ? manualText.count : recognizedText.count)")
                    if #available(iOS 16.0, *) {
                        let text = selectedMethod == .manual ? manualText : recognizedText
                        router.navigate(to: .preview(text: text, shouldPopToRoot: $shouldPopToRoot))
                    } else {
                        navigateToPreview = true
                    }
                }) {
                    Text("下一步")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                        .padding(.horizontal)
                }
                .disabled((selectedMethod == .manual && manualText.isEmpty) ||
                          (selectedMethod == .camera && recognizedText.isEmpty) ||
                          isRecognizing)
            }
            .navigationTitle("新建内容")
            .sheet(isPresented: $showCamera) {
                CameraOptionsView(
                    isPresented: $showCamera,
                    selectedImage: $selectedImage,
                    recognizedText: $recognizedText,
                    isRecognizing: $isRecognizing
                )
                .environmentObject(dataManager)
            }
            .onChange(of: shouldPopToRoot) { oldValue, newValue in
                print("shouldPopToRoot 变化: \(oldValue) -> \(newValue)")
                if newValue {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            // 显示加载指示器
            if isRecognizing {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("正在识别文字...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
        }
    }
    
    // 兼容 iOS 16 以下版本的导航链接
    @ViewBuilder
    private var adaptiveNavigationLink: some View {
        if #available(iOS 16.0, *) {
            EmptyView()
                .navigationDestination(isPresented: $navigateToPreview) {
                    PreviewEditView(
                        text: selectedMethod == .manual ? manualText : recognizedText,
                        shouldPopToRoot: $shouldPopToRoot
                    )
                }
        } else {
            NavigationLink(
                destination: PreviewEditView(
                    text: selectedMethod == .manual ? manualText : recognizedText,
                    shouldPopToRoot: $shouldPopToRoot
                ),
                isActive: $navigateToPreview
            ) {
                EmptyView()
            }
        }
    }
}

struct InputMethodButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .blue : .primary)
        }
    }
} 