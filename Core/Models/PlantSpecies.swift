// PlantSpecies.swift
// 植物品种资源库 —— 每个品种定义形态参数，供程序化绘制引擎使用

import SwiftUI

struct PlantSpecies: Identifiable, Codable, Hashable {
    let id: String
    let name: String           // 中文名
    let nameEn: String         // 英文名
    let symbol: String         // 简称（用于花园标签）
    let isPro: Bool            // 是否 Pro 解锁
    let description: String   // 中文描述
    let descriptionEn: String  // 英文描述
    let scientificName: String // 学名

    // 形态参数（供 PlantCanvas 绘制）
    let stemColorHex: String   // 茎/叶颜色
    let flowerColorHex: String // 花朵颜色
    let flowerCenterHex: String// 花心颜色
    let petalCount: Int        // 花瓣数
    let petalShape: PetalShape // 花瓣形状

    // 颜色主题
    let colorTheme: ColorTheme

    // 生长参数
    let growthDays: GrowthDays // 各生长阶段需要的天数
    let waterNeed: Int         // 需水量指数 1-5
    let difficulty: Difficulty // 难度

    // 植物特征
    let bloomColor: String     // 开花颜色
    let leafShape: LeafShape   // 叶子形状

    enum PetalShape: String, Codable {
        case round   // 圆瓣（向日葵）
        case pointed // 尖瓣（玫瑰）
        case cluster // 簇状（樱花）
        case fan     // 扇形（多肉）
    }

    enum Difficulty: String, Codable {
        case easy
        case medium
        case hard

        var displayName: String {
            switch self {
            case .easy:
                return NSLocalizedString("简单", comment: "Easy difficulty")
            case .medium:
                return NSLocalizedString("中等", comment: "Medium difficulty")
            case .hard:
                return NSLocalizedString("困难", comment: "Hard difficulty")
            }
        }
    }

    enum LeafShape: String, Codable {
        case ovate      // 卵形
        case lanceolate // 披针形
        case palmate    // 掌状
        case linear     // 线形
        case succulent  // 肉质
        case peltate    // 盾形
    }

    struct ColorTheme: Codable, Hashable {
        let primary: String    // 主色调
        let secondary: String  // 次要色调
        let dark: String       // 深色调
    }

    struct GrowthDays: Codable, Hashable {
        let seedToSprout: Int
        let sproutToSeedling: Int
        let seedlingToMature: Int
        let matureToBlooming: Int
        let bloomingToHarvestable: Int

        var totalDays: Int {
            seedToSprout + sproutToSeedling + seedlingToMature + matureToBlooming + bloomingToHarvestable
        }
    }

    // MARK: - 颜色快捷访问（绘制引擎用）

    var stemColor: Color { Color(hex: stemColorHex) }
    var flowerColor: Color { Color(hex: flowerColorHex) }
    var flowerCenterColor: Color { Color(hex: flowerCenterHex) }

    var isFree: Bool { !isPro }
    var isProOnly: Bool { isPro }

    /// 本地化的名称
    var localizedName: String {
        Bundle.main.preferredLocalizations.contains("zh") ? name : nameEn
    }

    /// 本地化的描述
    var localizedDescription: String {
        Bundle.main.preferredLocalizations.contains("zh") ? description : descriptionEn
    }
}

// MARK: - 品种库（内置）

enum PlantLibrary {
    /// 免费品种（新用户可选）
    static let free: [PlantSpecies] = [.sunflower, .succulent, .mint]

    /// Pro 解锁品种
    static let pro: [PlantSpecies] = [
        .rose, .sakura, .tulip, .lavender,
        .cherryBlossom, .frenchLavender, .lotus, .bamboo, .jadePlant
    ]

    /// 全部品种
    static let all: [PlantSpecies] = free + pro

    /// 按 id 查找
    static func species(id: String) -> PlantSpecies {
        all.first { $0.id == id } ?? .sunflower
    }
}

// MARK: - 静态方法

extension PlantSpecies {
    static func allSpecies() -> [PlantSpecies] {
        PlantLibrary.all
    }

    static func proSpecies() -> [PlantSpecies] {
        PlantLibrary.pro
    }

    static func freeSpecies() -> [PlantSpecies] {
        PlantLibrary.free
    }
}

