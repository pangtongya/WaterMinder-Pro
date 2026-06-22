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

    @State private var lastAmount: Int = 0  // 记录最近一次水量（用于水滴动画）
    @State private var showSuccessPulse: Bool = false  // 成功喝水后的脉冲动画
    @State private var pressedCup: CupType? = nil  // 当前按下的杯型（用于按压反馈）
    @State private var showAmountBubble: CupType? = nil  // 显示水量气泡
    @State private var bubbleTask: Task<Void, Never>? = nil  // 使用 Task 替代 Timer

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(CupType.allCases, id: \.self) { cup in
                    cupButton(cup)
                }
            }

            // 今日进度提示
            progressHint
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            // 成功喝水后的脉冲光环
            if showSuccessPulse {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.bloomWater.opacity(0.6), lineWidth: 3)
                    .padding(-4)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - 杯型按钮

    private func cupButton(_ cup: CupType) -> some View {
        Button {
            recordWater(cup)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // 背景圆（按压时放大）
                    Circle()
                        .fill(Color.bloomWater.opacity(pressedCup == cup ? 0.25 : 0.12))
                        .frame(width: pressedCup == cup ? 56 : 52, height: pressedCup == cup ? 56 : 52)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressedCup)

                    Image(systemName: cup.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.bloomWater)
                        .scaleEffect(pressedCup == cup ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressedCup)
                }

                Text("\(cup.defaultAmount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("ml")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                // 水量气泡（点击后显示）
                if showAmountBubble == cup {
                    Text("+\(cup.defaultAmount)ml")
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
                .onChanged { _ in pressedCup = cup }
                .onEnded { _ in pressedCup = nil }
        )
        .accessibilityLabel("\(cup.localizedName) \(cup.defaultAmount) ml")
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

    // MARK: - 记录喝水

    private func recordWater(_ cup: CupType) {
        let amount = cup.defaultAmount
        lastAmount = amount

        // 1. 显示水量气泡（使用 Task 替代 Timer，自动取消旧任务）
        bubbleTask?.cancel()
        showAmountBubble = cup
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
        waterStore.add(amount: amount, cupType: cup)

        // 3. 喂给植物（核心：植物恢复生机）
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

        // 7. 成功脉冲动画（视觉反馈）
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
