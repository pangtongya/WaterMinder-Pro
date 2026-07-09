// PaywallView.swift
// 付费墙 —— Apple 风格设计 + 高转化率优化
//
// 设计要点：
// 1. Apple 风格：SurfaceCard、IconCircle、Badge、SectionHeader
// 2. 转化率优化：限时优惠、社会证明、定价锚定
// 3. 视觉层级：圆角 16px、border-first 阴影、清晰分区
// 4. 动画效果：页面淡入、功能滑入、购买成功庆祝
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
    
    // 动画状态
    @State private var fadeInOpacity = 0.0
    @State private var featuresOffset = 50.0
    @State private var reviewsOpacity = 0.0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部关闭按钮
                topBar
                
                // 英雄区域：植物预览 + 价值主张
                heroSection
                    .padding(.bottom, 20)
                
                // 限时优惠横幅
                if showLimitedOffer {
                    limitedOfferBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Pro 功能亮点（Apple 风格 SurfaceCard）
                featuresSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .offset(y: featuresOffset)
                    .opacity(fadeInOpacity)
                
                // 用户评价（Apple 风格 SurfaceCard）
                reviewsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .opacity(reviewsOpacity)
                
                // 定价卡片（Apple 风格）
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
        .background(Color.bloomBackground)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // 页面淡入动画
            withAnimation(.easeOut(duration: 0.5)) {
                fadeInOpacity = 1.0
            }
            
            // 功能列表滑入动画（延迟 0.2s）
            Task {
                try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    featuresOffset = 0
                }
            }
            
            // 用户评价淡入动画（延迟 0.4s）
            Task {
                try? await Task.sleep(nanoseconds: UInt64(0.4 * 1_000_000_000))
                withAnimation(.easeOut(duration: 0.5)) {
                    reviewsOpacity = 1.0
                }
            }
            
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
        .alert(L.purchaseFailed, isPresented: $showError) {
            Button(L.ok, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(L.restoreSuccessful, isPresented: $showRestoreSuccess) {
            Button(L.ok) {
                dismiss()
            }
        } message: {
            Text(L.proUnlockedThankYou)
        }
        .overlay {
            if showSuccess {
                successOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
    }

    // MARK: - 顶部栏（Apple 风格）

    private var topBar: some View {
        HStack {
            // 标题（Apple Large Title 风格）
            VStack(alignment: .leading, spacing: 2) {
                Text(L.upgradeToPro)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .tracking(-0.5)
                    .foregroundStyle(Color.bloomTextPrimary)
                Text(L.unlockAllPlantsDreamGarden)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.bloomTextTertiary)
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
                PlantView(plant: previewPlant(for: 0))
                    .frame(width: 100, height: 140)
                    .opacity(0.7)
                    .scaleEffect(0.9)
                    .zIndex(0)
                
                PlantView(plant: previewPlant(for: 1))
                    .frame(width: 100, height: 140)
                    .opacity(1.0)
                    .scaleEffect(1.1)
                    .zIndex(1)
                
                PlantView(plant: previewPlant(for: 2))
                    .frame(width: 100, height: 140)
                    .opacity(0.7)
                    .scaleEffect(0.9)
                    .zIndex(0)
            }
            
            // 核心价值主张
            VStack(spacing: 8) {
                Text(L.makeDrinkingAnAdventure)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.bloomTextPrimary)
                Text(L.everySipMakesGardenBeautiful)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }
    
    private func previewPlant(for index: Int) -> Plant {
        let species = ["sunflower", "rose", "cactus"]
        let stages: [GrowthStage] = [.seedling, .mature, .harvestable]
        return Plant(
            name: [L.previewPlantName1, L.previewPlantName2, L.previewPlantName3][index],
            speciesID: species[index],
            stage: stages[index],
            health: 95
        )
    }

    // MARK: - 限时优惠横幅（Apple 风格）

    private var limitedOfferBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.bloomWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(L.limitedOfferSave30)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.bloomTextPrimary)
                Text(String(format: L.offerRemainingFormat, formattedCountdown))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.bloomWarning)
            }
            
            Spacer()
            
            Image(systemName: "gift.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.bloomGold)
        }
        .padding(14)
        .background(Color.bloomWarning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bloomBorder, lineWidth: 0.5)
        )
    }
    
    private var formattedCountdown: String {
        let minutes = countdownSeconds / 60
        let seconds = countdownSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - 功能亮点（Apple 风格 SurfaceCard）

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            SectionHeader(L.proExclusiveFeatures)
            
            SurfaceCard(padding: 16) {
                VStack(spacing: 12) {
                    featureRow(
                        icon: "leaf.fill",
                        title: L.all7PlantsTitle,
                        desc: L.all7PlantsDesc,
                        highlight: true
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    featureRow(
                        icon: "house.fill",
                        title: L.unlimitedGardenSpaceTitle,
                        desc: L.unlimitedGardenSpaceDesc,
                        highlight: true
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    featureRow(
                        icon: "chart.bar.fill",
                        title: L.deepDataInsights,
                        desc: L.deepDataInsightsDesc2,
                        highlight: false
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    featureRow(
                        icon: "icloud.fill",
                        title: L.iCloudMultiDeviceTitle,
                        desc: L.iCloudMultiDeviceDesc,
                        highlight: false
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    featureRow(
                        icon: "moon.fill",
                        title: L.allThemesTitle,
                        desc: L.allThemesDesc,
                        highlight: false
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    featureRow(
                        icon: "sparkles",
                        title: L.moreComingTitle,
                        desc: L.moreComingDesc,
                        highlight: false
                    )
                }
            }
        }
    }
    
    private func featureRow(icon: String, title: String, desc: String, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            // Apple 风格 IconCircle
            IconCircle(
                icon: icon,
                backgroundColor: highlight ? Color.bloomPrimaryMuted : Color.bloomFill,
                iconColor: highlight ? Color.bloomPrimary : Color.bloomTextSecondary,
                size: .medium
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(highlight ? Color.bloomPrimary : Color.bloomTextPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if highlight {
                Badge(L.coreBadge, style: .brand)
            }
        }
    }

    // MARK: - 用户评价（Apple 风格 SurfaceCard）

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            SectionHeader(L.whatUsersSay)
            
            SurfaceCard(padding: 16) {
                VStack(spacing: 12) {
                    // 总评分
                    HStack {
                        Text(L.overallRating)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.bloomGold)
                            }
                            Text("4.9")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.bloomTextSecondary)
                        }
                    }
                    
                    Divider()
                    
                    // 用户评价卡片
                    VStack(spacing: 12) {
                        reviewCard(
                            name: L.reviewerNameXiaoming,
                            avatar: "leaf.fill",
                            avatarColor: Color.bloomPrimary,
                            text: L.reviewerTextXiaoming,
                            rating: 5
                        )
                        
                        Divider()
                        
                        reviewCard(
                            name: L.reviewerNameHuaer,
                            avatar: "flower.fill",
                            avatarColor: Color.bloomGold,
                            text: L.reviewerTextHuaer,
                            rating: 5
                        )
                    }
                }
            }
        }
    }
    
    private func reviewCard(name: String, avatar: String, avatarColor: Color, text: String, rating: Int) -> some View {
        HStack(spacing: 12) {
            // Apple 风格 IconCircle
            IconCircle(
                icon: avatar,
                backgroundColor: avatarColor.opacity(0.15),
                iconColor: avatarColor,
                size: .medium
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    HStack(spacing: 1) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.bloomGold)
                        }
                    }
                }
                
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
    }

    // MARK: - 定价区域（Apple 风格优化）

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Section Header
            SectionHeader(L.chooseYourPlan)
            
            VStack(spacing: 12) {
                // 年订阅（主推）
                productCard(
                    productID: BloomProduct.yearlyID,
                    isSelected: selectedProductID == BloomProduct.yearlyID,
                    badge: Badge(L.mostPopular, style: .brand)
                )
                
                // 终身购买
                productCard(
                    productID: BloomProduct.lifetimeID,
                    isSelected: selectedProductID == BloomProduct.lifetimeID,
                    badge: Badge(L.bestValue, style: .gold)
                )
            }
        }
    }
    
    @ViewBuilder
    private func productCard(productID: String, isSelected: Bool, badge: Badge? = nil) -> some View {
        if let product = storeManager.products.first(where: { $0.id == productID }) {
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

        Button {
                selectedProductID = productID
                Haptics.light()
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    // 标题行
                    HStack(spacing: 12) {
                        // 选中指示器（Apple 风格）
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color.bloomPrimary : Color.bloomBorder, lineWidth: 2)
                                .frame(width: 24, height: 24)

                            if isSelected {
                                Circle()
                                    .fill(Color.bloomPrimary)
                                    .frame(width: 14, height: 14)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(isYearly ? L.annualMember : L.lifetimeUnlock)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.bloomTextPrimary)

                                if let badge = badge {
                                    badge
                                }
                            }

                            // 价格说明
                            if isYearly {
                                Text(String(format: L.dailyPriceFormat, dailyPrice))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                            if isLifetime && savingsPercent > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 10))
                                    Text(String(format: L.saveVs3YearFormat, savingsPercent))
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color.bloomSuccess)
                            }
                        }

                        Spacer()

                        // 价格展示（Apple 风格 rounded 字体）
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(product.displayPrice)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.bloomTextPrimary)

                            if isYearly {
                                Text(L.perYear)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                            if isLifetime {
                                Text(L.forever)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                        }
                    }

                    // 选中状态额外展示：低风险承诺
                    if isSelected {
                        HStack(spacing: 8) {
                            IconCircle(
                                icon: "checkmark.shield.fill",
                                backgroundColor: Color.bloomSuccess.opacity(0.15),
                                iconColor: Color.bloomSuccess,
                                size: .small
                            )

                            Text(isYearly ? L.freeTrial7Days : L.onePurchaseForever)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.bloomSuccess)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(isSelected ? Color.bloomPrimaryMuted : Color.bloomSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.bloomPrimary : Color.bloomBorder, lineWidth: isSelected ? 2 : 0.5)
                )
                .shadow(
                    color: isSelected ? Color.bloomPrimary.opacity(0.15) : Color.clear,
                    radius: 8,
                    y: 4
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 购买按钮（Apple 风格）

    private var purchaseButton: some View {
        Button {
            guard let product = storeManager.products.first(where: { $0.id == selectedProductID }) else {
                return
            }
            Task {
                await purchase(product)
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    IconCircle(
                        icon: "sparkles",
                        backgroundColor: Color.white.opacity(0.2),
                        iconColor: .white,
                        size: .small
                    )
                    
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
        guard storeManager.products.first(where: { $0.id == selectedProductID }) != nil else {
            return L.loading
        }
        let isYearly = selectedProductID == BloomProduct.yearlyID
        return isYearly ? L.startFreeTrial : L.unlockNow
    }

    // MARK: - 底部信息（Apple 风格）

    private var footerSection: some View {
        VStack(spacing: 12) {
            // 恢复购买（Apple 风格）
            Button {
                Task {
                    isRestoring = true
                    await storeManager.restore()
                    isRestoring = false
                    
                    if storeManager.isPro {
                        showRestoreSuccess = true
                    } else {
                        errorMessage = L.noPurchasesFound
                        showError = true
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        IconCircle(
                            icon: "arrow.uturn.backward.circle.fill",
                            backgroundColor: Color.bloomFill,
                            iconColor: Color.bloomTextSecondary,
                            size: .small
                        )
                    }
                    
                    Text(L.restorePurchases)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
            }
            .disabled(isRestoring)
            
            // 法律条款（Apple 风格）
            Text(L.subscriptionFooterText)
                .font(.system(size: 10))
                .foregroundStyle(Color.bloomTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // 服务条款 & 隐私政策（Apple 风格分隔）
            HStack(spacing: 8) {
                Button {
                    openURL(AppConstants.URLs.termsOfService)
                } label: {
                    Text(L.termsOfService)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextTertiary)
                
                Button {
                    openURL(AppConstants.URLs.privacyPolicy)
                } label: {
                    Text(L.privacyPolicy)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
            }
        }
    }

    // MARK: - 成功动画（Apple 风格庆祝）

    private var successOverlay: some View {
        ZStack {
            // 背景模糊
            Color.bloomBackground.opacity(0.85)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            // 成功卡片（Apple 风格）
            VStack(spacing: 24) {
                // 成功图标（带动画）
                ZStack {
                    // 外圈光晕
                    Circle()
                        .fill(Color.bloomSuccess.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showSuccess ? 1.2 : 0.8)
                        .animation(.easeOut(duration: 0.6).repeatForever(autoreverses: true), value: showSuccess)
                    
                    // 内圈
                    Circle()
                        .fill(Color.bloomSuccess.opacity(0.25))
                        .frame(width: 100, height: 100)
                    
                    // 成功图标
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.bloomSuccess)
                        .scaleEffect(showSuccess ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
                }
                
                VStack(spacing: 12) {
                    Text(L.congratsUpgrade)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Text(L.allProFeaturesUnlocked)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.bloomTextSecondary)
                    
                    // 权益提示（Apple 风格 IconCircle）
                    HStack(spacing: 8) {
                        IconCircle(
                            icon: "sparkles",
                            backgroundColor: Color.bloomGoldMuted,
                            iconColor: Color.bloomGold,
                            size: .small
                        )
                        
                        Text(L.startGrowingMore)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                    }
                }
                
                // 开始使用按钮（Apple 风格）
                Button {
                    dismiss()
                } label: {
                    Text(L.startUsing)
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.bloomPrimary.opacity(0.25), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.bloomSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.bloomBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 40)
            .scaleEffect(showSuccess ? 1.0 : 0.8)
            .opacity(showSuccess ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccess)
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
