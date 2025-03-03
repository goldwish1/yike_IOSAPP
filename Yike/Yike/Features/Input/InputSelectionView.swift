import SwiftUI

struct InputSelectionView: View {
    @State private var selectedMethod: InputMethod = .manual
    @State private var showCamera = false
    @State private var recognizedText = ""
    @State private var manualText = ""
    @State private var wordCount = 0
    
    enum InputMethod {
        case camera, manual
    }
    
    var body: some View {
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
                TextEditor(text: $manualText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(minHeight: 200)
                    .onChange(of: manualText) { newValue in
                        wordCount = newValue.count
                    }
                
                if manualText.isEmpty {
                    Text("请输入要背诵的内容（250字以内）")
                        .foregroundColor(.gray)
                        .padding(16)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 下一步按钮
            NavigationLink(
                destination: PreviewEditView(text: manualText.isEmpty ? recognizedText : manualText),
                isActive: .constant(!manualText.isEmpty || !recognizedText.isEmpty)
            ) {
                Button(action: {
                    // 导航链接会处理跳转
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
            }
            .disabled(manualText.isEmpty && recognizedText.isEmpty)
        }
        .navigationTitle("新建内容")
        .sheet(isPresented: $showCamera) {
            // 在实际应用中实现相机和OCR功能
            Text("相机和OCR功能将在这里实现")
                .padding()
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