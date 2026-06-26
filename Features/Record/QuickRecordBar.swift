// QuickRecordBar.swift
// 快速记录条 —— 喝水按钮，按完植物立即恢复生机
//
// 这是用户与植物互动的核心触点：每按一次，植物就"喝到水"，
// 健康度回升、成长值累积，是即时的情感正反馈。

import SwiftUI

struct QuickRecordBar: View {
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var lastAmount: Int = 0
    @State private var showSuccessPulse: Bool = false
    @State private var showAmountBubble: Int? = nil
    @State private var bubbleTask: Task<Void, Never>? = nil
    @State private var isWaterButtonPressed: Bool = false
    
    // 常用杯型选项（固定显示）
    private let quickAmounts = [200, 300, 500]
    
    var body: some View {
        SurfaceCard(padding: 20) {
            VStack(spacing: 16) {
                // 主要喝水按钮
                mainWaterButton
                
                // 杯型快捷选择
                cupSizeSelector
                
                // 今日进度提示
                progressHint
            }
        }
        .background(Color.bloomWaterMuted.opacity(0.3))
        .overlay {
            // 成功喝水后的脉冲光环
            if showSuccessPulse {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.bloomWater.opacity(0.6), lineWidth: 3)
                    .padding(-4)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - 主要喝水按钮
    
    private var mainWaterButton: some View {
        Button {
            recordWater(lastAmount > 0 ? lastAmount : 250)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    // 水滴图标背景
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bloomWater, Color.bloomWater.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    // 水滴图标
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(isWaterButtonPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isWaterButtonPressed)
                }

                Text("喝水")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.bloomWater, Color.bloomWater.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isWaterButtonPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isWaterButtonPressed)
            .overlay(alignment: .top) {
                // 水量气泡提示
                if let amount = showAmountBubble {
                    Text("+\(amount)ml")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.bloomWater)
                        .clipShape(Capsule())
                        .offset(y: -8)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAmountBubble)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isWaterButtonPressed = true }
                .onEnded { _ in isWaterButtonPressed = false }
        )
    }
    
    // MARK: - 杯型选择器
    
    private var cupSizeSelector: some View {
        HStack(spacing: 12) {
            ForEach(quickAmounts, id: \.self) { amount in
                CupSizeButton(
                    amount: amount,
                    icon: cupIcon(for: amount),
                    isSelected: lastAmount == amount
                ) {
                    recordWater(amount)
                }
            }
            
            // 自定义杯型入口
            customCupButton
        }
    }
    
    private var customCupButton: some View {
        Button {
            // TODO: 打开自定义杯型界面
            Haptics.light()
        } label: {
            VStack(spacing: 4) {
                IconCircle(
                    icon: "plus",
                    backgroundColor: Color.bloomFill,
                    iconColor: Color.bloomTextSecondary,
                    size: .medium
                )
                
                Text("自定义")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 进度提示
    
    private var progressHint: some View {
        HStack(spacing: 6) {
            Image(systemName: waterStore.isGoalMetToday ? "checkmark.circle.fill" : "drop.fill")
                .font(.system(size: 13))
            Text(progressText)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(progressColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(progressColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var progressText: String {
        waterStore.isGoalMetToday
            ? NSLocalizedString("今日目标达成！", comment: "Goal achieved")
            : String(format: NSLocalizedString("还差 %d ml", comment: "Remaining ml"), waterStore.remaining)
    }
    
    private var progressColor: Color {
        let p = waterStore.todayProgress
        if p >= 1.0 { return Color.bloomSuccess }
        if p < 0.3 { return Color.bloomDanger }
        return Color.bloomPrimary
    }
    
    // MARK: - 辅助方法
    
    private func cupIcon(for amount: Int) -> String {
        switch amount {
        case 200: return "cup.and.saucer.fill"
        case 300: return "mug.fill"
        case 500: return "takeoutbag.and.cup.and.straw.fill"
        default: return "cup.and.saucer.fill"
        }
    }
    
    private func recordWater(_ amount: Int) {
        lastAmount = amount
        
        // 1. 显示水量气泡
        bubbleTask?.cancel()
        showAmountBubble = amount
        bubbleTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation {
                        showAmountBubble = nil
                    }
                }
            }
        }
        
        // 2. 记录喝水数据
        let cupType: CupType = {
            switch amount {
            case 200: return .small
            case 300: return .medium  // 使用 medium 作为 300ml
            case 500: return .large
            default: return .medium
            }
        }()
        
        waterStore.add(amount: amount, cupType: cupType)
        
        // 3. 喂给植物
        plantEngine.water(amount: amount)
        
        // 4. 达标结算
        if waterStore.isGoalMetToday {
            plantEngine.processGoalMet()
        }
        
        // 5. 同步到健康App
        if healthManager.isAuthorized {
            Task { try? await healthManager.saveWater(amount) }
        }
        
        // 6. 触觉反馈
        Haptics.waterDrop()
        
        // 7. 成功脉冲动画
        showSuccessPulse = true
        withAnimation(.easeOut(duration: 0.3)) {
            showSuccessPulse = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showSuccessPulse = false
                    }
                }
            }
        }
    }
}

#Preview {
    QuickRecordBar()
        .environmentObject(WaterStore())
        .environmentObject(PlantEngine())
        .environmentObject(HealthManager.shared)
        .padding()
        .background(Color(.systemBackground))
}