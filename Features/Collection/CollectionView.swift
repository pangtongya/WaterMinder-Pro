// CollectionView.swift
// 我的花园收藏 —— 已收获植物展示，收集心理的载体
//
// 用户把养熟的植物收获进来，形成"成就墙"。
// 同时展示所有品种（Pro 品种标记锁定），激发收集欲。

import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var storeManager: StoreManager

    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 收藏概览
                overviewCard

                // 当前正在养的植物
                currentPlantCard

                // 已收获的植物列表
                if !gardenStore.items.isEmpty {
                    harvestedSection
                }

                // 品种图鉴（含 Pro 品种）
                speciesCodex

                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.myGarden)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
    }

    // MARK: - 收藏概览

    private var overviewCard: some View {
        HStack(spacing: 0) {
            overviewStat(value: "\(gardenStore.totalCount)", label: "Harvested".localized, icon: "🌸")
            Divider().frame(height: 40)
            overviewStat(value: "\(gardenStore.uniqueSpeciesCount)", label: "Species".localized, icon: "🌿")
            Divider().frame(height: 40)
            overviewStat(value: "\(PlantLibrary.all.count)", label: "Total".localized, icon: "📖")
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func overviewStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 20))
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 当前植物

    private var currentPlantCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("正在养护".localized).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(plantEngine.plant.species.symbol).font(.system(size: 20))
            }

            AnimatedPlantView(plant: plantEngine.plant)
                .frame(width: 120, height: 160)

            Text(plantEngine.plant.name)
                .font(.system(size: 16, weight: .semibold))
            Text("\(plantEngine.plant.species.localizedName) · \(plantEngine.plant.stage.name)")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - 已收获列表

    private var harvestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("收获墙".localized).font(.system(size: 15, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(gardenStore.items) { item in
                    harvestedCard(item)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func harvestedCard(_ item: GardenItem) -> some View {
        VStack(spacing: 8) {
            // 真实植物视觉（替代 emoji）
            MiniPlantCanvas(speciesID: item.speciesID, stage: item.peakStage)
                .frame(width: 100, height: 100)

            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
            Text(item.species.localizedName)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(String(format: L.daysToHarvest, item.daysToHarvest))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - 品种图鉴

    private var speciesCodex: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("品种图鉴".localized).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(gardenStore.uniqueSpeciesCount)/\(PlantLibrary.all.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PlantLibrary.all) { species in
                    speciesCell(species)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func speciesCell(_ species: PlantSpecies) -> some View {
        let collected = gardenStore.hasCollected(speciesID: species.id)
        let locked = species.isPro && !storeManager.isPro

        VStack(spacing: 6) {
            ZStack {
                // 真正的植物预览（替代 emoji）
                MiniPlantCanvas(speciesID: species.id, stage: .harvestable)
                    .frame(width: 80, height: 80)
                    .opacity(locked ? 0.25 : 1.0)

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(8)
                        .background(Circle().fill(.orange.opacity(0.15)))
                }
            }

            Text(species.name)
                .font(.system(size: 11, weight: .medium))

            if collected {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text("已收集".localized)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.green)
                }
            } else if locked {
                Text("Pro 解锁".localized)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("未收集".localized)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(collected ? Color.bloomSuccess.opacity(0.1) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            if locked { showPaywall = true }
        }
    }
}

// MARK: - 简化版植物视图（收藏页、图鉴、Widget 复用）

/// 极简版植物绘制：用 PlantCanvas 的核心绘制逻辑，但尺寸更小、无动画
/// 只在需要时实例化，避免浪费渲染资源
struct MiniPlantCanvas: View {
    let speciesID: String
    let stage: GrowthStage

    var body: some View {
        let species = PlantLibrary.species(id: speciesID)
        let mockPlant = Plant(
            name: "",
            speciesID: species.id,
            stage: stage,
            growthPoints: 500,
            health: 85
        )
        PlantView(plant: mockPlant)
    }
}
