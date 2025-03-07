import SwiftUI

struct PreviewEditView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var content: String
    @State private var showingSaveAlert = false
    
    @Binding var shouldPopToRoot: Bool
    
    init(text: String, shouldPopToRoot: Binding<Bool>) {
        let defaultTitle = text.components(separatedBy: ["。", "！", "？", ".", "!", "?", "\n"])
            .first?
            .prefix(5)
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "新建内容"
        
        _title = State(initialValue: defaultTitle)
        _content = State(initialValue: text)
        _shouldPopToRoot = shouldPopToRoot
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("内容标题")
                .font(.headline)
            
            TextField("请输入标题", text: $title)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Text("内容预览")
                .font(.headline)
            
            TextEditor(text: $content)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(minHeight: 200)
            
            Spacer()
            
            Button(action: saveContent) {
                Text("保存")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .disabled(title.isEmpty || content.isEmpty)
        }
        .padding()
        .navigationTitle("预览编辑")
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("成功"),
                message: Text("内容已保存"),
                dismissButton: .default(Text("确定")) {
                    shouldPopToRoot = true
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveContent() {
        let newItem = MemoryItem(
            id: UUID(),
            title: title,
            content: content,
            progress: 0.0,
            reviewStage: 0,
            lastReviewDate: nil,
            nextReviewDate: nil
        )
        
        dataManager.addMemoryItem(newItem)
        showingSaveAlert = true
    }
} 