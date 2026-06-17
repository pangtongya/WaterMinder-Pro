// PlantVisualState.swift
// 绘制引擎的输入 —— 把植物状态打包成 Canvas 需要的形态描述
//
// 设计：把"健康度/成长阶段"等业务状态，转换成绘制参数
// （茎高、叶数、花大小、颜色饱和度、下垂角度、摇摆幅度），
// 让 Canvas 只关心怎么画，不关心业务逻辑。

import SwiftUI

struct PlantVisualState {
    let species: PlantSpecies
    let stage: GrowthStage
    let health: Double        // 0–100
    let time: Double          // 用于摇摆动画（时间戳）

    // MARK: - 派生绘制参数

    /// 茎的相对高度（0–1）
    var stemRatio: Double { stage.stemRatio }

    /// 叶片数量
    var leafCount: Int { stage.leafCount }

    /// 是否开花
    var hasFlower: Bool { stage.hasFlower }

    /// 颜色饱和度（健康度低 → 灰绿/枯黄）
    /// health 100 → 1.0，health 0 → 0.35
    var saturation: Double {
        0.35 + (health / 100.0) * 0.65
    }

    /// 叶子下垂角度（弧度），健康度低 → 下垂更厉害
    /// health 100 → 0，health 0 → 0.5（约28°）
    var droopAngle: Double {
        (1.0 - health / 100.0) * 0.5
    }

    /// 摇摆幅度（健康时摇摆，蔫了不动）
    var swayAmplitude: Double {
        (health / 100.0) * 0.04
    }

    /// 花朵大小比例（0–1，随阶段绽放）
    var flowerSize: Double {
        switch stage {
        case .blooming:    return 0.7
        case .harvestable: return 1.0
        default:           return 0
        }
    }

    /// 叶子亮度偏移（健康时鲜亮，蔫了暗淡）
    var leafBrightness: Double {
        0.6 + (health / 100.0) * 0.4
    }

    // MARK: - 便捷构造

    init(plant: Plant, time: Double = 0) {
        self.species = plant.species
        self.stage = plant.stage
        self.health = plant.health
        self.time = time
    }

    init(species: PlantSpecies, stage: GrowthStage, health: Double, time: Double = 0) {
        self.species = species
        self.stage = stage
        self.health = health
        self.time = time
    }
}
