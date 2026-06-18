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
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            PlantView(plant: plant, animationPhase: timeline.date.timeIntervalSinceReferenceDate)
        }
        // drawingGroup() 将视图合成为单一图层，减少重绘次数
        .drawingGroup()
    }
}

#Preview {
    AnimatedPlantView(plant: Plant(stage: .sprout, health: 85))
        .frame(width: 300, height: 300)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Seedling") {
    AnimatedPlantView(plant: Plant(stage: .seedling, health: 55))
        .frame(width: 300, height: 300)
        .padding()
        .background(Color(.systemBackground))
}