extension PlantSpecies {
    /// 向日葵（默认首株，免费）
    static let sunflower = PlantSpecies(
        id: "sunflower",
        name: NSLocalizedString("向日葵", comment: "Sunflower plant name"),
        nameEn: "Sunflower",
        symbol: "🌻",
        isPro: false,
        description: NSLocalizedString("向阳而生，你的第一株伙伴", comment: "Sunflower description"),
        descriptionEn: "Growing toward the sun, your first companion",
        scientificName: "Helianthus annuus",
        stemColorHex: "#3D8A2E",
        flowerColorHex: "#F5B82E",
        flowerCenterHex: "#7A4A1A",
        petalCount: 14,
        petalShape: .pointed,
        colorTheme: ColorTheme(
            primary: "#F5B82E",
            secondary: "#FFD93D",
            dark: "#7A4A1A"
        ),
        growthDays: GrowthDays(
            seedToSprout: 1,
            sproutToSeedling: 2,
            seedlingToMature: 3,
            matureToBlooming: 3,
            bloomingToHarvestable: 2
        ),
        waterNeed: 3,
        difficulty: .easy,
        bloomColor: NSLocalizedString("明黄色", comment: "Bright yellow bloom color"),
        leafShape: .ovate
    )

    static let succulent = PlantSpecies(
        id: "succulent",
        name: NSLocalizedString("多肉", comment: "Succulent plant name"),
        nameEn: "Succulent",
        symbol: "🪴",
        isPro: false,
        description: NSLocalizedString("憨态可掬，坚韧又可爱", comment: "Succulent description"),
        descriptionEn: "Cute and resilient, tough yet adorable",
        scientificName: "Sedum morganianum",
        stemColorHex: "#5C9A4A",
        flowerColorHex: "#E88BA0",
        flowerCenterHex: "#D4647E",
        petalCount: 8,
        petalShape: .fan,
        colorTheme: ColorTheme(
            primary: "#5C9A4A",
            secondary: "#8BC34A",
            dark: "#2E5A1C"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 3,
            seedlingToMature: 4,
            matureToBlooming: 4,
            bloomingToHarvestable: 3
        ),
        waterNeed: 1,
        difficulty: .easy,
        bloomColor: NSLocalizedString("粉色", comment: "Pink bloom color"),
        leafShape: .succulent
    )

    static let mint = PlantSpecies(
        id: "mint",
        name: NSLocalizedString("薄荷", comment: "Mint plant name"),
        nameEn: "Mint",
        symbol: "🌿",
        isPro: false,
        description: NSLocalizedString("清新提神，越喝越精神", comment: "Mint description"),
        descriptionEn: "Fresh and energizing, the more you drink the better you feel",
        scientificName: "Mentha spicata",
        stemColorHex: "#4FAE5C",
        flowerColorHex: "#C8A8E8",
        flowerCenterHex: "#9A7BC4",
        petalCount: 10,
        petalShape: .round,
        colorTheme: ColorTheme(
            primary: "#4FAE5C",
            secondary: "#81C784",
            dark: "#1B5E20"
        ),
        growthDays: GrowthDays(
            seedToSprout: 1,
            sproutToSeedling: 2,
            seedlingToMature: 2,
            matureToBlooming: 3,
            bloomingToHarvestable: 2
        ),
        waterNeed: 4,
        difficulty: .easy,
        bloomColor: NSLocalizedString("淡紫色", comment: "Light purple bloom color"),
        leafShape: .lanceolate
    )

    // MARK: - Pro 品种

    static let rose = PlantSpecies(
        id: "rose",
        name: NSLocalizedString("玫瑰", comment: "Rose plant name"),
        nameEn: "Rose",
        symbol: "🌹",
        isPro: true,
        description: NSLocalizedString("经典浪漫，值得用心守护", comment: "Rose description"),
        descriptionEn: "Classic romance, worth protecting with care",
        scientificName: "Rosa hybrida",
        stemColorHex: "#3A7D34",
        flowerColorHex: "#E63946",
        flowerCenterHex: "#A82230",
        petalCount: 16,
        petalShape: .pointed,
        colorTheme: ColorTheme(
            primary: "#E63946",
            secondary: "#FF6B6B",
            dark: "#8B0000"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 3,
            seedlingToMature: 4,
            matureToBlooming: 4,
            bloomingToHarvestable: 3
        ),
        waterNeed: 4,
        difficulty: .medium,
        bloomColor: NSLocalizedString("红色", comment: "Red bloom color"),
        leafShape: .ovate
    )

