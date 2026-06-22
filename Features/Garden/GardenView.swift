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
    @State private var plantPressing = false    // 植物按压视觉反馈
    @State private var showWilt = false         // 植物枯萎提示动画
    @State private var showGoalCelebration = false  // 达标庆祝


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

                // 1b. 枯萎恢复横幅（celebration 消失后仍然可见，直到用户喝水恢复健康）
                if plantEngine.plant.isWilted {
                    wiltBanner
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 2. 状态卡
                PlantStatusCard()
                    .padding(.horizontal, 20)

                // 3. 收获按钮（成熟时显示）或即将成熟提示
            if plantEngine.plant.canHarvest {
                harvestButton
                    .padding(.horizontal, 20)
            } else {
                harvestHint
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
        // 枯萎提示：监听 engine 发布的枯萎事件
        .onChange(of: plantEngine.justWilted) { _, wilted in
            if wilted {
                showWilt = true
                Haptics.error()
            }
        }
        // 达标庆祝：监听 waterStore.isGoalMetToday 的变化
        .onChange(of: waterStore.isGoalMetToday) { oldValue, newValue in
            if !oldValue && newValue {
                // 从未达标到达标，显示庆祝
                showGoalCelebration = true
                Haptics.success()
                
                // 3秒后自动消失
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
            // 枯萎提示：显示在植物区上方
            if showWilt {
                WiltCelebration {
                    withAnimation { showWilt = false }
                    plantEngine.consumeWilt()
                }
                .transition(.opacity)
            }
            // 达标庆祝
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

    private var plantHero: some View {
        ZStack {
            // 背景光晕（健康时鲜亮）
            RadialGradient(
                colors: [
                    healthGlowColor.opacity(plantEngine.plant.isPaused ? 0.05 : 0.15),
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
                .scaleEffect(plantPressing ? 0.94 : 1.0)  // 按压时微缩
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: plantPressing)
                .opacity(plantEngine.plant.isPaused ? 0.5 : 1.0)  // 暂停时植物半透明

            // 暂停状态提示覆盖
            if plantEngine.plant.isPaused {
                VStack(spacing: 10) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color(white: 0.45))
                    Text(L.carePaused)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                    Text(L.pauseExplanation)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(white: 0.35))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.85))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .contentShape(Rectangle())  // 让整个区域可点击
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in plantPressing = true }
                .onEnded { _ in plantPressing = false }
        )
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
                Text(String(format: L.daysRemaining, plantEngine.plant.remainingPauseDays))
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

    // MARK: - 枯萎恢复横幅

    /// 植物枯萎后持续显示的横幅，直到用户喝水恢复健康度 > 0
    /// 解决：WiltCelebration 消失后用户不知道自己该怎么让植物复活
    private var wiltBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.triangle.fill")
                .font(.system(size: 22))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.wiltBannerTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(L.wiltBannerBody)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: plantEngine.plant.isWilted)
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
                Text(String(format: L.harvestFormat, plantEngine.plant.name))
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

    /// 植物尚未成熟时的提示
    private var harvestHint: some View {
        let stage = plantEngine.plant.stage
        let growthPoints = plantEngine.plant.growthPoints
        let next = GrowthRules.nextStage(after: stage)
        let remaining = GrowthRules.pointsToNextStage(currentStage: stage, growthPoints: growthPoints)

        return HStack(spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.bloomPrimary.opacity(0.8))
            VStack(alignment: .leading, spacing: 2) {
                if let nextStage = next {
                    Text(String(format: L.waterMoreForStage, nextStage.name))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                    if let pts = remaining, pts > 0 {
                        Text(String(format: L.pointsToNextStage, Int(pts)))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(L.plantGrowingHealthily)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.bloomPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            // 暂停养护：不更新植物，但给用户清晰反馈
            if plantEngine.plant.isPaused {
                Haptics.error()
                // 给用户短暂的"摇晃"视觉效果（由 splashTrigger + 错误触觉组合表示）
                return
            }
            let succeeded = await plantEngine.waterPlant(
                cup: cup,
                waterStore: waterStore,
                healthManager: healthManager
            )
            // 水滴动画 + 触觉（UI 相关，仍在 View 层）
            if succeeded {
                splashTrigger += 1
                Haptics.waterDrop()
            } else {
                Haptics.error()
            }
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
    @State private var showUndoSnackbar = false
    @State private var deletedRecord: WaterRecord?
    @State private var plantStateBeforeDelete: Plant?
    @State private var undoTask: Task<Void, Never>? = nil  // 使用 Task 替代 DispatchWorkItem
    
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
                    Text(String(format: L.plantHasntWatered, plantEngine.plant.name))
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
            
            // 撤销 Snackbar
            if showUndoSnackbar, let deleted = deletedRecord {
                UndoSnackbarView(
                    deletedRecord: deleted,
                    onUndo: performUndo,
                    onDismiss: dismissUndoSnackbar
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: showUndoSnackbar)
        .alert(L.deleteRecordConfirm, isPresented: $showDeleteConfirm) {
            Button(L.cancel, role: .cancel) { }
            Button(L.delete, role: .destructive) {
                if let record = recordToDelete {
                    performDelete(record)
                }
            }
        } message: {
            Text(L.deleteRecordWarning)
        }
    }
    
    // MARK: - 删除记录（带撤销功能）
    
    private func performDelete(_ record: WaterRecord) {
        // 保存删除前的植物状态
        plantStateBeforeDelete = plantEngine.plant
        deletedRecord = record
        
        // 执行删除
        Task {
            await plantEngine.deleteRecord(record, waterStore: waterStore, healthManager: healthManager)
        }
        
        // 显示撤销 Snackbar
        withAnimation {
            showUndoSnackbar = true
        }
        
        // 5秒后自动消失（使用 Task 替代 DispatchWorkItem）
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                await MainActor.run {
                    dismissUndoSnackbar()
                }
            }
        }
        
        Haptics.light()
    }
    
    // MARK: - 撤销删除
    
    private func performUndo() {
        guard let record = deletedRecord, let previousPlant = plantStateBeforeDelete else { return }
        
        // 取消自动消失
        undoTask?.cancel()
        
        // 恢复记录（直接插入，不创建新记录）
        waterStore.restore(record: record)
        
        // 恢复植物状态
        plantEngine.restorePlantState(previousPlant)
        
        // 移除 Snackbar
        withAnimation {
            showUndoSnackbar = false
        }
        
        Haptics.success()
    }
    
    // MARK: - 消失撤销 Snackbar
    
    private func dismissUndoSnackbar() {
        withAnimation {
            showUndoSnackbar = false
        }
        deletedRecord = nil
        plantStateBeforeDelete = nil
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
                Label(L.delete, systemImage: "trash")
            }
        }
    }
}

