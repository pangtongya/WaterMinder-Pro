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
    private var retryTask: Task<Void, Never>?
    private var isListening = false

    /// 解锁 Pro 的回调（购买成功后通知 UserStore）
    var onProUnlocked: ((String) -> Void)?

    private init() {
        startTransactionListener()
        // 启动时异步验证现有购买权益（不阻塞 init）
        Task { await updatePurchasedProducts() }
    }

    deinit {
        transactionListener?.cancel()
        retryTask?.cancel()
    }

    // MARK: - 交易监听（带重试）

    private func startTransactionListener() {
        guard !isListening else { return }
        isListening = true
        transactionListener = listenForTransactionsWithRetry()
    }

    private func listenForTransactionsWithRetry() -> Task<Void, Error> {
        Task.detached { [weak self] in
            while !Task.isCancelled {
                for await result in Transaction.updates {
                    do {
                        let transaction = try self?.checkVerified(result)
                        if let t = transaction {
                            await self?.deliverTransaction(t)
                            await t.finish()
                        }
                    } catch {
                        // 单笔交易验证失败，继续监听下一条
                        #if DEBUG
                        print("[StoreManager] 交易验证失败: \(error)")
                        #endif
                    }
                }
                // AsyncSequence 结束（理论上不会发生），短暂等待后重连
                try? await Task.sleep(for: .seconds(5))
            }
        }
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
            products = []
            return
        }
        #endif

        do {
            let storeProducts = try await Product.products(for: BloomProduct.allIDs)
            products = storeProducts.sorted { $0.price < $1.price }
            if products.isEmpty {
                #if DEBUG
                print("⚠️ [StoreManager] App Store Connect 中未配置商品")
                #endif
            }
        } catch {
            lastError = "无法加载商品：\(error.localizedDescription)"
        }
    }

    // MARK: - Pro 状态查询

    /// 当前是否为 Pro（优先查交易状态，回退查 Keychain）
    var isProProvider: () -> Bool = { false }
    var isPro: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["BLOOM_FORCE_PRO"] == "1" { return true }
        #endif

        if KeychainManager.shared.loadBool(for: "bloom.isPro") { return true }
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

    // MARK: - 更新本地权益（在后台队列执行）

    private func updatePurchasedProducts() async {
        // 后台队列检查交易权益
        let hasPro = await Task.detached(priority: .userInitiated) { () -> Bool in
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   BloomProduct.allIDs.contains(transaction.productID) {
                    return true
                }
            }
            return false
        }.value

        KeychainManager.shared.saveBool(hasPro, for: "bloom.isPro")
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
        KeychainManager.shared.saveBool(true, for: "bloom.isPro")
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
