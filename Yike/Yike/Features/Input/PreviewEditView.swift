import SwiftUI

struct PreviewEditView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var content: String
    @State private var showingSaveAlert = false
    
    @Binding var shouldPopToRoot: Bool
    
    // 添加编辑模式标志和可选的memoryItem参数
    let isEditMode: Bool
    let existingItem: MemoryItem?
    
    // 初始化方法 - 新建模式
    init(text: String, shouldPopToRoot: Binding<Bool>) {
        let defaultTitle = text.components(separatedBy: ["。", "！", "？", ".", "!", "?", "\n"])
            .first?
            .prefix(5)
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "新建内容"
        
        _title = State(initialValue: defaultTitle)
        _content = State(initialValue: text)
        _shouldPopToRoot = shouldPopToRoot
        self.isEditMode = false
        self.existingItem = nil
    }
    
    // 新增初始化方法 - 编辑模式
    init(memoryItem: MemoryItem, shouldPopToRoot: Binding<Bool>) {
        _title = State(initialValue: memoryItem.title)
        _content = State(initialValue: memoryItem.content)
        _shouldPopToRoot = shouldPopToRoot
        self.isEditMode = true
        self.existingItem = memoryItem
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
                Text(isEditMode ? "保存修改" : "保存")
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
        .navigationTitle(isEditMode ? "编辑内容" : "预览编辑")
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("成功"),
                message: Text(isEditMode ? "内容已更新" : "内容已保存"),
                dismissButton: .default(Text("确定")) {
                    shouldPopToRoot = true
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveContent() {
        if isEditMode, let existingItem = existingItem {
            // 编辑模式 - 更新现有内容
            var updatedItem = existingItem
            updatedItem.title = title
            updatedItem.content = content
            
            // 更新数据
            dataManager.updateMemoryItem(updatedItem)
            
            // 清除相关缓存（如果有API语音缓存）
            SiliconFlowTTSService.shared.clearCache(for: existingItem.content)
        } else {
            // 新建模式 - 创建新内容
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
        }
        
        showingSaveAlert = true
    }
} 