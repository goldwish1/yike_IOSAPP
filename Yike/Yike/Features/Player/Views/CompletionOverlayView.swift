import SwiftUI

/// 完成学习时的遮罩动画视图
struct CompletionOverlayView: View {
    /// 是否显示遮罩
    let isVisible: Bool
    
    /// 动画完成后的回调
    let onAnimationComplete: () -> Void
    
    /// 动画状态
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    // 半透明背景
                    Color.black.opacity(0.3)
                        .ignoresSafeArea(.all, edges: [.horizontal, .bottom]) // 只忽略底部和水平方向的安全区域
                    
                    // 完成提示
                    VStack(spacing: 16) {
                        // 对勾动画
                        Circle()
                            .trim(from: 0, to: animationProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        // 文字提示
                        Text("学习已完成")
                            .font(.headline)
                            .foregroundColor(.white)
                            .opacity(animationProgress)
                    }
                }
                .onAppear {
                    // 启动动画
                    withAnimation(.easeOut(duration: 0.5)) {
                        animationProgress = 1.0
                    }
                    
                    // 1.5秒后调用完成回调
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onAnimationComplete()
                    }
                }
            }
        }
    }
} 