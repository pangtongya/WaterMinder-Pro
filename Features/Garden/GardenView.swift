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
    @State private var showHarvestCelebration = false
    @State private var showPauseConfirm = false
    @State private var showResumeAlert = false
    @State private var isSharing = false
    @State private var shareImage: UIImage?
    @State private var showGardenLimitAlert = false
    @State private var showPaywall = false
    
    var body: some View {
        Group {
            mainContent
        }
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
            Text(L.proUnlocksGardenSlots)
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
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                plantHeroSection
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                
                healthCardSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                quickRecordSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                todayRecordsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Spacer(minLength: 100)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.bloomBackground)
        .navigationTitle(L.myGarden)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButton
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
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
                    withAnimation {
                        showGoalCelebration = false
                    }
                }
            }
        }
        .overlay {
            celebrationOverlay
        }
        .animation(.easeInOut(duration: 0.25), value: celebrateStage)
        .animation(.easeInOut(duration: 0.25), value: showWilt)
    }
    
    // MARK: - 分享按钮
    
    private var shareButton: some View {
        Button {
            sharePlantStatus()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.bloomSurface)
                    .frame(width: 32, height: 32)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
            .frame(minWidth: 44, minHeight: 44)
            .overlay(
                Circle()
                    .stroke(Color.bloomBorder, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .disabled(isSharing)
    }
    
    // MARK: - 庆祝覆盖层
    
    private var celebrationOverlay: some View {
        ZStack {
            if let stage = celebrateStage {
                GenericCelebrationOverlay(
                    title: L.congratulations,
                    message: L.reachedStageMsg,
                    iconName: stage.emoji,
                    onDismiss: {
                        withAnimation { celebrateStage = nil }
                        plantEngine.consumeStageUpCelebration()
                    }
                )
                .transition(.opacity)
            }
            if showWilt {
                GenericCelebrationOverlay(
                    title: L.plantThirsty,
                    message: L.giveItWater,
                    iconName: "💧",
                    onDismiss: {
                        withAnimation { showWilt = false }
                        plantEngine.consumeWilt()
                    }
                )
                .transition(.opacity)
            }
            if showGoalCelebration {
                GenericCelebrationOverlay(
                    title: L.goalAchieved,
                    message: L.keepUpGoodHabits,
                    iconName: "🎉",
                    onDismiss: {
                        withAnimation { showGoalCelebration = false }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            if showHarvestCelebration {
                GenericCelebrationOverlay(
                    title: L.harvestSuccess,
                    message: L.plantAddedToCollection,
                    iconName: "🌸",
                    onDismiss: {
                        withAnimation { showHarvestCelebration = false }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - 1. 植物英雄区
    
    private var plantHeroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                ProgressRing(
                    progress: plantEngine.plant.health / 100,
                    lineWidth: 8,
                    size: 180,
                    backgroundColor: Color.bloomFill,
                    foregroundColor: Color.bloomPrimary,
                    accessibilityLabel: NSLocalizedString("健康度", comment: "Health progress")
                )
                
                ZStack {
                    Circle()
                        .fill(Color.bloomSurfaceSecondary)
                        .frame(width: 148, height: 148)
                    
                    AnimatedPlantView(plant: plantEngine.plant)
                        .frame(width: 140, height: 180)
                        .scaleEffect(plantPressing ? 0.94 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: plantPressing)
                        .opacity(plantEngine.plant.isPaused ? 0.5 : 1.0)
                        .clipShape(Circle())
                    
                    if splashTrigger > 0 {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "droplet.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.bloomWater)
                                .opacity(0.7)
                                .offset(y: -40 - CGFloat(splashTrigger % 10 * 8))
                                .opacity(splashTrigger > 0 ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.08), value: splashTrigger)
                                .accessibilityHidden(true)
                        }
                    }
                    
                    if plantEngine.plant.isPaused {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 148, height: 148)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                            Text(L.carePaused)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 148, height: 148)
                .contentShape(Circle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in plantPressing = true }
                        .onEnded { _ in plantPressing = false }
                )
                .onTapGesture {
                    waterPlant(.medium)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(Int(plantEngine.plant.health))%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.bloomPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.bloomSurface)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                    }
                }
                .frame(width: 180, height: 180)
            }
            .frame(width: 180, height: 180)
            
            VStack(spacing: 2) {
                Text(plantEngine.plant.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.bloomTextPrimary)
                    .tracking(-0.3)
                
                Text("\(plantEngine.plant.species.localizedName) · \(stageName)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 2. 健康度卡片
    
    private var healthCardSection: some View {
        SurfaceCard(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(L.health)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(plantEngine.plant.health))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)
                }
                .padding(.bottom, 6)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.bloomFill)
                        
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.bloomPrimary)
                            .frame(width: geometry.size.width * (plantEngine.plant.health / 100))
                            .animation(.easeInOut(duration: 0.4), value: plantEngine.plant.health)
                    }
                }
                .frame(height: 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L.health)
                .accessibilityValue("\(Int(plantEngine.plant.health))%")
                
                Text(healthStatusText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L.growthProgress)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.bloomTextTertiary)
                        
                        Spacer()
                        
                        Text("\(Int(growthProgress))%")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.bloomFill)
                            
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.bloomWater)
                                .frame(width: geometry.size.width * (growthProgress / 100))
                                .animation(.easeInOut(duration: 0.4), value: growthProgress)
                        }
                    }
                    .frame(height: 6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L.growthProgress)
                    .accessibilityValue("\(Int(growthProgress))%")
                }
                .padding(.top, 12)
                
                Divider()
                    .background(Color.bloomDivider)
                    .padding(.top, 12)
                
                HStack {
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 16))
                            .accessibilityHidden(true)
                        
                        Text(String(format: L.streakDaysFormat, waterStore.currentStreak))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.bloomTextPrimary)
                    }
                    
                    Spacer()
                    
                    if waterStore.currentStreak >= 7 {
                        Badge(L.milestoneBadge, style: .brand)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
    
    // MARK: - 3. 快速记录卡片
    
    private var quickRecordSection: some View {
        SurfaceCard(padding: 16) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(CupType.allCases, id: \.self) { cup in
                        Button {
                            waterPlant(cup)
                        } label: {
                            VStack(spacing: 4) {
                                IconCircle(
                                    icon: cup.icon,
                                    backgroundColor: Color.bloomWaterMuted,
                                    iconColor: Color.bloomWater,
                                    size: .medium
                                )
                                
                                Text("\(cup.defaultAmount)ml")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "droplets")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.bloomWater)
                            .accessibilityHidden(true)
                        
                        if waterStore.remaining > 0 {
                            Text(String(format: L.remainingMlFormat, waterStore.remaining))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.bloomWater)
                        } else {
                            Text(L.goalReachedToday)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.bloomSuccess)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.bloomPrimarySubtle)
                    .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, 16)
            }
        }
    }
    
    // MARK: - 4. 今日记录
    
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.todayLog)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.bloomTextPrimary)
                    .tracking(-0.3)
                
                Spacer()
                
                Text("\(waterStore.todayTotal) ml")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.bloomPrimary)
            }
            .padding(.bottom, 12)
            
            if waterStore.todayRecords.isEmpty {
                emptyRecordsView
            } else {
                SurfaceCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(waterStore.todayRecords.enumerated()), id: \.element.id) { index, record in
                            HStack(spacing: 12) {
                                IconCircle(
                                    icon: record.cupType.icon,
                                    backgroundColor: Color.bloomWaterMuted,
                                    iconColor: Color.bloomWater,
                                    size: .small
                                )
                                .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(record.amount)ml")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.bloomTextPrimary)
                                    
                                    Text(record.cupType.localizedName)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.bloomTextTertiary)
                                }
                                
                                Spacer()
                                
                                Text(record.timeString)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .accessibilityElement(children: .combine)
                            
                            if index < waterStore.todayRecords.count - 1 {
                                Divider()
                                    .background(Color.bloomDivider)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyRecordsView: some View {
        SurfaceCard(padding: 0) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.bloomWaterMuted)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "drop")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.bloomWater)
                        .accessibilityHidden(true)
                }
                
                VStack(spacing: 4) {
                    Text(L.noRecordsYet)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextSecondary)
                    
                    Text(L.tapToRecordWater)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - Helper Properties
    
    private var healthStatusText: String {
        if plantEngine.plant.health >= 90 {
            return L.healthStatusGreat
        } else if plantEngine.plant.health >= 70 {
            return L.healthStatusGood
        } else if plantEngine.plant.health >= 40 {
            return L.healthStatusThirsty
        } else {
            return L.healthStatusNeedsWater
        }
    }
    
    private var stageName: String {
        switch plantEngine.plant.stage {
        case .seed: return L.seedStageName
        case .sprout: return L.sproutStageName
        case .seedling: return L.seedlingStageName
        case .mature: return L.growingStageName
        case .blooming: return L.bloomingStageName
        case .harvestable: return L.harvestableStageName
        }
    }
    
    private var growthProgress: Double {
        let daysSincePlanting = plantEngine.plant.ageInDays
        let totalGrowthDays = plantEngine.plant.species.growthDays.totalDays
        return min(Double(daysSincePlanting) / Double(max(totalGrowthDays, 1)) * 100, 100)
    }
    
    // MARK: - Actions
    
    private func waterPlant(_ cupType: CupType) {
        splashTrigger += 1
        Haptics.light()
        Task {
            await plantEngine.waterPlant(cup: cupType, waterStore: waterStore, healthManager: healthManager)
        }
    }
    
    private func performHarvest() {
        Task {
            let result = plantEngine.harvest()
            if result != nil {
                showHarvestCelebration = true
                Haptics.success()
            }
        }
    }
    
    private func sharePlantStatus() {
        isSharing = true
        let plant = plantEngine.plant
        Task { @MainActor in
            shareImage = ShareCardRenderer.renderHarvestCard(plant: plant)
            isSharing = false
        }
    }
}
