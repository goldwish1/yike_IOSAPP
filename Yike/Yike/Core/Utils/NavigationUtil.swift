import SwiftUI

/// 导航工具类,用于处理导航相关的操作
/// 主要提供返回到根视图等导航控制功能
struct NavigationUtil {
    /// 返回到根视图
    /// 该方法会将导航栈清空,回到最顶层的根视图
    /// 常用于需要重置导航状态的场景,比如用户完成某个流程后需要返回主页面
    static func popToRootView() {
        // 获取当前窗口的根视图控制器,并查找其导航控制器
        // filter isKeyWindow 用于获取当前激活的窗口
        findNavigationController(viewController: UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController)?
            .popToRootViewController(animated: true) // 带动画效果返回到根视图
    }
    
    /// 递归查找导航控制器
    /// 该方法会从传入的视图控制器开始,递归查找其导航控制器
    /// - Parameter viewController: 要查找的起始视图控制器
    /// - Returns: 找到的导航控制器,如果没找到则返回nil
    static private func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        // 如果传入的视图控制器为nil,则返回nil
        guard let viewController = viewController else {
            return nil
        }
        
        // 如果当前视图控制器就是导航控制器,则直接返回
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        // 递归遍历子视图控制器查找导航控制器
        // 注意:这里的实现假设导航控制器在第一个子视图中
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
        }
        
        return nil
    }
} 