// MARK: - 撤销 Snackbar

struct UndoSnackbarView: View {
    let deletedRecord: WaterRecord
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.bloomSuccess)
            
            Text(String(format: L.deletedFormat, deletedRecord.formattedAmount))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                onUndo()
            } label: {
                Text(L.undo)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.bloomPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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

// MARK: - 植物枯萎提示（情感反馈的另一面，提醒用户要更勤喝水）

struct WiltCelebration: View {
    let onDismiss: () -> Void
    @State private var appear = false
    @State private var leavesFalling = false

    var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                // 枯萎的植物图标 + 落叶粒子
                ZStack {
                    // 灰暗的背景光环
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.brown.opacity(0.45), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(appear ? 1.0 : 0.4)

                    // 枯萎植物（低垂的叶子）
                    VStack(spacing: 0) {
                        HStack(spacing: -10) {
                            Circle()
                                .fill(Color.brown)
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(leavesFalling ? -25 : -10))
                                .offset(y: leavesFalling ? 20 : 0)
                            Circle()
                                .fill(Color.brown.opacity(0.8))
                                .frame(width: 28, height: 28)
                                .rotationEffect(.degrees(leavesFalling ? 20 : 10))
                                .offset(y: leavesFalling ? 15 : 0)
                        }
                        // 主茎
                        Rectangle()
                            .fill(Color.brown.opacity(0.85))
                            .frame(width: 10, height: 60)
                            .rotationEffect(.degrees(leavesFalling ? 8 : 2))
                            .offset(y: -8)
                    }
                    .scaleEffect(appear ? 1.0 : 0.3)
                    .opacity(appear ? 1 : 0)

                    // 散落的叶片
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.brown.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .offset(
                                x: leavesFalling ? CGFloat(i * 8 - 16) : 0,
                                y: leavesFalling ? 80 : 0
                            )
                            .opacity(leavesFalling ? 0 : 1)
                            .animation(
                                Animation.easeIn(duration: 1.2)
                                    .delay(Double(i) * 0.15),
                                value: leavesFalling
                            )
                    }
                }

                // 主标题：温和的"枯萎"提示
                Text(L.plantWilted)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)

                // 副标题：温和的提醒
                Text(L.startFromSeed)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)

                // 提示卡片：健康度说明
                HStack(spacing: 10) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.bloomWater)
                    Text(L.dailyHydrationTip)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .opacity(appear ? 1 : 0)

                // 继续按钮
                Button {
                    onDismiss()
                } label: {
                    Text(L.gotIt)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                appear = true
            }
            // 延迟一会儿让叶子落下
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    leavesFalling = true
                }
            }
        }
    }
}

