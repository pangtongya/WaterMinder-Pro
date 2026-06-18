// PlantView.swift
// 植物视图 —— 包装 PlantCanvas，加上摇摆动画和平滑过渡
//
// TimelineView 驱动 time 参数，让健康时植物轻轻摇摆，蔫了静止。
// 健康度/阶段变化用 withAnimation 平滑过渡（由外部触发）。

import SwiftUI

struct PlantView: View {
    let plant: Plant
    var animationPhase: Double = 0   // 由 TimelineView 注入

    var body: some View {
        // 用当前 phase 作为摇摆时间
        let state = PlantVisualState(plant: plant, time: animationPhase)
        PlantCanvas(state: state)
            // 健康度变化时整体有轻微缩放反馈
            .scaleEffect(plant.health > 80 ? 1.0 : 0.97)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: plant.health)
    }
}

/// 带自动摇摆动画的植物视图（用于主界面）
struct AnimatedPlantView: View {
    let plant: Plant

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            PlantView(plant: plant, animationPhase: timeline.date.timeIntervalSinceReferenceDate)
        }
    }
}

// #Preview {
//     VStack(spacing: 40) {
//         AnimatedPlantView(plant: Plant(name: "小绿", stage: .harvestable, health: 90))
//             .frame(width: 200, height: 280)
//         AnimatedPlantView(plant: Plant(name: "蔫蔫", stage: .mature, health: 25))
//             .frame(width: 200, height: 280)
//     }
//     .padding()
// }
