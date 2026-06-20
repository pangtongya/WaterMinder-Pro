// PaywallView.swift
// 付费墙 —— 在用户感受到植物养成价值后展示
//
// 设计原则（来自 chickenfocus 推文）：
//   - paywall shown after users understand the value
//   - includes a lifetime option
// Pro 解锁：全部品种 + 高级统计 + iCloud 同步 + 无限花园

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedProduct: Product?
    @State private var showRestoreSuccess = false
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部
                    header

                    // 沙盒测试模式提示
                    #if DEBUG
                    if storeManager.products.isEmpty {
                        Text("⚠️ 沙盒测试模式".localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.vertical, 4)
                    }
                    #endif

                    // Pro 权益列表
                    benefitsList

                    // 商品选择
                    if storeManager.products.isEmpty {
                        if storeManager.isLoading {
                            ProgressView("正在加载...")
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                #if DEBUG
                                Text("🧪 开发模式".localized)
                                    .font(.title2)
                                Text("请在 App Store Connect 配置商品后测试".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("或在 Scheme 中添加 BLOOM_DEV_MODE=1 环境变量".localized)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                #else
                                Text("暂未配置内购商品".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                #endif
                            }
                            .padding(.vertical, 40)
                        }
                    } else {
                        productsList
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Bloom Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭".localized) { dismiss() }
                }
            }
            .alert("恢复成功".localized, isPresented: $showRestoreSuccess) {
                Button("太好了".localized) { dismiss() }
            } message: {
                Text(L.proThankYou)
            }
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(spacing: 12) {
            Text("🌸")
                .font(.system(size: 48))

            Text("解锁更多生命".localized)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("养出更美的花园，收集全部品种".localized)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 10)
    }

    // MARK: - 权益列表

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow(icon: "📊", title: "Advanced Statistics".localized, desc: "Complete data analysis and visualization reports")
            benefitRow(icon: "🎨", title: "Custom Themes".localized, desc: "Unlock all Pro themes and appearances")
            benefitRow(icon: "🌱", title: "Unlimited Plants".localized, desc: "Unlock all 7 plant species for your dream garden")
            benefitRow(icon: "☁️", title: "Multi-device Sync".localized, desc: "CloudKit data sync and backup")
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func benefitRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(desc).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.bloomSuccess)
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 商品列表

    private var productsList: some View {
        VStack(spacing: 12) {
            ForEach(storeManager.products, id: \.id) { product in
                productCard(product)
            }

            if let error = storeManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // 恢复购买
            Button("恢复购买".localized) {
                Task {
                    await storeManager.restore()
                    if storeManager.isPro {
                        showRestoreSuccess = true
                    }
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .padding(.top, 8)

            // 法律小字
            Text("订阅自动续期，可随时在系统设置中取消".localized)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            // 服务条款 & 隐私政策
            HStack(spacing: 4) {
                Button("Terms of Service".localized) {
                    openURL(AppConstants.URLs.termsOfService)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Button("Privacy Policy".localized) {
                    openURL(AppConstants.URLs.privacyPolicy)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isLifetime = product.id == BloomProduct.lifetimeID
        let isYearly = product.id == BloomProduct.yearlyID

        // 计算终身相对于年订阅的节省（如果有年订阅商品）
        let yearlyProduct = storeManager.products.first { $0.id == BloomProduct.yearlyID }
        let savingsPercent: Int? = {
            guard let yearly = yearlyProduct, isLifetime else { return nil }
            let yearlyCostPer3Years = (yearly.price as NSDecimalNumber).doubleValue * 3
            let lifetimePrice = (product.price as NSDecimalNumber).doubleValue
            let savings = (yearlyCostPer3Years - lifetimePrice) / yearlyCostPer3Years * 100
            return Int(max(0, savings))
        }()

        return Button {
            selectedProduct = product
            Task { await purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isLifetime ? "Lifetime Purchase" : "Pro Yearly")
                            .font(.system(size: 16, weight: .bold))
                        if isLifetime {
                            Text("BEST VALUE".localized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.bloomGold)
                                .clipShape(Capsule())
                        } else if isYearly {
                            Text("POPULAR".localized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.bloomPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    if let savings = savingsPercent, savings > 0 {
                        Text(String(format: "Save %d%% vs subscription".localized, savings))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.bloomSuccess)
                    } else {
                        Text(isLifetime ? "One-time purchase, permanent unlock".localized : "Unlimited care all year")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .padding(16)
            .background(isSelected ? Color.bloomPrimary.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.bloomPrimary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(storeManager.isPurchasing)
        .overlay {
            if storeManager.isPurchasing && isSelected {
                ProgressView()
            }
        }
    }

    private func purchase(_ product: Product) async {
        await storeManager.purchase(product)
        // 购买成功后关闭
        if storeManager.isPro {
            Haptics.success()
            dismiss()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager.shared)
}
