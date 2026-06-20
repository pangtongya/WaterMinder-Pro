// GardenView.swift
// ⭐ 主界面 —— 植物花园，用户的核心情感场域
//
// 结构：
//   1. 顶部：植物绘制区（AnimatedPlantView）—— 视觉中心，承载全部情感
//   2. 中部：植物状态卡（PlantStatusCard）—— 名字、健康度、状态文案
//   3. 底部：快速记录条（QuickRecordBar）—— 喝水按钮
//
// 每次喝水 → 植物立即恢复生机，形成"浇水养花"的正反馈闭环。

import SwiftUI

struct GardenView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var achievementStore: AchievementStore

    @State private var showHarvestSheet = false
    @State private var celebrateStage: GrowthStage?
    @State private var splashTrigger: Int = 0   // 水滴动画触发器


    @State private var showPauseConfirm = false
    @State private var showResumeAlert = false
    @State private var isSharing = false
    @State private var shareImage: UIImage?
    @State private var showGardenLimitAlert = false
    @State private var showPaywall = false
    @EnvironmentObject var storeManager: StoreManager
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 植物绘制区
                plantHero

                // 2. 状态卡
                PlantStatusCard()
                    .padding(.horizontal, 20)

                // 3. 收获按钮（成熟时显示）
                if plantEngine.plant.canHarvest {
                    harvestButton
                        .padding(.horizontal, 20)
                }

                // 4. 快速记录
                QuickRecordBar()
                    .padding(.horizontal, 20)

                // 5. 今日记录
                todayRecords
                    .padding(.horizontal, 20)

                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.myGarden)
        .navigationBarTitleDisplayMode(.large)
        // 阶段升级庆祝：监听 engine 发布的庆祝事件
        .onChange(of: plantEngine.lastStageUpCelebration) { _, newStage in
            if let stage = newStage {
                celebrateStage = stage
                Haptics.success()
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
        }
        .animation(.easeInOut(duration: 0.25), value: celebrateStage)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    sharePlantStatus()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isSharing)
            }
        }
        .alert(L.pauseCare, isPresented: $showPauseConfirm) {
            Button(NSLocalizedString("取消", comment: "Cancel"), role: .cancel) { }
            Button(NSLocalizedString("暂停", comment: "Pause"), role: .destructive) {
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
            Button(NSLocalizedString("取消", comment: "Cancel"), role: .cancel) { }
        } message: {
            Text(L.confirmResumeCare)
        }
        .alert(L.gardenFull, isPresented: $showGardenLimitAlert) {
            Button(NSLocalizedString("取消", comment: "Cancel"), role: .cancel) { }
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

    private var plantHero: some View {
        ZStack {
            // 背景光晕（健康时鲜亮）
            RadialGradient(
                colors: [
                    healthGlowColor.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 160
            )

            // 水滴飞溅动画层
            WaterSplashOverlay(trigger: splashTrigger)

            AnimatedPlantView(plant: plantEngine.plant)
                .frame(width: 240, height: 320)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .contentShape(Rectangle())  // 让整个区域可点击
        .onTapGesture {
            waterPlant(.medium)
        }
    }


    // MARK: - 暂停养护横幅

    private var pauseBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.carePaused)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.orange)
                Text(String(format: NSLocalizedString("剩余 %d 天", comment: ""), plantEngine.plant.remainingPauseDays))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(L.resumeCare) {
                showResumeAlert = true
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.bloomPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.bloomPrimary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    private var healthGlowColor: Color {
        Color.healthColor(plantEngine.plant.health)
    }

    // MARK: - 收获按钮

    private var harvestButton: some View {
        Button {
            showHarvestSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text(String(format: NSLocalizedString("收获 %@", comment: "Harvest [plant name]"), plantEngine.plant.name))
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.bloomGold, Color.bloomPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }


    // MARK: - 分享

    private func sharePlantStatus() {
        isSharing = true
        Task {
            let image = await SharingManager.shared.generatePlantShareCard(
                plant: plantEngine.plant,
                waterStore: waterStore,
                achievementStore: achievementStore
            )
            await MainActor.run {
                shareImage = image
                isSharing = false
            }
        }
    }

    /// 实际执行收获逻辑（由 HarvestView 的 onHarvest 调用）
    private func performHarvest() {
        if !gardenStore.harvestPlant(plantEngine: plantEngine, isPro: userStore.isPro) {
            let check = gardenStore.canHarvest(isPro: userStore.isPro)
            if !check.allowed {
                showGardenLimitAlert = true
            }
            return
        }
        Haptics.success()
    }

    // MARK: - 点击植物浇水

    /// 点击植物直接浇水（用中杯默认量），并触发水滴动画
    private func waterPlant(_ cup: CupType) {
        Task {
            await plantEngine.waterPlant(cup: cup, waterStore: waterStore, healthManager: healthManager)
            // 水滴动画 + 触觉（UI 相关，仍在 View 层）
            splashTrigger += 1
            Haptics.waterDrop()
        }
    }

    // MARK: - 今日记录

    private var todayRecords: some View {
        TodayRecordsCard()
    }

}
// MARK: - 今日记录卡片

struct TodayRecordsCard: View {
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var healthManager: HealthManager
    @State private var recordToDelete: WaterRecord?
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.todayLog)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if !waterStore.todayRecords.isEmpty {
                    Text("\(waterStore.todayTotal) ml")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.bloomWater)
                }
            }

            if waterStore.todayRecords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "drop")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.bloomWater.opacity(0.4))
                    Text(String(format: NSLocalizedString("%@ 还没喝到水", comment: ""), plantEngine.plant.name))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(waterStore.todayRecords.prefix(5).enumerated()), id: \.element.id) { idx, record in
                        recordRow(record)
                        if idx < min(waterStore.todayRecords.count, 5) - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .alert(NSLocalizedString("删除这条记录？", comment: "Delete this record?"), isPresented: $showDeleteConfirm) {
            Button(NSLocalizedString("取消", comment: "Cancel"), role: .cancel) { }
            Button(NSLocalizedString("删除", comment: "Delete"), role: .destructive) {
                if let record = recordToDelete {
                    Task {
                        await plantEngine.deleteRecord(record, waterStore: waterStore, healthManager: healthManager)
                    }
                    Haptics.light()
                }
            }
        } message: {
            Text(NSLocalizedString("删除后将同步更新植物状态", comment: "Will update plant state after deletion"))
        }
    }

    private func recordRow(_ record: WaterRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bloomWater.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: record.cupType.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomWater)
            }
            Text(record.timeString)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(record.formattedAmount)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.bloomWater)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                recordToDelete = record
                showDeleteConfirm = true
            } label: {
                Label(NSLocalizedString("删除", comment: "Delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - 阶段升级庆祝

struct StageUpCelebration: View {
    let stage: GrowthStage
    let onDismiss: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 18) {
                // emoji + 光环
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.bloomGold.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(appear ? 1.0 : 0.4)

                    Text(stage.emoji)
                        .font(.system(size: 76))
                        .scaleEffect(appear ? 1.0 : 0.3)
                }

                Text(L.itGrew)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)

                Text(String(format: NSLocalizedString("进入了「%@」阶段", comment: "Reached the [stage] stage"), stage.name))
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(appear ? 1 : 0)

                Button {
                    onDismiss()
                } label: {
                    Text(L.keepNurturing)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                appear = true
            }
        }
    }
}

