// PaywallView.swift
// 付费墙 —— 经过转化率优化的设计
//
// 设计要点：
// 1. 7秒首屏决定：植物预览 + 核心价值主张
// 2. 社会证明：用户评价、使用数据
// 3. 定价锚定：年订阅 vs 终身购买对比
// 4. 紧迫感：限时优惠
// 5. 低风险承诺：随时取消、恢复购买
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedProductID: String = BloomProduct.lifetimeID
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false
    @State private var showSuccess = false
    @State private var showRestoreSuccess = false
    @State private var isRestoring = false
    
    // 限时优惠状态
    @State private var showLimitedOffer = true
    @State private var countdownSeconds: Int = 600  // 10分钟倒计时
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部关闭按钮（延迟显示，先让用户看内容）
                topBar
                
                // 英雄区域：植物预览 + 价值主张
                heroSection
                    .padding(.bottom, 24)
                
                // 限时优惠横幅
                if showLimitedOffer {
                    limitedOfferBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Pro 功能亮点
                featuresSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // 用户评价
                reviewsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // 定价卡片
                pricingSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // 购买按钮
                purchaseButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 底部法律信息
                footerSection
                    .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.bloomPrimary.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .topTrailing
            )
        )
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // 默认选中年订阅（转化率更高的选项）
            if storeManager.products.contains(where: { $0.id == BloomProduct.yearlyID }) {
                selectedProductID = BloomProduct.yearlyID
            }
        }
        .onReceive(timer) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                showLimitedOffer = false
            }
        }
        .alert("购买失败".localized, isPresented: $showError) {
            Button("好的".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("恢复成功".localized, isPresented: $showRestoreSuccess) {
            Button("好的".localized) {
                dismiss()
            }
        } message: {
            Text("Pro 权益已解锁，感谢您的支持！".localized)
        }
        .overlay {
            if showSuccess {
                successOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
    }

    // MARK: - 顶部栏

    private var topBar: some View {
        HStack {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text("升级到 Pro".localized)
                    .font(.system(size: 22, weight: .bold))
                Text("解锁全部植物，打造你的梦幻花园".localized)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 英雄区域

    private var heroSection: some View {
        VStack(spacing: 16) {
            // 三株植物并排展示（Pro 专属）
            HStack(spacing: -20) {
                ForEach(0..<3, id: \.self) { index in
                    let plant = previewPlant(for: index)
                    PlantView(plant: plant, size: .medium)
                        .frame(width: 100, height: 140)
                        .opacity(index == 1 ? 1.0 : 0.7)
                        .scaleEffect(index == 1 ? 1.1 : 0.9)
                        .zIndex(index == 1 ? 1 : 0)
                }
            }
            
            // 核心价值主张
            VStack(spacing: 8) {
                Text("🌱 把喝水变成一场冒险")
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("每一杯水，都让你的花园更美丽")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }
    
    private func previewPlant(for index: Int) -> Plant {
        let species = ["sunflower", "rose", "cactus"]
        let stages: [GrowthStage] = [.growing, .mature, .harvestable]
        return Plant(
            name: ["小阳", "小玫", "小仙"][index],
            speciesID: species[index],
            stage: stages[index],
            health: 95
        )
    }

    // MARK: - 限时优惠横幅

    private var limitedOfferBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("限时优惠 - 立省 30%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text("优惠剩余: \(formattedCountdown)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            Image(systemName: "gift.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.bloomGold)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.12),
                    Color.bloomGold.opacity(0.08)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var formattedCountdown: String {
        let minutes = countdownSeconds / 60
        let seconds = countdownSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - 功能亮点

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro 专属权益")
                .font(.system(size: 18, weight: .bold))
            
            VStack(spacing: 12) {
                featureRow(
                    icon: "🌿",
                    title: "全部 7 种植物",
                    desc: "解锁所有品种，每种都有独特的生长动画",
                    highlight: true
                )
                featureRow(
                    icon: "🏡",
                    title: "无限花园空间",
                    desc: "免费用户最多 5 株，Pro 想养多少养多少",
                    highlight: true
                )
                featureRow(
                    icon: "📊",
                    title: "深度数据洞察",
                    desc: "喝水趋势、达标率分析、成长历程一目了然",
                    highlight: false
                )
                featureRow(
                    icon: "☁️",
                    title: "iCloud 多设备同步",
                    desc: "iPhone、iPad 数据实时同步",
                    highlight: false
                )
                featureRow(
                    icon: "🌙",
                    title: "全部主题皮肤",
                    desc: "多种精美主题，每天都是新感觉",
                    highlight: false
                )
                featureRow(
                    icon: "✨",
                    title: "更多即将推出",
                    desc: "未来新功能 Pro 用户优先体验",
                    highlight: false
                )
            }
        }
    }
    
    private func featureRow(icon: String, title: String, desc: String, highlight: Bool) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(highlight ? Color.bloomPrimary.opacity(0.1) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title.localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(highlight ? Color.bloomPrimary : .primary)
                Text(desc.localized)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if highlight {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.bloomSuccess)
                    .font(.system(size: 20))
            }
        }
        .padding(12)
        .background(highlight ? Color.bloomPrimary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 用户评价

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("用户怎么说")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.bloomGold)
                    }
                    Text("4.9")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                reviewCard(
                    name: "小明",
                    avatar: "😀",
                    text: "用了三个月，喝水习惯真的养成了！每天都期待看我的植物长大。",
                    rating: 5
                )
                reviewCard(
                    name: "花儿",
                    avatar: "🌸",
                    text: "植物太可爱了！为了不让它枯萎，我现在每天都喝够水。",
                    rating: 5
                )
            }
        }
    }
    
    private func reviewCard(name: String, avatar: String, text: String, rating: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(avatar)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.localized)
                        .font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 1) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.bloomGold)
                        }
                    }
                }
            }
            Text(text.localized)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 定价区域

    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text("选择你的计划")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 年订阅（主推）
            productCard(
                productID: BloomProduct.yearlyID,
                isSelected: selectedProductID == BloomProduct.yearlyID,
                isPopular: true
            )
            
            // 终身购买
            productCard(
                productID: BloomProduct.lifetimeID,
                isSelected: selectedProductID == BloomProduct.lifetimeID,
                isBestValue: true
            )
        }
    }
    
    private func productCard(productID: String, isSelected: Bool, isPopular: Bool = false, isBestValue: Bool = false) -> some View {
        guard let product = storeManager.products.first(where: { $0.id == productID }) else {
            return AnyView(EmptyView())
        }
        
        let isYearly = productID == BloomProduct.yearlyID
        let isLifetime = productID == BloomProduct.lifetimeID
        
        // 计算日均价格
        let priceDouble = (product.price as NSDecimalNumber).doubleValue
        let dailyPrice: String = {
            if isYearly {
                let daily = priceDouble / 365
                return String(format: "%.2f", daily)
            }
            return ""
        }()
        
        // 计算终身节省（和 3 年订阅对比）
        let savingsPercent: Int = {
            guard isLifetime,
                  let yearly = storeManager.products.first(where: { $0.id == BloomProduct.yearlyID }) else {
                return 0
            }
            let yearlyCost = (yearly.price as NSDecimalNumber).doubleValue * 3
            let savings = (yearlyCost - priceDouble) / yearlyCost * 100
            return Int(max(0, savings))
        }()
        
        return AnyView(
            Button {
                selectedProductID = productID
                Haptics.light()
            } label: {
                HStack(spacing: 14) {
                    // 选中指示器
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.bloomPrimary : Color(.tertiarySystemFill), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(Color.bloomPrimary)
                                .frame(width: 14, height: 14)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(isYearly ? "年度会员" : "终身解锁")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            if isPopular {
                                Text("最受欢迎")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.bloomPrimary)
                                    .clipShape(Capsule())
                            }
                            if isBestValue {
                                Text("最划算")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.bloomGold)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if isYearly {
                            Text("每天约 \(dailyPrice) 元，养成喝水好习惯")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        if isLifetime && savingsPercent > 0 {
                            Text("比订阅 3 年节省 \(savingsPercent)%，一次购买永久使用")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.bloomSuccess)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if isYearly {
                            Text("/ 年")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        if isLifetime {
                            Text("永久")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(isSelected ? Color.bloomPrimary.opacity(0.08) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.bloomPrimary : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        )
    }

    // MARK: - 购买按钮

    private var purchaseButton: some View {
        Button {
            guard let product = storeManager.products.first(where: { $0.id == selectedProductID }) else {
                return
            }
            Task {
                await purchase(product)
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.bloomPrimary, Color.bloomDeep],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.bloomPrimary.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(isPurchasing || storeManager.isPurchasing || storeManager.products.isEmpty)
    }
    
    private var buttonTitle: String {
        guard let product = storeManager.products.first(where: { $0.id == selectedProductID }) else {
            return "加载中...".localized
        }
        let isYearly = selectedProductID == BloomProduct.yearlyID
        return isYearly ? "开始免费试用" : "立即解锁".localized
    }

    // MARK: - 底部信息

    private var footerSection: some View {
        VStack(spacing: 12) {
            // 恢复购买
            Button {
                Task {
                    isRestoring = true
                    await storeManager.restore()
                    isRestoring = false
                    
                    if storeManager.isPro {
                        showRestoreSuccess = true
                    } else {
                        errorMessage = "未找到已购买的记录".localized
                        showError = true
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("恢复购买".localized)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isRestoring)
            
            // 法律条款
            Text("订阅自动续期，可随时在系统设置中取消。终身版一次购买永久有效。".localized)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // 服务条款 & 隐私政策
            HStack(spacing: 8) {
                Button {
                    openURL(AppConstants.URLs.termsOfService)
                } label: {
                    Text("服务条款".localized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                
                Button {
                    openURL(AppConstants.URLs.privacyPolicy)
                } label: {
                    Text("隐私政策".localized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 成功动画

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 成功图标
                ZStack {
                    Circle()
                        .fill(Color.bloomSuccess.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.bloomSuccess)
                }
                
                VStack(spacing: 8) {
                    Text("🎉 恭喜升级！")
                        .font(.system(size: 22, weight: .bold))
                    Text("Pro 权益已全部解锁")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                
                Text("开始养更多的植物吧！")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                Button {
                    dismiss()
                } label: {
                    Text("开始使用")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 40)
        }
    }

    // MARK: - 购买逻辑

    private func purchase(_ product: Product) async {
        isPurchasing = true
        await storeManager.purchase(product)
        isPurchasing = false
        
        if storeManager.isPro {
            Haptics.success()
            withAnimation {
                showSuccess = true
            }
        } else if let error = storeManager.lastError {
            errorMessage = error
            showError = true
        }
    }

    // MARK: - 工具
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
