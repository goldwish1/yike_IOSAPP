import SwiftUI

struct TechnicalSupportView: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("忆趣技术支持")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Group {
                    Text("欢迎使用忆趣应用！本页面提供技术支持信息，帮助您解决使用中可能遇到的问题。")
                        .padding(.bottom, 8)
                    
                    Text("一、常见问题")
                        .font(.headline)
                    
                    Text("1.1 应用无法打开或崩溃")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 请确保您的iOS系统版本为16.0或更高版本\n• 尝试关闭后台所有应用，然后重新打开忆趣\n• 如仍有问题，请尝试重启设备后再次打开应用")
                        .padding(.bottom, 8)
                    
                    Text("1.2 语音播放问题")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 检查设备是否处于静音模式\n• 确保应用有麦克风权限（设置→隐私→麦克风）\n• 在线语音功能需要网络连接，请确保您的设备已连接互联网\n• 如使用在线语音时遇到问题，可尝试使用本地语音模式")
                        .padding(.bottom, 8)
                    
                    Text("1.3 OCR文字识别问题")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 确保应用有相机权限（设置→隐私→相机）\n• 拍照时保持画面稳定，文字清晰可见\n• 避免在光线过暗或过亮环境下拍摄\n• 对于复杂格式的文本，建议手动输入获得更好的效果")
                        .padding(.bottom, 8)
                }
                
                Group {
                    Text("1.4 提醒功能问题")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 确保应用有通知权限（设置→通知→忆趣）\n• 检查是否在应用内开启了提醒功能\n• 请勿开启\"请勿打扰\"模式，以免错过重要提醒")
                        .padding(.bottom, 8)
                    
                    Text("1.5 积分相关问题")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 购买积分时请确保网络连接稳定\n• 如支付成功但积分未到账，请等待几分钟后刷新或重启应用\n• 如长时间未收到购买的积分，请联系我们的客服邮箱")
                        .padding(.bottom, 8)
                    
                    Text("二、功能使用指南")
                        .font(.headline)
                    
                    Text("2.1 创建记忆内容")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 点击主页面的\"+\"按钮新建记忆内容\n• 可以通过拍照OCR识别或手动输入文本\n• 输入完成后点击\"保存\"按钮")
                        .padding(.bottom, 8)
                    
                    Text("2.2 使用语音播放")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 在播放界面可调整语音类型、语速和重复间隔\n• 本地语音无需积分，在线语音每次使用消耗5积分\n• 播放时可切换上一条/下一条内容，也可暂停和继续")
                        .padding(.bottom, 8)
                    
                    Text("2.3 设置提醒")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 在设置页面可开启艾宾浩斯记忆曲线提醒\n• 可选择提醒方式：仅通知、通知+声音或通知+震动\n• 系统会根据科学记忆规律在最佳时间点提醒您复习")
                        .padding(.bottom, 8)
                }
                
                Group {
                    Text("三、隐私与账户")
                        .font(.headline)
                    
                    Text("3.1 数据安全")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 您的所有学习内容均存储在设备本地，我们不会上传到服务器\n• 在线语音功能会将文字内容发送到语音服务提供商进行处理，但不会保存您的内容")
                        .padding(.bottom, 8)
                    
                    Text("3.2 购买与退款")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• 所有购买都通过Apple的App Store处理\n• 如需退款，请直接联系Apple支持：reportaproblem.apple.com")
                        .padding(.bottom, 8)
                    
                    Text("四、联系我们")
                        .font(.headline)
                    
                    Text("如您有任何其他问题或建议，请发送邮件至：shicfp@126.com\n\n我们的支持团队将在24小时内回复您的邮件。")
                        .padding(.bottom, 8)
                    
                    Text("五、系统要求")
                        .font(.headline)
                    
                    Text("• iOS 16.0或更高版本\n• 推荐设备：iPhone XS及以上机型\n• 约15MB的存储空间")
                }
            }
            .padding()
        }
        .navigationTitle("技术支持")
    }
}

#Preview {
    TechnicalSupportView()
        .environmentObject(NavigationRouter.shared)
} 