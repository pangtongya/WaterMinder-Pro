// GardenView.swift
// Apple 风格重构 —— 主界面
//
// 设计特点：
// - Apple Human Interface Guidelines 风格
// - 大标题导航
// - 毛玻璃底部栏
// - 圆角卡片
// - 进度环
// - 简洁的视觉层级

import SwiftUI

struct GardenView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementStore: AchievementStore
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var showHarvestSheet = false
    @State private var celebrateStage: GrowthStage?
    @State private var splashTrigger: Int = 0
    @State private var plantPressing = false
    @State private var showWilt = false
    @State private var showGoalCelebration = false
    @State private var showPauseConfirm = false
    @State private var showResumeAlert = false
    @State private var isSharing = false
    @State private var shareImage: UIImage?
    @State private var showGardenLimitAlert = false
    @State private var showPaywall = false
    
    private var plantFadeIn: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. 植物主视觉区 - 带进度环
                plantHeroSection
                    .padding(.horizontal, 16)
                
                // 2. 枯萎恢复横幅
                if plantEngine.plant.isWilted {
                    wiltBanner
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // 3. 状态信息卡片
                statusSection
                    .padding(.horizontal, 16)
                
                // 4. 成就徽章
                if plantEngine.plant.currentStreak >= 7 {
                    streakBadge
                        .padding(.horizontal, 16)
                }
                
                // 5. 快速记录区
                quickRecordSection
                    .padding(.horizontal, 16)
                
                // 6. 今日记录列表
                todayRecordsSection
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .background(Color.bloomBackground)
        .navigationTitle("我的花园")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    sharePlantStatus()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                .disabled(isSharing)
            }
        }
        .onChange(of: plantEngine.lastStageUpCelebration) { _, newStage in
            if let stage = newStage {
                celebrateStage = stage
                Haptics.success()
            }
        }
        .onChange(of: plantEngine.justWilted) { _, wilted in
            if wilted {
                showWilt = true
                Haptics.error()
            }
        }
        .onChange(of: waterStore.isGoalMetToday) { oldValue, newValue in
            if !oldValue && newValue {
                showGoalCelebration = true
                Haptics.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showGoalCelebration = false
                    }
                }
            }
        }
        .overlay {
            if let stage = celebrateStage {
                StageUpCelebration(stage: stage) {
                    withAnimation { celebrateStage = nil }
                    plantEngine.consumeStageUpCelebration()
                }
                .transition(.opacity)
            }
            if showWilt {
                WiltCelebration {
                    withAnimation { showWilt = false }
                    plantEngine.consumeWilt()
                }
                .transition(.opacity)
            }
            if showGoalCelebration {
                GoalCelebrationView {
                    withAnimation {
                        showGoalCelebration = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: celebrateStage)
        .animation(.easeInOut(duration: 0.25), value: showWilt)
        .alert(L.pauseCare, isPresented: $showPauseConfirm) {
            Button(L.cancel, role: .cancel) { }
            Button(L.pause, role: .destructive) {
                plantEngine.pauseCare()
                Haptics.light()
            }
        } message: {
            Text(L.pauseExplanation)
        }
        .alert(L.resumeCare, isPresented: $showResumeAlert) {
            Button(L.restore) {
                plantEngine.resumeCare()
                Haptics.success()
            }
            Button(L.cancel, role: .cancel) { }
        } message: {
            Text(L.confirmResumeCare)
        }
        .alert(L.gardenFull, isPresented: $showGardenLimitAlert) {
            Button(L.cancel, role: .cancel) { }
            Button(L.upgradeToPro) {
                NotificationCenter.default.post(name: AppConstants.NotificationNames.showPaywall, object: nil)
            }
        } message: {
            Text(L.proGardenLimit)
        }
        .sheet(isPresented: $showHarvestSheet) {
            HarvestView(plant: plantEngine.plant, onHarvest: performHarvest)
        }
        .sheet(isPresented: $isSharing) {
            if let shareImage {
                ActivityViewController(activityItems: [shareImage])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.NotificationNames.showPaywall)) { _ in
            showPaywall = true
        }
    }
    
    // MARK: - 植物主视觉区
    
    private var plantHeroSection: some View {
        SurfaceCard(padding: 20) {
            VStack(spacing: 20) {
                // 进度环 + 植物
                ZStack {
                    // 进度环
                    ProgressRing(
                        progress: plantEngine.plant.health / 100,
                        lineWidth: 12,
                        size: 200,
                        backgroundColor: Color.bloomFill,
                        foregroundColor: healthColor
                    ) {
                        // 中心植物
                        ZStack {
                            // 背景光晕
                            RadialGradient(
                                colors: [
                                    healthGlowColor.opacity(plantEngine.plant.isPaused ? 0.05 : 0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                            
                            // 水滴动画
                            WaterSplashOverlay(trigger: splashTrigger)
                            
                            // 植物
                            AnimatedPlantView(plant: plantEngine.plant)
                                .frame(width: 140, height: 180)
                                .scaleEffect(plantPressing ? 0.94 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: plantPressing)
                                .opacity(plantEngine.plant.isPaused ? 0.5 : 1.0)
                        }
                    }
                    
                    // 暂停状态覆盖
                    if plantEngine.plant.isPaused {
                        VStack(spacing: 6) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.bloomTextTertiary)
                            Text(L.carePaused)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.bloomTextSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bloomSurface.opacity(0.9))
                        )
                    }
                }
                .frame(width: 220, height: 220)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in plantPressing = true }
                        .onEnded { _ in plantPressing = false }
                )
                .onTapGesture {
                    waterPlant(.medium)
                }
                
                // 植物信息
                VStack(spacing: 8) {
                    HStack {
                        Text(plantEngine.plant.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        Badge(stageName, style: .brand)
                    }
                    
                    // 健康度
                    HealthStatusBar(health: plantEngine.plant.health)
                    
                    // 成长进度
                    GrowthProgressBar(progress: growthProgress)
                }
            }
        }
    }
    
    // MARK: - 状态信息
    
    private var statusSection: some View {
        SurfaceCard(padding: 16) {
            VStack(spacing: 16) {
                // 统计数据
                HStack(spacing: 0) {
                    statItem(
                        icon: "droplet.fill",
                        iconColor: .bloomWater,
                        value: "\(waterStore.todayAmount)",
                        unit: "ml",
                        label: "今日饮水"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    statItem(
                        icon: "flag.fill",
                        iconColor: .bloomWarning,
                        value: "\(Int(waterStore.todayProgress * 100))",
                        unit: "%",
                        label: "目标进度"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    statItem(
                        icon: "flame.fill",
                        iconColor: .orange,
                        value: "\(plantEngine.plant.currentStreak)",
                        unit: "天",
                        label: "连续达标"
                    )
                }
                
                // 喝水进度
                VStack(spacing: 8) {
                    HStack {
                        Text("今日喝水")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                        
                        Spacer()
                        
                        if waterStore.remainingAmount > 0 {
                            ProgressCapsule(remaining: waterStore.remainingAmount)
                        } else {
                            Badge("已达标", style: .success)
                        }
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.bloomFill)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.bloomWater, Color.bloomPrimary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(waterStore.todayProgress, 1.0))
                                .animation(.easeInOut(duration: 0.4), value: waterStore.todayProgress)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }
    
    private func statItem(icon: String, iconColor: Color, value: String, unit: String, label: String) -> some View {
        VStack(spacing: 6) {
            IconCircle(icon: icon, backgroundColor: iconColor.opacity(0.15), iconColor: iconColor, size: .small)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomTextPrimary)
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 成就徽章
    
    private var streakBadge: some View {
        SurfaceCard(padding: 16) {
            HStack(spacing: 12) {
                StreakBadge(days: plantEngine.plant.currentStreak, showBadge: plantEngine.plant.currentStreak >= 30)
                
                Spacer()
                
                Button {
                    // 跳转到成就页面
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
            }
        }
    }
    
    // MARK: - 快速记录
    
    private var quickRecordSection: some View {
        QuickRecordBar()
    }
    
    // MARK: - 今日记录
    
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("今日记录", action: nil, actionTitle: nil)
            
            if waterStore.todayRecords.isEmpty {
                emptyRecordsView
            } else {
                SurfaceCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(waterStore.todayRecords.prefix(5)) { record in
                            WaterRecordRow(
                                amount: record.amount,
                                cupType: record.cupType.localizedName,
                                time: record.timeString,
                                icon: record.cupType.iconName
                            )
                            
                            if record.id != waterStore.todayRecords.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    private var emptyRecordsView: some View {
        SurfaceCard(padding: 24) {
            VStack(spacing: 12) {
                IconCircle(
                    icon: "drop",
                    backgroundColor: Color.bloomWaterMuted,
                    iconColor: Color.bloomWater,
                    size: .medium
                )
                
                Text("还没有喝水记录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.bloomTextSecondary)
                
                Text("点击上方按钮记录喝水")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 枯萎恢复横幅
    
    private var wiltBanner: some View {
        SurfaceCard(padding: 16) {
            HStack(spacing: 12) {
                Image(systemName: "drop.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("植物口渴了！")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Text("点击植物喝水，让它恢复健康")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var healthColor: Color {
        if plantEngine.plant.health > 70 {
            return .bloomSuccess
        } else if plantEngine.plant.health > 40 {
            return .bloomWarning
        } else {
            return .bloomError
        }
    }
    
    private var healthGlowColor: Color {
        if plantEngine.plant.health > 70 {
            return .bloomSuccess
        } else if plantEngine.plant.health > 40 {
            return .bloomWarning
        } else {
            return .bloomError
        }
    }
    
    private var stageName: String {
        switch plantEngine.plant.stage {
        case .seed: return "种子"
        case .sprout: return "发芽"
        case .seedling: return "幼苗"
        case .growing: return "成株"
        case .mature: return "成熟"
        case .budding: return "含苞"
        case .harvestable: return "可收获"
        }
    }
    
    private var growthProgress: Double {
        let daysSincePlanting = plantEngine.plant.daysSincePlanting
        let totalGrowthDays = plantEngine.plant.species?.totalGrowthDays ?? 30
        return min(Double(daysSincePlanting) / Double(totalGrowthDays) * 100, 100)
    }
    
    // MARK: - Actions
    
    private func waterPlant(_ cupType: CupType) {
        splashTrigger += 1
        Task {
            await plantEngine.water(amount: cupType.amount, cupType: cupType, waterStore: waterStore, healthManager: healthManager)
        }
    }
    
    private func performHarvest() {
        Task {
            await plantEngine.harvest(waterStore: waterStore, healthManager: healthManager)
        }
    }
    
    private func sharePlantStatus() {
        isSharing = true
    }
}