// MARK: - 水滴飞溅动画

/// 点击浇水时，几颗水滴从顶部下落并淡出
struct WaterSplashOverlay: View {
    let trigger: Int

    @State private var drops: [WaterDrop] = []
    @State private var animating = false

    var body: some View {
        ZStack {
            ForEach(drops) { drop in
                Circle()
                    .fill(Color.bloomWater.opacity(drop.opacity))
                    .frame(width: drop.size, height: drop.size)
                    .offset(x: drop.xOffset, y: drop.yOffset)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            spawnDrops()
        }
    }

    private func spawnDrops() {
        // 生成 6 颗随机水滴
        let newDrops = (0..<6).map { i -> WaterDrop in
            WaterDrop(
                id: UUID(),
                size: Double.random(in: 6...12),
                xOffset: Double.random(in: -40...40),
                yOffset: -80,
                opacity: 0.9
            )
        }
        drops = newDrops

        // 下落动画
        withAnimation(.easeIn(duration: 0.6)) {
            for i in drops.indices {
                drops[i].yOffset = 60
                drops[i].opacity = 0
            }
        }

        // 清理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            drops = []
        }
    }
}


private struct WaterDrop: Identifiable {
    let id: UUID
    var size: Double
    var xOffset: Double
    var yOffset: Double
    var opacity: Double
}
