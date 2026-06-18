// PlantStatusCard.swift
// 植物状态卡片 —— 名字、健康度、状态文案
//
// 这块是情感的直接传达：让用户看到"它现在怎么样了"。
// 状态文案（来自 HealthCalculator.statusMessage）用愧疚/关怀语气，
// 是 chickenfocus 心理学的核心落地点。

import SwiftUI

struct PlantStatusCard: View {
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var waterStore: WaterStore

    var body: some View {
        VStack(spacing: 14) {
            // 名字 + 阶段
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plantEngine.plant.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("\(plantEngine.plant.species.name) · \(plantEngine.plant.stage.name)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                stageBadge
            }

            // 状态文案（情感传达）
            Text(HealthCalculator.statusMessage(plantEngine.plant.health))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(healthColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 健康度进度条
            healthBar

            // 成长进度（距离下一阶段）
            growthProgressBar

            // 连胜 + 里程碑
            if waterStore.currentStreak > 0 {
                streakRow
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 子视图

    private var stageBadge: some View {
        Text(plantEngine.plant.stage.emoji)
            .font(.system(size: 24))
            .padding(8)
            .background(Color.bloomPrimary.opacity(0.12))
            .clipShape(Circle())
    }

    private var healthBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L.health)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(plantEngine.plant.health))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(healthColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    Capsule()
                        .fill(healthColor)
                        .frame(width: geo.size.width * plantEngine.plant.health / 100, height: 6)
                        .animation(.spring(response: 0.6), value: plantEngine.plant.health)
                }
            }
            .frame(height: 6)
        }
    }

    private var healthColor: Color {
        Color.healthColor(plantEngine.plant.health)
    }

    // MARK: - 连胜 + 里程碑

    /// 里程碑天数及其奖励描述
    private static let milestones: [(days: Int, title: String, emoji: String)] = [
        (3,   "初露锋芒",   "🌱"),
        (7,   "坚持一周",   "🌿"),
        (14,  "两周达人",   "🪴"),
        (21,  "三周传奇",   "🌷"),
        (30,  "满月之约",   "🌸"),
        (60,  "双月坚守",   "🏆"),
        (100, "百日不辍",   "👑"),
    ]

    private var streakRow: some View {
        let streak = waterStore.currentStreak
        let passedMilestones = Self.milestones.filter { $0.days <= streak }
        let nextMilestone = Self.milestones.first { $0.days > streak }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                Text(String(format: NSLocalizedString("连续 %d 天达标", comment: ""), streak))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                // 最近达成里程碑
                if let last = passedMilestones.last {
                    Text("\(last.emoji) \(last.title)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.bloomGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.bloomGold.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            // 下一里程碑提示
            if let next = nextMilestone {
                HStack(spacing: 4) {
                    Text(String(format: NSLocalizedString("再坚持 %d 天 → %@ %@", comment: ""),
                              next.days - streak, next.emoji, next.title))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 成长进度条

    private var growthProgressBar: some View {
        let stage = plantEngine.plant.stage
        let points = plantEngine.plant.growthPoints
        let progress = GrowthRules.progressToNextStage(currentStage: stage, growthPoints: points)
        let nextName = GrowthRules.nextStage(after: stage)?.name
        let isMax = (stage == .harvestable)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(isMax ? NSLocalizedString("已满级", comment: "Max level") : NSLocalizedString("成长进度", comment: "Growth progress"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                if let next = nextName {
                    Text(String(format: NSLocalizedString("下一阶段：%@", comment: ""), next))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text(L.readyToHarvest)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.bloomGold)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 5)
                    Capsule()
                        .fill(Color.bloomPrimary.opacity(0.8))
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 5)
        }
    }
}

#Preview {
    PlantStatusCard()
        .environmentObject(PlantEngine())
        .environmentObject(WaterStore())
        .padding()
}
