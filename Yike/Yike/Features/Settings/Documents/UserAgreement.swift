import SwiftUI

struct UserAgreementView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("记得住用户协议")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("欢迎使用记得住应用！")
                            .font(.headline)
                        
                        Text("本协议是您与记得住应用（以下简称\"本应用\"）之间关于您使用本应用服务所订立的协议。请您仔细阅读本协议，您点击\"同意\"按钮或继续使用本应用，即表示您已充分理解并同意本协议的全部内容。")
                            .padding(.bottom, 8)
                        
                        Text("一、服务内容")
                            .font(.headline)
                        
                        Text("1.1 本应用是一款基于科学记忆方法的智能背诵辅助工具，专注于帮助学生通过听觉重复和智能提醒来提升记忆效率。\n1.2 本应用提供的具体服务内容包括但不限于：文本识别、语音播放、记忆提醒、学习统计等功能。")
                            .padding(.bottom, 8)
                        
                        Text("二、用户行为规范")
                            .font(.headline)
                        
                        Text("2.1 您在使用本应用服务时，必须遵守中华人民共和国相关法律法规的规定，不得利用本应用从事违法违规行为。\n2.2 您不得利用本应用进行任何可能对互联网正常运行造成不利影响的行为。\n2.3 您不得利用本应用传播任何骚扰性、中伤性、诽谤性、辱骂性、恐吓性、庸俗性或淫秽性的信息。")
                            .padding(.bottom, 8)
                    }
                    
                    Group {
                        Text("三、知识产权")
                            .font(.headline)
                        
                        Text("3.1 本应用的所有权、运营权和知识产权归本应用开发者所有。\n3.2 未经本应用开发者明确书面许可，您不得以任何形式复制、模仿、传播、出版、公布、展示本应用的任何内容。")
                            .padding(.bottom, 8)
                        
                        Text("四、隐私保护")
                            .font(.headline)
                        
                        Text("4.1 保护用户隐私是本应用的基本政策，本应用会按照《记得住隐私政策》的规定收集、使用、储存和分享您的个人信息。\n4.2 本应用不会向任何第三方提供、公开或共享您的个人信息，除非事先获得您的明确授权。")
                            .padding(.bottom, 8)
                        
                        Text("五、免责声明")
                            .font(.headline)
                        
                        Text("5.1 您理解并同意，在使用本应用服务的过程中，可能会遇到不可抗力等风险因素，本应用不对因此导致的任何损失承担责任。\n5.2 本应用不保证服务一定能满足您的要求，也不保证服务不会中断，对服务的及时性、安全性、准确性也不作保证。")
                            .padding(.bottom, 8)
                        
                        Text("六、协议修改")
                            .font(.headline)
                        
                        Text("6.1 本应用有权在必要时修改本协议条款，协议条款一旦发生变动，将会在本应用上公布修改后的协议内容。\n6.2 如果您不同意修改后的条款，可以选择停止使用本应用；如果您继续使用本应用，则视为您接受修改后的协议。")
                            .padding(.bottom, 8)
                        
                        Text("七、适用法律")
                            .font(.headline)
                        
                        Text("7.1 本协议的订立、执行和解释及争议的解决均应适用中华人民共和国法律。\n7.2 如双方就本协议内容或执行发生争议，应友好协商解决；协商不成时，任何一方均可向本应用所在地有管辖权的人民法院提起诉讼。")
                            .padding(.bottom, 8)
                        
                        Text("八、联系我们")
                            .font(.headline)
                        
                        Text("如您对本协议有任何疑问，或者有任何投诉、建议，请发送邮件至：shicfp@126.com")
                    }
                }
                .padding()
            }
            .navigationBarTitle("用户协议", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    UserAgreementView()
} 