// MARK: - 水滴飞溅动画

/// 点击浇水时，水滴飞溅动画（增强版）
struct WaterSplashOverlay: View {
    let trigger: Int

    @State private var drops: [WaterDrop] = []
    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(drops) { drop in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.bloomWater.opacity(drop.opacity),
                                    Color.bloomWater.opacity(drop.opacity * 0.5)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: drop.size / 2
                            )
                        )
                        .frame(width: drop.size, height: drop.size)
                        .offset(x: drop.xOffset, y: drop.yOffset)
                        .blur(radius: drop.blur)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            spawnDrops()
        }
    }

    private func spawnDrops() {
        // 生成 12 颗随机水滴（增加到 12 颗，更丰富）
        let newDrops = (0..<12).map { i -> WaterDrop in
            let angle = Double(i) / 12.0 * 360
            let distance = Double.random(in: 30...70)
            let radian = angle * .pi / 180
            
            return WaterDrop(
                id: UUID(),
                size: Double.random(in: 6...14),
                xOffset: 0,
                yOffset: 0,
                opacity: 0.9,
                targetX: cos(radian) * distance,
                targetY: sin(radian) * distance,
                blur: Double.random(in: 0...2)
            )
        }
        drops = newDrops

        // 飞溅动画（使用 spring 动画，更生动）
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            for i in drops.indices {
                drops[i].xOffset = drops[i].targetX
                drops[i].yOffset = drops[i].targetY
                drops[i].opacity = 0
                drops[i].size *= 0.5
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
    var targetX: Double = 0
    var targetY: Double = 0
    var blur: Double = 0
}

// MARK: - 达标庆祝视图

/// 每日目标达成时的庆祝弹窗
struct GoalCelebrationView: View {
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showStars: Bool = false
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 庆祝卡片
            VStack(spacing: 20) {
                // 星星动画
                if showStars {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.yellow)
                                .scaleEffect(showStars ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.1), value: showStars)
                        }
                    }
                    .padding(.top, 10)
                }
                
                // 图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.bloomSuccess)
                    .scaleEffect(scale)
                
                // 标题
                Text(L.goalAchieved)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomPrimary)
                
                // 副标题
                Text(L.keepUpGoodHabits)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // 关闭按钮
                Button {
                    onDismiss()
                } label: {
                    Text(L.amazing)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showStars = true
                }
            }
        }
    }
}
