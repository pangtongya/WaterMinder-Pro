// StoreManager.swift
// StoreKit 2 内购管理 —— Pro 年订阅 + 终身买断
//
// 功能：加载商品、发起购买、监听交易更新、验证权益、恢复购买。
// Pro 解锁：全部品种 + 高级统计 + iCloud 同步 + 无限花园。

import Foundation
import StoreKit

// MARK: - 产品定义

enum BloomProduct {
    /// Pro 年订阅
    static let yearlyID = "com.pangtong.bloom.pro.yearly"
    /// Pro 终身买断
    static let lifetimeID = "com.pangtong.bloom.pro.lifetime"

    static let allIDs: Set<String> = [yearlyID, lifetimeID]
}

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// 已加载的商品（按价格排序）
    @Published private(set) var products: [Product] = []

    /// 是否正在加载
    @Published private(set) var isLoading = false

    /// 是否正在购买
    @Published private(set) var isPurchasing = false

    /// 购买结果错误
    @Published var lastError: String?

    private var transactionListener: Task<Void, Error>?

    /// 解锁 Pro 的回调（购买成功后通知 UserStore）
    var onProUnlocked: ((String) -> Void)?

    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 加载商品

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        // 开发模式：使用模拟商品进行测试
        let isDevMode = ProcessInfo.processInfo.environment["BLOOM_DEV_MODE"] == "1"
        if isDevMode {
            print("⚠️ [StoreManager] 沙盒测试模式 - 使用模拟商品")
            // 注意：由于 Product 是 StoreKit 的类型，我们无法直接创建实例
            // 这里设置为空，让 PaywallView 显示开发模式提示
            products = []
            return
        }
        #endif

        do {
            let storeProducts = try await Product.products(for: BloomProduct.allIDs)
            // 按价格排序（年订阅通常比终身便宜，放前面）
            products = storeProducts.sorted { $0.price < $1.price }
            if products.isEmpty {
                print("⚠️ [StoreManager] App Store Connect 中未配置商品")
            }
        } catch {
            lastError = "无法加载商品：\(error.localizedDescription)"
        }
    }

    // MARK: - Pro 状态查询

    /// 当前是否为 Pro（优先查交易状态，回退闭包）
    var isProProvider: () -> Bool = { false }
    var isPro: Bool {
        #if DEBUG
        // 开发模式：可以通过 UserDefaults 手动设置 Pro 状态进行测试
        if UserDefaults.standard.bool(forKey: "bloom.dev.pro") { return true }
        #endif
        
        // 先查本地缓存的权益
        if UserDefaults.standard.bool(forKey: "bloom.isPro") { return true }
        return isProProvider()
    }

    // MARK: - 购买

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await deliverTransaction(transaction)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                lastError = "购买待处理，请稍后查看"
            @unknown default:
                break
            }
        } catch {
            lastError = "购买失败：\(error.localizedDescription)"
        }
    }

    // MARK: - 恢复购买

    func restore() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            lastError = "恢复购买失败：\(error.localizedDescription)"
        }
    }

    // MARK: - 交易监听（后台续订/退款）

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let t = transaction {
                        await self?.deliverTransaction(t)
                        await t.finish()
                    }
                } catch {
                    // 交易未通过验证，忽略
                }
            }
        }
    }

    // MARK: - 更新本地权益

    private func updatePurchasedProducts() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if BloomProduct.allIDs.contains(transaction.productID) {
                    hasPro = true
                    break
                }
            }
        }

        UserDefaults.standard.set(hasPro, forKey: "bloom.isPro")
        if hasPro {
            onProUnlocked?("restored")
        }
    }

    // MARK: - 交易验证

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.verificationFailed
        }
    }

    private func deliverTransaction(_ transaction: Transaction) async {
        UserDefaults.standard.set(true, forKey: "bloom.isPro")
        onProUnlocked?(transaction.productID)
    }

    // MARK: - 错误

    enum StoreError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed: return "交易验证失败"
            }
        }
    }
}
