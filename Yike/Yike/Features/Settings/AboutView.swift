import SwiftUI
import SafariServices

struct AboutView: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.presentationMode) var presentationMode
    @State private var showingWebView = false
    @State private var urlToShow: URL?
    @State private var showingMailView = false
    
    // 定义链接URL
    private let contactEmail = "shicfp@126.com"
    private let supportURL = "https://www.aicodehelper.top/docs/best-practices/support/"
    
    var body: some View {
        VStack(spacing: 30) {
            // 应用图标
            Image(systemName: "brain")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .frame(width: 120, height: 120)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            // 应用名称和版本
            VStack(spacing: 5) {
                Text("忆趣")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("v1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 应用描述
            Text("基于科学记忆方法的智能背诵辅助工具")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 应用信息
            VStack(spacing: 0) {
                InfoRow(title: "应用大小", value: "15MB")
                InfoRow(title: "更新日期", value: "2023-11-15")
                InfoRow(title: "开发者", value: "小宇宙")
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal)
            
            Spacer()
            
            // 按钮组
            VStack(spacing: 10) {
                LinkButton(title: "用户协议", action: {
                    router.navigate(to: .userAgreementView)
                })
                LinkButton(title: "隐私政策", action: {
                    router.navigate(to: .privacyPolicyView)
                })
                LinkButton(title: "技术支持", action: {
                    if let url = URL(string: supportURL) {
                        urlToShow = url
                        showingWebView = true
                    }
                })
                LinkButton(title: "联系我们", action: {
                    showingMailView = true
                })
            }
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
        .padding(.top, 40)
        .navigationTitle("关于")
        .sheet(isPresented: $showingWebView) {
            if let url = urlToShow {
                SafariView(url: url)
            }
        }
        .alert(isPresented: $showingMailView) {
            Alert(
                title: Text("联系我们"),
                message: Text("请发送邮件至：\(contactEmail)"),
                primaryButton: .default(Text("复制邮箱")) {
                    UIPasteboard.general.string = contactEmail
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
}

// Safari视图包装器
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        // 不需要更新
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .offset(y: 16),
            alignment: .bottom
        )
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
} 