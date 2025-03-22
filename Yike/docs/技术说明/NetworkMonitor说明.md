# NetworkMonitor技术说明文档

## 1. 概述

NetworkMonitor是一个网络状态监控服务，使用Swift的NWPathMonitor API实现实时网络连接状态监测。它采用单例模式设计，为整个应用提供统一的网络状态监控服务，支持检测网络连接状态和类型（WiFi、蜂窝网络、以太网等）。

## 2. 技术架构

### 2.1 核心组件

- **NWPathMonitor**: Apple提供的网络路径监控API，用于监测网络连接状态变化
- **DispatchQueue**: 用于处理网络状态更新的异步操作
- **发布-订阅模式**: 通过属性观察器和ObservableObject协议实现网络状态变化通知

### 2.2 类图

```
+-------------------+
| NetworkMonitor    |
+-------------------+
| - monitor         |
| - queue           |
| + isConnected     |
| + connectionType  |
+-------------------+
| + shared          |
| + startMonitoring |
| + stopMonitoring  |
| - checkConnectionType |
+-------------------+
```

### 2.3 依赖关系

- **Network框架**: 提供NWPathMonitor API
- **Combine框架**: 提供ObservableObject支持
- **SwiftUI**: 在视图中使用@ObservedObject观察网络状态变化

## 3. 详细设计

### 3.1 单例模式实现

采用静态属性实现单例，确保全局唯一实例：

```swift
static let shared = NetworkMonitor()
```

### 3.2 网络连接状态监控

使用NWPathMonitor监控网络状态变化，通过pathUpdateHandler回调处理状态更新：

```swift
private func startMonitoring() {
    monitor = NWPathMonitor()
    queue = DispatchQueue(label: "NetworkMonitor")
    
    monitor.pathUpdateHandler = { [weak self] path in
        DispatchQueue.main.async {
            self?.isConnected = path.status == .satisfied
            self?.connectionType = self?.checkConnectionType(path)
        }
    }
    
    monitor.start(queue: queue)
}
```

### 3.3 网络类型检测

根据网络路径属性判断具体的网络连接类型：

```swift
private func checkConnectionType(_ path: NWPath) -> ConnectionType {
    if path.usesInterfaceType(.wifi) {
        return .wifi
    } else if path.usesInterfaceType(.cellular) {
        return .cellular
    } else if path.usesInterfaceType(.wiredEthernet) {
        return .ethernet
    } else {
        return .unknown
    }
}
```

### 3.4 应用生命周期管理

在应用启动时开始监控，应用终止时停止监控：

```swift
// 在YikeApp.swift中初始化
@StateObject private var networkMonitor = NetworkMonitor.shared
```

## 4. 使用方法

### 4.1 初始化与配置

在应用入口点初始化NetworkMonitor：

```swift
// YikeApp.swift
struct YikeApp: App {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
        }
    }
}
```

### 4.2 在视图中使用

任何需要网络状态的视图可以使用@EnvironmentObject或@ObservedObject访问：

```swift
struct MyView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if networkMonitor.isConnected {
            Text("网络已连接")
        } else {
            Text("网络未连接")
                .foregroundColor(.red)
        }
    }
}
```

### 4.3 在服务中使用

在其他服务类中检查网络状态：

```swift
// 在IAPManager中使用
func fetchProducts() {
    guard NetworkMonitor.shared.isConnected else {
        print("没有网络连接，无法获取产品信息")
        return
    }
    
    // 获取产品信息的代码
}
```

## 5. 最佳实践

### 5.1 UI反馈

- 在进行网络操作前先检查网络状态
- 网络不可用时提供清晰的视觉反馈
- 网络恢复后自动重试之前失败的操作

### 5.2 性能考虑

- NetworkMonitor是轻量级服务，对性能影响微小
- 监控在后台队列中运行，不阻塞主线程
- 状态更新使用主线程以确保UI更新安全

### 5.3 错误处理

- 为网络操作添加超时机制
- 处理各种网络错误类型(超时、服务器错误等)
- 提供用户友好的错误信息

## 6. 与其他服务集成

### 6.1 与IAPManager集成

```swift
func purchase(product: SKProduct) {
    guard NetworkMonitor.shared.isConnected else {
        // 处理无网络情况
        self.purchaseError = "无网络连接，请检查网络后重试"
        return
    }
    
    // 购买逻辑
}
```

### 6.2 与PointsRechargeView集成

```swift
// 在UI中显示网络状态
if !networkMonitor.isConnected {
    HStack {
        Image(systemName: "wifi.slash")
            .foregroundColor(.red)
        Text("网络连接已断开，请检查网络连接后重试")
            .font(.footnote)
            .foregroundColor(.red)
    }
    .padding(.horizontal)
}
```

## 7. 测试策略

### 7.1 单元测试

- 测试网络状态变化的正确处理
- 测试不同网络类型的检测准确性
- 模拟网络中断和恢复场景

### 7.2 集成测试

- 测试NetworkMonitor与IAPManager的集成
- 测试UI组件对网络状态变化的响应
- 测试网络状态恢复后的自动重试机制

### 7.3 手动测试

- 在飞行模式下测试应用行为
- 在WiFi和蜂窝网络间切换测试
- 测试弱网络环境下的应用表现

## 8. 未来扩展

### 8.1 功能增强

- 添加网络质量评估（延迟、带宽）
- 实现更细粒度的网络错误处理
- 添加网络使用统计功能

### 8.2 架构优化

- 考虑使用Combine进一步简化状态管理
- 添加更多网络相关服务（如Reachability）
- 实现更强大的重试机制和队列管理 