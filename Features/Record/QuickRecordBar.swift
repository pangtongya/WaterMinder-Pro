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
    }

    // MARK: - 杯型按钮

    private func cupButton(_ cup: CupType) -> some View {
        Button {
            recordWater(cup)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.bloomWater.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: cup.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.bloomWater)
                }

                Text("\(cup.defaultAmount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("ml")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cup.rawValue) \(cup.defaultAmount) 毫升")
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
            ? "今日目标达成！"
            : "还差 \(waterStore.remaining) ml"
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

        // 1. 记录喝水数据
        waterStore.add(amount: amount, cupType: cup)

        // 2. 喂给植物（核心：植物恢复生机）
        plantEngine.water(amount: amount)

        // 3. 达标结算
        if waterStore.isGoalMetToday {
            plantEngine.processGoalMet()
        }

        // 4. 同步到健康App
        if healthManager.isAuthorized {
            Task { try? await healthManager.saveWater(amount) }
        }

        // 5. 触觉反馈
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

#Preview {
    QuickRecordBar()
        .environmentObject(WaterStore())
        .environmentObject(PlantEngine())
        .environmentObject(HealthManager.shared)
        .padding()
}
