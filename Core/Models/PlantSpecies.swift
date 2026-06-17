// PlantSpecies.swift
// 植物品种资源库 —— 每个品种定义形态参数，供程序化绘制引擎使用

import SwiftUI

struct PlantSpecies: Identifiable, Codable, Hashable {
    let id: String
    let name: String           // 中文名
    let symbol: String         // 简称（用于花园标签）
    let isPro: Bool            // 是否 Pro 解锁
    let description: String

    // 形态参数（供 PlantCanvas 绘制）
    let stemColorHex: String   // 茎/叶颜色
    let flowerColorHex: String // 花朵颜色
    let flowerCenterHex: String// 花心颜色
    let petalCount: Int        // 花瓣数
    let petalShape: PetalShape // 花瓣形状

    enum PetalShape: String, Codable {
        case round   // 圆瓣（向日葵）
        case pointed // 尖瓣（玫瑰）
        case cluster // 簇状（樱花）
        case fan     // 扇形（多肉）
    }

    // MARK: - 颜色快捷访问（绘制引擎用）

    var stemColor: Color { Color(hex: stemColorHex) }
    var flowerColor: Color { Color(hex: flowerColorHex) }
    var flowerCenterColor: Color { Color(hex: flowerCenterHex) }

    var isFree: Bool { !isPro }
}

// MARK: - 品种库（内置）

enum PlantLibrary {
    /// 免费品种（新用户可选）
    static let free: [PlantSpecies] = [.sunflower, .succulent, .mint]

    /// Pro 解锁品种
    static let pro: [PlantSpecies] = [.rose, .sakura, .tulip, .lavender]

    /// 全部品种
    static let all: [PlantSpecies] = free + pro

    /// 按 id 查找
    static func species(id: String) -> PlantSpecies {
        all.first { $0.id == id } ?? .sunflower
    }
}

extension PlantSpecies {
    /// 向日葵（默认首株，免费）—— 先用它打通绘制全链路
    static let sunflower = PlantSpecies(
        id: "sunflower",
        name: "向日葵",
        symbol: "🌻",
        isPro: false,
        description: "向阳而生，你的第一株伙伴",
        stemColorHex: "#3D8A2E",
        flowerColorHex: "#F5B82E",
        flowerCenterHex: "#7A4A1A",
        petalCount: 14,
        petalShape: .pointed
    )

    static let succulent = PlantSpecies(
        id: "succulent",
        name: "多肉",
        symbol: "🪴",
        isPro: false,
        description: "憨态可掬，坚韧又可爱",
        stemColorHex: "#5C9A4A",
        flowerColorHex: "#E88BA0",
        flowerCenterHex: "#D4647E",
        petalCount: 8,
        petalShape: .fan
    )

    static let mint = PlantSpecies(
        id: "mint",
        name: "薄荷",
        symbol: "🌿",
        isPro: false,
        description: "清新提神，越喝越精神",
        stemColorHex: "#4FAE5C",
        flowerColorHex: "#C8A8E8",
        flowerCenterHex: "#9A7BC4",
        petalCount: 10,
        petalShape: .round
    )

    // MARK: - Pro 品种

    static let rose = PlantSpecies(
        id: "rose",
        name: "玫瑰",
        symbol: "🌹",
        isPro: true,
        description: "经典浪漫，值得用心守护",
        stemColorHex: "#3A7D34",
        flowerColorHex: "#E63946",
        flowerCenterHex: "#A82230",
        petalCount: 16,
        petalShape: .pointed
    )

    static let sakura = PlantSpecies(
        id: "sakura",
        name: "樱花",
        symbol: "🌸",
        isPro: true,
        description: "转瞬即逝的美，且喝且珍惜",
        stemColorHex: "#6B8E4E",
        flowerColorHex: "#FFB7C5",
        flowerCenterHex: "#E88AA0",
        petalCount: 5,
        petalShape: .cluster
    )

    static let tulip = PlantSpecies(
        id: "tulip",
        name: "郁金香",
        symbol: "🌷",
        isPro: true,
        description: "优雅挺立，杯状花冠",
        stemColorHex: "#4A8A3A",
        flowerColorHex: "#E94B6A",
        flowerCenterHex: "#B8324A",
        petalCount: 6,
        petalShape: .round
    )

    static let lavender = PlantSpecies(
        id: "lavender",
        name: "薰衣草",
        symbol: "💜",
        isPro: true,
        description: "宁静安神，紫色的浪漫",
        stemColorHex: "#5C8A4A",
        flowerColorHex: "#9D7BCC",
        flowerCenterHex: "#7A5DA8",
        petalCount: 12,
        petalShape: .cluster
    )
}