    static let sakura = PlantSpecies(
        id: "sakura",
        name: NSLocalizedString("樱花", comment: "Sakura plant name"),
        nameEn: "Sakura",
        symbol: "🌸",
        isPro: true,
        description: NSLocalizedString("转瞬即逝的美，且喝且珍惜", comment: "Sakura description"),
        descriptionEn: "Fleeting beauty, cherish every sip",
        scientificName: "Cerasus serrulata",
        stemColorHex: "#6B8E4E",
        flowerColorHex: "#FFB7C5",
        flowerCenterHex: "#E88AA0",
        petalCount: 5,
        petalShape: .cluster,
        colorTheme: ColorTheme(
            primary: "#FFB7C5",
            secondary: "#FFC0CB",
            dark: "#DB7093"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 3,
            seedlingToMature: 3,
            matureToBlooming: 3,
            bloomingToHarvestable: 2
        ),
        waterNeed: 3,
        difficulty: .medium,
        bloomColor: NSLocalizedString("粉色", comment: "Pink bloom color"),
        leafShape: .ovate
    )

    static let tulip = PlantSpecies(
        id: "tulip",
        name: NSLocalizedString("郁金香", comment: "Tulip plant name"),
        nameEn: "Tulip",
        symbol: "🌷",
        isPro: true,
        description: NSLocalizedString("优雅挺立，杯状花冠", comment: "Tulip description"),
        descriptionEn: "Elegant and upright, cup-shaped bloom",
        scientificName: "Tulipa gesneriana",
        stemColorHex: "#4A8A3A",
        flowerColorHex: "#E94B6A",
        flowerCenterHex: "#B8324A",
        petalCount: 6,
        petalShape: .round,
        colorTheme: ColorTheme(
            primary: "#E94B6A",
            secondary: "#FF6B8A",
            dark: "#8B0020"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 2,
            seedlingToMature: 3,
            matureToBlooming: 3,
            bloomingToHarvestable: 2
        ),
        waterNeed: 3,
        difficulty: .medium,
        bloomColor: NSLocalizedString("玫红色", comment: "Rose red bloom color"),
        leafShape: .lanceolate
    )

    static let lavender = PlantSpecies(
        id: "lavender",
        name: NSLocalizedString("薰衣草", comment: "Lavender plant name"),
        nameEn: "Lavender",
        symbol: "💜",
        isPro: true,
        description: NSLocalizedString("宁静安神，紫色的浪漫", comment: "Lavender description"),
        descriptionEn: "Calming serenity, purple romance",
        scientificName: "Lavandula angustifolia",
        stemColorHex: "#5C8A4A",
        flowerColorHex: "#9D7BCC",
        flowerCenterHex: "#7A5DA8",
        petalCount: 12,
        petalShape: .cluster,
        colorTheme: ColorTheme(
            primary: "#9D7BCC",
            secondary: "#BB9EDD",
            dark: "#5A3A8A"
        ),
        growthDays: GrowthDays(
            seedToSprout: 3,
            sproutToSeedling: 3,
            seedlingToMature: 4,
            matureToBlooming: 4,
            bloomingToHarvestable: 3
        ),
        waterNeed: 2,
        difficulty: .medium,
        bloomColor: NSLocalizedString("紫色", comment: "Purple bloom color"),
        leafShape: .lanceolate
    )

    // MARK: - 新增 Pro 专属植物

    static let cherryBlossom = PlantSpecies(
        id: "cherryblossom",
        name: NSLocalizedString("晚樱", comment: "Cherry blossom plant name"),
        nameEn: "Cherry Blossom",
        symbol: "🌸",
        isPro: true,
        description: NSLocalizedString("春季限定，繁花似锦的晚樱", comment: "Cherry blossom description"),
        descriptionEn: "Spring limited, double-flowered cherry blossom",
        scientificName: "Cerasus serrulata 'Kanzan'",
        stemColorHex: "#5D7B3E",
        flowerColorHex: "#FF9FB6",
        flowerCenterHex: "#E67A94",
        petalCount: 20,
        petalShape: .cluster,
        colorTheme: ColorTheme(
            primary: "#FF9FB6",
            secondary: "#FFB7C5",
            dark: "#C96B85"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 3,
            seedlingToMature: 4,
            matureToBlooming: 4,
            bloomingToHarvestable: 3
        ),
        waterNeed: 3,
        difficulty: .medium,
        bloomColor: NSLocalizedString("深粉色", comment: "Deep pink bloom color"),
        leafShape: .ovate
    )

