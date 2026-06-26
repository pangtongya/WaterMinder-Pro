// CollectionView.swift
// Apple 风格重构 —— 收藏页
//
// 设计特点：
// - Apple Human Interface Guidelines 风格
// - 统计数据卡片
// - 品种网格展示
// - Pro 锁定样式

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
            VStack(spacing: 16) {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -geo.frame(in: .named("scroll")).origin.y
                    )
                }
                .frame(height: 0)
                
                // 收集进度总览
                collectionProgressCard
                    .padding(.horizontal, 16)
                
                // 当前养护植物
                currentPlantCard
                    .padding(.horizontal, 16)
                
                // 已收获列表
                if !gardenStore.items.isEmpty {
                    harvestedSection
                        .padding(.horizontal, 16)
                }
                
                // 品种图鉴
                speciesCodex
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            scrollOffset = offset
            checkLoadMore()
        }
        .scrollIndicators(.hidden)
        .background(Color.bloomBackground)
        .navigationTitle("收藏")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
        .sheet(isPresented: $showSpeciesDetail) {
            if let species = selectedSpecies {
                NavigationStack {
                    List {
                        Section("品种信息") {
                            HStack {
                                Text("名称")
                                Spacer()
                                Text(species.localizedName)
                            }
                            HStack {
                                Text("难度")
                                Spacer()
                                Text(species.difficulty.displayName)
                            }
                            HStack {
                                Text("需水量")
                                Spacer()
                                Text("\(species.waterNeed)")
                            }
                        }
                        
                        Section("收藏状态") {
                            HStack {
                                Text("是否已收藏")
                                Spacer()
                                if gardenStore.hasCollected(speciesID: species.id) {
                                    Text("已收藏").foregroundStyle(Color.bloomSuccess)
                                } else {
                                    Text("未收藏").foregroundStyle(Color.bloomTextTertiary)
                                }
                            }
                        }
                    }
                    .navigationTitle(species.localizedName)
                    .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(gardenStore)
            }
        }
        .onAppear {
            visibleHarvestCount = min(initialLoadCount, gardenStore.items.count)
        }
    }
    
    private func checkLoadMore() {
        guard hasMoreHarvests else { return }
        
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
        SurfaceCard(padding: 16) {
            VStack(spacing: 16) {
                // 标题行
                HStack {
                    IconCircle(
                        icon: "book.closed.fill",
                        backgroundColor: Color.bloomGoldMuted,
                        iconColor: Color.bloomWarning,
                        size: .small
                    )
                    
                    Text("收藏进度")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Text("\(gardenStore.uniqueSpeciesCount)/\(PlantLibrary.all.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bloomPrimary)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bloomFill)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bloomPrimary)
                            .frame(width: geometry.size.width * (Double(gardenStore.uniqueSpeciesCount) / Double(PlantLibrary.all.count)))
                            .animation(.easeInOut(duration: 0.4), value: gardenStore.uniqueSpeciesCount)
                    }
                }
                .frame(height: 8)
                
                // 统计卡片
                StatsCard(stats: [
                    (icon: "🌸", value: "\(gardenStore.totalCount)", label: "总收获数"),
                    (icon: "🌿", value: "\(gardenStore.uniqueSpeciesCount)", label: "已收集品种"),
                    (icon: "📖", value: "\(PlantLibrary.all.count)", label: "全部品种")
                ])
                
                // 全部收集提示
                if gardenStore.uniqueSpeciesCount == PlantLibrary.all.count {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.bloomWarning)
                        
                        Text("恭喜！已收集全部品种")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.bloomWarning)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - 当前植物

    private var currentPlantCard: some View {
        SurfaceCard(padding: 16) {
            VStack(spacing: 12) {
                // 标题行
                HStack {
                    Text("当前养护")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Badge(stageName, style: .brand)
                }
                
                // 植物视图
                AnimatedPlantView(plant: plantEngine.plant)
                    .frame(width: 100, height: 140)
                
                // 植物信息
                VStack(spacing: 4) {
                    Text(plantEngine.plant.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Text("\(plantEngine.plant.species.localizedName) · \(plantEngine.plant.stage.name)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                
                // 成长信息
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(plantEngine.plant.ageInDays)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.bloomTextPrimary)
                        Text("养护天数")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(plantEngine.plant.health))%")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.bloomPrimary)
                        Text("健康度")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 2) {
                        Text("\(plantEngine.plant.ageInDays)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.bloomWarning)
                        Text("养护天数")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                }
            }
        }
    }

    // MARK: - 已收获列表

    private var harvestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("收获墙", action: nil, actionTitle: nil)
            
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
    }

    private func harvestedCard(_ item: GardenItem) -> some View {
        VStack(spacing: 8) {
            // 用 PlantView 替代 MiniPlantCanvas
            PlantView(
                plant: Plant(
                    speciesID: item.speciesID,
                    stage: item.peakStage,
                    health: 100
                )
            )
            .frame(width: 80, height: 80)

            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)
                .lineLimit(1)
            
            Text(item.species.localizedName)
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextSecondary)
                .lineLimit(1)
            
            Text("\(item.daysToHarvest) 天成熟")
                .font(.system(size: 10))
                .foregroundStyle(Color.bloomTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 品种图鉴

    private var speciesCodex: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("品种图鉴", action: {
                // 查看全部
            }, actionTitle: "查看全部")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(PlantLibrary.all, id: \.id) { species in
                    let isCollected = gardenStore.hasCollected(speciesID: species.id)
                    let isProLocked = species.isProOnly && !storeManager.isPro
                    
                    Button {
                        if isCollected {
                            selectedSpecies = species
                            showSpeciesDetail = true
                        } else if !isProLocked {
                            // 购买或解锁
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        speciesCard(species, isCollected: isCollected, isProLocked: isProLocked)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func speciesCard(_ species: PlantSpecies, isCollected: Bool, isProLocked: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isCollected ? Color.bloomPrimary.opacity(0.15) : Color.bloomFill)
                    .frame(width: 48, height: 48)
                
                if isCollected {
                    Text(species.symbol)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: isProLocked ? "lock.fill" : "questionmark")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
            }
            
            Text(species.localizedName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isCollected ? Color.bloomTextPrimary : Color.bloomTextSecondary)
                .lineLimit(1)
            
            if isCollected {
                Badge("已收集", style: .brand)
            } else if isProLocked {
                Badge("Pro", style: .gold)
            } else {
                Badge("未收集", style: .fill)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(isCollected || !isProLocked ? 1.0 : 0.7)
    }
    
    // MARK: - Helper Properties
    
    private var stageName: String {
        switch plantEngine.plant.stage {
        case .seed: return "种子"
        case .sprout: return "发芽"
        case .seedling: return "幼苗"
        case .mature: return "成株"
        case .blooming: return "含苞"
        case .harvestable: return "盛开"
        }
    }
}
