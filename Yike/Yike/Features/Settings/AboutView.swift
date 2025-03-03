import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
                    Text("忆刻")
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
                    InfoRow(title: "开发者", value: "忆刻团队")
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
                    LinkButton(title: "用户协议", action: {})
                    LinkButton(title: "隐私政策", action: {})
                    LinkButton(title: "联系我们", action: {})
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 40)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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