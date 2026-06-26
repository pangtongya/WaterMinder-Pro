import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var storeManager: StoreManager

    @State private var showPaywall = false
    @State private var selectedSpecies: PlantSpecies?
    @State private var showSpeciesDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                statsCard
                    .padding(.horizontal, 16)
                
                currentPlantCard
                    .padding(.horizontal, 16)
                
                harvestWallSection
                    .padding(.horizontal, 16)
                
                speciesCodexSection
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
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
    }

    // MARK: - 1. 顶部统计卡片

    private var statsCard: some View {
        SurfaceCard(padding: 16) {
            HStack(spacing: 0) {
                statItem(
                    icon: "🌸",
                    value: "\(gardenStore.items.count)",
                    label: "已收获"
                )
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 0.5)
                    .background(Color.bloomDivider)
                
                statItem(
                    icon: "🌿",
                    value: "\(gardenStore.uniqueSpeciesCount)",
                    label: "品种"
                )
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 0.5)
                    .background(Color.bloomDivider)
                
                statItem(
                    icon: "📖",
                    value: "\(PlantSpecies.allCases.count)",
                    label: "全部"
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 24))
                .padding(.bottom, 2)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.bloomPrimary)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextSecondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 2. 当前植物卡片

    private var currentPlantCard: some View {
        SurfaceCard(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("正在养护")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)
                    
                    Spacer()
                    
                    Text("🌼")
                        .font(.system(size: 20))
                }
                .padding(.bottom, 12)
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.bloomPrimary.opacity(0.15),
                                        Color.bloomPrimary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 160)
                        
                        AnimatedPlantView(plant: plantEngine.plant)
                            .frame(width: 100, height: 140)
                    }
                    .frame(width: 120, height: 160)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(plantEngine.plant.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.bloomTextPrimary)
                            .tracking(-0.3)
                            .lineLimit(1)
                        
                        Text("\(plantEngine.plant.species.localizedName) · \(plantEngine.plant.stage.name)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                            .padding(.top, 4)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Badge("第 \(plantEngine.plant.ageInDays) 天", style: .brand)
                            Badge("养护中", style: .fill)
                        }
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - 3. 收获墙

    private var harvestWallSection: some View {
        SurfaceCard(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("收获墙")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Text("\(gardenStore.items.count) 棵")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                .padding(.bottom, 12)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(gardenStore.items) { item in
                        harvestedPlantCard(item)
                    }
                    
                    if gardenStore.items.isEmpty {
                        emptyHarvestSlot
                    }
                }
            }
        }
    }
    
    private func harvestedPlantCard(_ item: GardenItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(harvestIconColor(for: item.species).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text(item.species.symbol)
                    .font(.system(size: 20))
            }
            .padding(.bottom, 8)
            
            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)
                .lineLimit(1)
            
            Text("\(item.species.localizedName) · 成熟")
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextSecondary)
                .padding(.top, 2)
                .lineLimit(1)
            
            Text("\(item.daysToHarvest) 天收获")
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var emptyHarvestSlot: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.bloomTextTertiary)
            
            Text("继续养护")
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func harvestIconColor(for species: PlantSpecies) -> Color {
        switch species.id {
        case "sunflower": return .bloomPrimary
        case "mint": return .bloomWater
        case "succulent": return .bloomPrimary
        default: return Color(hex: species.colorTheme.primary)
        }
    }

    // MARK: - 4. 品种图鉴

    private var speciesCodexSection: some View {
        SurfaceCard(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("品种图鉴")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Text("\(gardenStore.uniqueSpeciesCount)/\(PlantSpecies.allCases.count)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                .padding(.bottom, 12)
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    ForEach(PlantSpecies.allCases, id: \.id) { species in
                        let isCollected = gardenStore.hasCollected(speciesID: species.id)
                        let isProLocked = species.isProOnly && !storeManager.isPro
                        
                        Button {
                            if isCollected {
                                selectedSpecies = species
                                showSpeciesDetail = true
                            } else if isProLocked {
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
    }
    
    private func speciesCard(_ species: PlantSpecies, isCollected: Bool, isProLocked: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isCollected ? Color.bloomPrimary.opacity(0.15) : Color.bloomFill)
                    .frame(width: 48, height: 48)
                
                if isCollected {
                    Text(species.symbol)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: isProLocked ? "lock.fill" : "questionmark")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
            }
            .padding(.bottom, 6)
            
            Text(species.localizedName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isCollected ? Color.bloomTextPrimary : Color.bloomTextSecondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            if isCollected {
                Badge("已收集", style: .brand)
                    .padding(.top, 4)
            } else if isProLocked {
                Badge("Pro 解锁", style: .gold)
                    .padding(.top, 4)
            } else {
                Badge("未收集", style: .fill)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(isCollected ? Color.bloomPrimary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(isCollected || !isProLocked ? 1.0 : 0.5)
    }
}

extension PlantSpecies: CaseIterable {
    public static var allCases: [PlantSpecies] {
        PlantLibrary.all
    }
}
