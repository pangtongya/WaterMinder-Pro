// CollectionView.swift
// 我的花园收藏 —— 已收获植物展示，收集心理的载体
//
// 用户把养熟的植物收获进来，形成"成就墙"。
// 同时展示所有品种（Pro 品种标记锁定），激发收集欲。

import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CollectionView: View {
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var storeManager: StoreManager

    @State private var showPaywall = false
    @State private var selectedSpecies: PlantSpecies?
    @State private var showSpeciesDetail = false
    @State private var visibleHarvestCount: Int = 6
    @State private var scrollOffset: CGFloat = 0
    
    private let initialLoadCount = 6
    private let loadMoreThreshold: CGFloat = 200
    
    private var hasMoreHarvests: Bool {
        visibleHarvestCount < gardenStore.items.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -geo.frame(in: .named("scroll")).origin.y
                    )
                }
                .frame(height: 0)
                
                collectionProgressCard

                currentPlantCard

                if !gardenStore.items.isEmpty {
                    harvestedSection
                }

                speciesCodex

                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            scrollOffset = offset
            checkLoadMore()
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.myGarden)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
        .sheet(isPresented: $showSpeciesDetail) {
            if let species = selectedSpecies {
                SpeciesDetailView(species: species)
                    .environmentObject(gardenStore)
            }
        }
        .onAppear {
            visibleHarvestCount = min(initialLoadCount, gardenStore.items.count)
        }
    }
    
    private func checkLoadMore() {
        guard hasMoreHarvests else { return }
        
        // 当滚动到接近底部时加载更多
        DispatchQueue.main.async {
            if scrollOffset > loadMoreThreshold {
                loadMoreHarvests()
            }
        }
    }
    
    private func loadMoreHarvests() {
        let nextCount = min(visibleHarvestCount + 6, gardenStore.items.count)
        if nextCount > visibleHarvestCount {
            withAnimation(.easeInOut(duration: 0.3)) {
                visibleHarvestCount = nextCount
            }
        }
    }

    // MARK: - 收集进度总览

    private var collectionProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.bloomGold)
                Text(L.collectionProgress)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(gardenStore.uniqueSpeciesCount)/\(PlantLibrary.all.count)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomPrimary)
            }

            VStack(spacing: 8) {
                ProgressView(value: Double(gardenStore.uniqueSpeciesCount), total: Double(PlantLibrary.all.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .bloomPrimary))
                
                HStack {
                    Text(String(format: L.collectionProgressHint, gardenStore.uniqueSpeciesCount, PlantLibrary.all.count))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if gardenStore.uniqueSpeciesCount == PlantLibrary.all.count {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.bloomGold)
                        Text(L.allCollected)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.bloomGold)
                    }
                }
            }

            HStack(spacing: 0) {
                progressStat(value: "\(gardenStore.totalCount)", label: L.totalHarvests, icon: "🌸")
                Divider().frame(height: 40)
                progressStat(value: "\(gardenStore.uniqueSpeciesCount)", label: L.speciesCollected, icon: "🌿")
                Divider().frame(height: 40)
                progressStat(value: "\(PlantLibrary.all.count)", label: L.totalSpecies, icon: "📖")
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func progressStat(value: String, label: String, icon: String) -> some View {
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
                Text(L.currentlyCaring).font(.system(size: 15, weight: .semibold))
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
            HStack {
                Text(L.harvestWall).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(gardenStore.items.count)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(gardenStore.items.prefix(visibleHarvestCount))) { item in
                    harvestedCard(item)
                }
            }
            
            if hasMoreHarvests {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 8)
                    Spacer()
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
                Text(L.speciesCodex).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(gardenStore.uniqueSpeciesCount)/\(PlantLibrary.all.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PlantLibrary.all) { species in
                    speciesCell(species)
                        .onTapGesture {
                            handleSpeciesTap(species)
                        }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func handleSpeciesTap(_ species: PlantSpecies) {
        let collected = gardenStore.hasCollected(speciesID: species.id)
        let locked = species.isPro && !storeManager.isPro

        if locked {
            showPaywall = true
        } else if collected {
            selectedSpecies = species
            showSpeciesDetail = true
        }
    }

    @ViewBuilder
    private func speciesCell(_ species: PlantSpecies) -> some View {
        let collected = gardenStore.hasCollected(speciesID: species.id)
        let locked = species.isPro && !storeManager.isPro
        let harvestCount = harvestCountForSpecies(species.id)

        VStack(spacing: 6) {
            ZStack {
                if collected {
                    MiniPlantCanvas(speciesID: species.id, stage: .harvestable)
                        .frame(width: 80, height: 80)
                } else {
                    ZStack {
                        MiniPlantCanvas(speciesID: species.id, stage: .harvestable)
                            .frame(width: 80, height: 80)
                            .opacity(0.15)
                            .saturation(0)
                        
                        Image(systemName: "questionmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                }

                if locked {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            if collected {
                Text(species.localizedName)
                    .font(.system(size: 11, weight: .medium))
            } else {
                Text(L.mysterySpecies)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            if collected {
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text(L.collected)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.green)
                    }
                    if harvestCount > 1 {
                        Text(String(format: L.harvestCount, harvestCount))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            } else if locked {
                Text(L.proUnlock)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text(L.notCollected)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(collected ? Color.bloomSuccess.opacity(0.08) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(collected ? Color.bloomSuccess.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func harvestCountForSpecies(_ speciesID: String) -> Int {
        gardenStore.items.filter { $0.speciesID == speciesID }.count
    }
}

// MARK: - 品种详情视图

struct SpeciesDetailView: View {
    let species: PlantSpecies
    @EnvironmentObject var gardenStore: GardenStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    detailInfoCard
                    
                    harvestHistorySection
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(species.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.done) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.bloomPrimary)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: species.colorTheme.primary).opacity(0.2), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                MiniPlantCanvas(speciesID: species.id, stage: .harvestable)
                    .frame(width: 140, height: 140)
            }
            
            Text(species.localizedName)
                .font(.system(size: 22, weight: .bold))
            
            Text(species.localizedDescription)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var detailInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.bloomPrimary)
                Text(L.speciesInfo)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            
            VStack(spacing: 10) {
                detailRow(label: L.scientificName, value: species.scientificName)
                Divider()
                detailRow(label: L.difficulty, value: species.difficulty.displayName)
                Divider()
                detailRow(label: L.waterNeed, value: String(repeating: "💧", count: species.waterNeed))
                Divider()
                detailRow(label: L.bloomColor, value: species.bloomColor)
                Divider()
                detailRow(label: L.growthDays, value: String(format: L.daysN, species.growthDays.totalDays))
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
    }

    private var harvestHistorySection: some View {
        let harvests = gardenStore.items.filter { $0.speciesID == species.id }
            .sorted { $0.harvestedAt > $1.harvestedAt }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.bloomGold)
                Text(L.harvestHistory)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(harvests.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomGold)
            }

            if harvests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "leaf")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text(L.noHarvestYet)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(harvests.enumerated()), id: \.element.id) { idx, item in
                        harvestHistoryRow(item)
                        if idx < harvests.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func harvestHistoryRow(_ item: GardenItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.bloomPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(item.species.symbol)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                Text(String(format: L.daysToHarvest, item.daysToHarvest))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.harvestedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
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
