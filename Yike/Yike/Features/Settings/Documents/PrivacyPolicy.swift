import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject var router: NavigationRouter
    // 保留presentationMode用于其他可能的需求
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("记得住隐私政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text("本隐私政策描述了记得住应用（以下简称\"我们\"或\"本应用\"）如何收集、使用、存储和共享您的个人信息。我们非常重视您的隐私保护，并致力于维护您对我们的信任。请您仔细阅读本隐私政策，以便了解我们的隐私保护实践。")
                        .padding(.bottom, 8)
                    
                    Text("一、我们收集的信息")
                        .font(.headline)
                    
                    Text("1.1 您提供的信息：当您使用本应用时，我们可能会收集您主动提供的信息，包括但不限于：\n- 您创建的学习内容\n- 您的学习记录和进度\n- 您的设备设置和偏好\n\n1.2 自动收集的信息：当您使用本应用时，我们可能会自动收集某些信息，包括但不限于：\n- 设备信息（如设备型号、操作系统版本、设备设置、唯一设备标识符等）\n- 日志信息（如使用时间、使用时长、崩溃数据等）\n- 性能数据（如应用响应时间、应用崩溃情况等）")
                        .padding(.bottom, 8)
                    
                    Text("二、我们如何使用您的信息")
                        .font(.headline)
                    
                    Text("2.1 提供、维护和改进我们的服务：\n- 处理您的请求和指令\n- 提供个性化的学习体验\n- 分析和改进我们的服务\n- 开发新功能和服务\n\n2.2 保障账户和数据安全：\n- 验证您的身份\n- 防止欺诈和滥用\n- 保护我们的合法权益")
                        .padding(.bottom, 8)
                    
                    Text("三、信息存储")
                        .font(.headline)
                    
                    Text("3.1 存储位置：您的个人信息主要存储在您的设备本地。\n\n3.2 存储期限：我们仅在实现本政策所述目的所必需的期间内保留您的个人信息，除非法律要求或允许更长的保留期限。")
                        .padding(.bottom, 8)
                }
                
                Group {
                    Text("四、信息安全")
                        .font(.headline)
                    
                    Text("4.1 我们采取合理的技术措施和数据安全措施，保护您的个人信息安全。\n4.2 我们会尽合理商业努力保护您的个人信息，但请理解互联网并非绝对安全的环境，我们无法保证信息传输的绝对安全。")
                        .padding(.bottom, 8)
                    
                    Text("五、信息共享")
                        .font(.headline)
                    
                    Text("5.1 我们不会向第三方出售您的个人信息。\n5.2 在以下情况下，我们可能会共享您的个人信息：\n- 获得您的明确同意\n- 遵守适用的法律法规\n- 保护我们的合法权益\n- 响应紧急情况")
                        .padding(.bottom, 8)
                    
                    Text("六、您的权利")
                        .font(.headline)
                    
                    Text("6.1 您有权访问、更正、删除您的个人信息。\n6.2 您有权随时撤回您的同意。\n6.3 如需行使上述权利，请通过本政策末尾提供的联系方式与我们联系。")
                        .padding(.bottom, 8)
                    
                    Text("七、儿童隐私")
                        .font(.headline)
                    
                    Text("本应用不针对13岁以下的儿童。如果我们发现自己收集了13岁以下儿童的个人信息，我们会立即删除相关信息。如果您认为我们可能收集了您孩子的信息，请通过本政策末尾提供的联系方式与我们联系。")
                        .padding(.bottom, 8)
                    
                    Text("八、隐私政策的变更")
                        .font(.headline)
                    
                    Text("8.1 我们可能会不时更新本隐私政策。\n8.2 当我们对本隐私政策做出重大变更时，我们会通过应用内通知或其他适当方式通知您。\n8.3 我们鼓励您定期查阅本隐私政策，以了解我们如何保护您的信息。")
                        .padding(.bottom, 8)
                    
                    Text("九、联系我们")
                        .font(.headline)
                    
                    Text("如果您对本隐私政策有任何疑问、意见或建议，请发送邮件至：shicfp@126.com")
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
    }
}

#Preview {
    PrivacyPolicyView()
        .environmentObject(NavigationRouter.shared)
} 