    static let frenchLavender = PlantSpecies(
        id: "frenchlavender",
        name: NSLocalizedString("法国薰衣草", comment: "French lavender plant name"),
        nameEn: "French Lavender",
        symbol: "💜",
        isPro: true,
        description: NSLocalizedString("浓郁芬芳，紫色系的优雅代表", comment: "French lavender description"),
        descriptionEn: "Rich fragrance, elegant purple representative",
        scientificName: "Lavandula stoechas",
        stemColorHex: "#4E7A3D",
        flowerColorHex: "#8B6BC4",
        flowerCenterHex: "#6A4DA0",
        petalCount: 16,
        petalShape: .cluster,
        colorTheme: ColorTheme(
            primary: "#8B6BC4",
            secondary: "#A88BDB",
            dark: "#5A3A8A"
        ),
        growthDays: GrowthDays(
            seedToSprout: 3,
            sproutToSeedling: 4,
            seedlingToMature: 4,
            matureToBlooming: 5,
            bloomingToHarvestable: 3
        ),
        waterNeed: 2,
        difficulty: .hard,
        bloomColor: NSLocalizedString("深紫色", comment: "Deep purple bloom color"),
        leafShape: .lanceolate
    )

    static let lotus = PlantSpecies(
        id: "lotus",
        name: NSLocalizedString("莲花", comment: "Lotus plant name"),
        nameEn: "Lotus",
        symbol: "🪷",
        isPro: true,
        description: NSLocalizedString("出淤泥而不染，水生植物之美", comment: "Lotus description"),
        descriptionEn: "Pure and elegant, beauty of aquatic plants",
        scientificName: "Nelumbo nucifera",
        stemColorHex: "#3D7A2E",
        flowerColorHex: "#F4A7B9",
        flowerCenterHex: "#D4647E",
        petalCount: 18,
        petalShape: .pointed,
        colorTheme: ColorTheme(
            primary: "#F4A7B9",
            secondary: "#FFC0CB",
            dark: "#C96B85"
        ),
        growthDays: GrowthDays(
            seedToSprout: 2,
            sproutToSeedling: 3,
            seedlingToMature: 4,
            matureToBlooming: 5,
            bloomingToHarvestable: 3
        ),
        waterNeed: 5,
        difficulty: .hard,
        bloomColor: NSLocalizedString("粉红色", comment: "Pink bloom color"),
        leafShape: .peltate
    )

    static let bamboo = PlantSpecies(
        id: "bamboo",
        name: NSLocalizedString("竹子", comment: "Bamboo plant name"),
        nameEn: "Bamboo",
        symbol: "🎋",
        isPro: true,
        description: NSLocalizedString("快速生长，坚韧挺拔的君子", comment: "Bamboo description"),
        descriptionEn: "Fast-growing, resilient and upright",
        scientificName: "Bambusa vulgaris",
        stemColorHex: "#4A8A3A",
        flowerColorHex: "#C8E6C9",
        flowerCenterHex: "#81C784",
        petalCount: 6,
        petalShape: .round,
        colorTheme: ColorTheme(
            primary: "#4CAF50",
            secondary: "#81C784",
            dark: "#2E7D32"
        ),
        growthDays: GrowthDays(
            seedToSprout: 1,
            sproutToSeedling: 1,
            seedlingToMature: 2,
            matureToBlooming: 2,
            bloomingToHarvestable: 2
        ),
        waterNeed: 4,
        difficulty: .easy,
        bloomColor: NSLocalizedString("浅绿色", comment: "Light green bloom color"),
        leafShape: .linear
    )

    static let jadePlant = PlantSpecies(
        id: "jadeplant",
        name: NSLocalizedString("玉露", comment: "Jade plant name"),
        nameEn: "Jade Plant",
        symbol: "🌵",
        isPro: true,
        description: NSLocalizedString("晶莹剔透，耐旱型多肉精品", comment: "Jade plant description"),
        descriptionEn: "Crystal clear, premium drought-tolerant succulent",
        scientificName: "Haworthia cooperi",
        stemColorHex: "#5C9A4A",
        flowerColorHex: "#A5D6A7",
        flowerCenterHex: "#66BB6A",
        petalCount: 10,
        petalShape: .fan,
        colorTheme: ColorTheme(
            primary: "#66BB6A",
            secondary: "#A5D6A7",
            dark: "#2E7D32"
        ),
        growthDays: GrowthDays(
            seedToSprout: 3,
            sproutToSeedling: 4,
            seedlingToMature: 5,
            matureToBlooming: 5,
            bloomingToHarvestable: 4
        ),
        waterNeed: 1,
        difficulty: .hard,
        bloomColor: NSLocalizedString("淡绿色", comment: "Light green bloom color"),
        leafShape: .succulent
    )
}
