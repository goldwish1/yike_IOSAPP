import StoreKit
import Combine
import SwiftUI

@MainActor
class IAPManager: ObservableObject {
    // 单例模式
    static let shared = IAPManager()
    
    // 发布的状态
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var purchaseError: String?
    
    // 产品ID定义
    private let productIDs = [
        "com.apicloud.yike.points.100",
        "com.apicloud.yike.points.300",
        "com.apicloud.yike.points.600",
        "com.apicloud.yike.points.1000"
    ]
    
    // 产品ID与积分值的映射
    let productPointsMapping: [String: Int] = [
        "com.apicloud.yike.points.100": 100,
        "com.apicloud.yike.points.300": 300,
        "com.apicloud.yike.points.600": 600,
        "com.apicloud.yike.points.1000": 1000
    ]
    
    // 购买状态枚举
    enum PurchaseState {
        case idle
        case purchasing
        case succeeded
        case failed
    }
    
    // 存储交易更新任务
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // 设置交易监听器
        updateListenerTask = listenForTransactions()
        
        // 加载产品信息
        Task {
            await fetchProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 持续监听交易更新
            for await result in StoreKit.Transaction.updates {
                do {
                    // 在新版StoreKit 2中，verificationResult.payloadValue不需要await
                    let transaction = try result.payloadValue
                    
                    // 处理交易
                    await self.handleTransaction(transaction)
                    
                    // 标记交易完成
                    await transaction.finish()
                } catch {
                    // 忽略交易验证错误，但记录它们
                    print("【IAP】交易验证失败: \(error)")
                }
            }
        }
    }
    
    // 处理交易
    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        // 查找对应的积分值
        if let points = self.productPointsMapping[transaction.productID] {
            // 添加积分
            DataManager.shared.addPoints(points, reason: "购买\(points)积分")
            
            // 更新状态
            self.purchaseState = .succeeded
            
            print("【IAP】购买成功: \(transaction.productID), 添加 \(points) 积分")
        }
    }
    
    // 获取产品信息
    @MainActor
    func fetchProducts() async {
        // 检查网络连接
        guard NetworkMonitor.shared.isConnected else {
            print("【IAP】无网络连接，无法获取产品信息")
            return
        }
        
        isLoading = true
        
        do {
            // 使用新API获取产品信息
            let storeProducts = try await Product.products(for: Set(productIDs))
            self.products = storeProducts
            
            if storeProducts.isEmpty {
                print("【IAP】没有找到可用的产品")
            } else {
                print("【IAP】成功加载 \(storeProducts.count) 个产品")
                for product in storeProducts {
                    print("【IAP】产品: \(product.displayName), 价格: \(product.displayPrice)")
                }
            }
        } catch {
            print("【IAP】加载产品失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // 购买产品
    @MainActor
    func purchase(product: Product) async {
        // 重置状态
        purchaseError = nil
        purchaseState = .purchasing
        
        // 检查网络连接
        guard NetworkMonitor.shared.isConnected else {
            purchaseError = "网络连接已断开，请恢复网络连接后重试"
            purchaseState = .failed
            print("【IAP】购买失败: 无网络连接")
            return
        }
        
        // 检查是否可以进行支付
        guard AppStore.canMakePayments else {
            purchaseError = "设备不支持内购"
            purchaseState = .failed
            return
        }
        
        do {
            // 开始购买流程
            let result = try await product.purchase()
            
            // 处理购买结果
            switch result {
            case .success(let verificationResult):
                // 验证购买
                switch verificationResult {
                case .verified(let transaction):
                    // 处理已验证的交易
                    await handleTransaction(transaction)
                    
                    // 标记交易完成
                    await transaction.finish()
                    
                case .unverified(_, let error):
                    // 处理未验证的交易
                    purchaseError = "购买验证失败: \(error.localizedDescription)"
                    purchaseState = .failed
                    print("【IAP】购买验证失败: \(error.localizedDescription)")
                }
            case .pending:
                // 等待外部操作(如家长批准)
                purchaseError = "购买等待中，可能需要家长批准"
                purchaseState = .idle
                print("【IAP】购买等待中")
            case .userCancelled:
                // 用户取消
                purchaseError = "购买已取消"
                purchaseState = .failed
                print("【IAP】用户取消购买")
            @unknown default:
                // 未知状态
                purchaseError = "未知购买状态"
                purchaseState = .failed
                print("【IAP】未知购买状态")
            }
        } catch {
            // 处理购买错误
            purchaseError = "购买失败: \(error.localizedDescription)"
            purchaseState = .failed
            print("【IAP】购买失败: \(error.localizedDescription)")
        }
    }
    
    // 恢复购买（消耗型IAP通常不需要恢复，但保留方法以备后用）
    @MainActor
    func restorePurchases() async {
        // 检查网络连接
        guard NetworkMonitor.shared.isConnected else {
            print("【IAP】无网络连接，无法恢复购买")
            return
        }
        
        do {
            try await AppStore.sync()
            print("【IAP】恢复购买完成")
        } catch {
            print("【IAP】恢复购买失败: \(error.localizedDescription)")
        }
    }
    
    // 通过积分值查找对应的产品
    func getProduct(for points: Int) -> Product? {
        guard let productID = productPointsMapping.first(where: { $0.value == points })?.key else {
            return nil
        }
        return products.first { $0.id == productID }
    }
    
    // 重置状态
    @MainActor
    func resetPurchaseState() {
        self.purchaseState = .idle
        self.purchaseError = nil
    }
}

// MARK: - 辅助功能
extension Product {
    // 格式化价格
    var localizedPrice: String {
        return displayPrice
    }
} 