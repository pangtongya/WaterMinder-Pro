// HarvestView.swift
// 收获植物视图 - 庆祝植物成熟并保存到收藏

import SwiftUI

struct HarvestView: View {
    let plant: Plant
    let onHarvest: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showCelebration = false
    @State private var plantScale: CGFloat = 0.8
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color.bloomPrimary.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 庆祝粒子动画
                if showCelebration {
                    CelebrationParticles()
                }
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // 真实植物视觉（替代 emoji）
                    AnimatedPlantView(plant: plant)
                        .frame(height: 220)
                        .scaleEffect(plantScale)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: plantScale)
                    
                    // 标题
                    VStack(spacing: 6) {
                        Text(String(format: L.plantMatured, plant.name))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(L.congratulations + " " + String(format: L.reachedStageMsg, plant.stage.name))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                    // 植物信息卡片
                    VStack(spacing: 12) {
                        infoRow(label: L.species, value: plant.species.localizedName)
                        Divider()
                        infoRow(label: L.stage, value: plant.stage.name)
                        Divider()
                        infoRow(label: L.health, value: "\(Int(plant.health))%")
                        Divider()
                        infoRow(label: L.daysCared, value: String(format: L.daysN, plant.ageInDays))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 收获按钮
                    Button {
                        onHarvest()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                            Text(L.harvestAndSave)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.bloomPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .navigationTitle(L.harvestPlantTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            plantScale = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCelebration = true
            }
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.system(size: 15))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .font(.system(size: 15))
        }
    }
}

// MARK: - 庆祝粒子动画

struct CelebrationParticles: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(particleColor(i))
                    .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: animate ? CGFloat.random(in: -50...200) : geo.size.height + 50
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 1.5...2.5))
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
    
    private func particleColor(_ index: Int) -> Color {
        let colors: [Color] = [.bloomPrimary, .bloomGold, .bloomSuccess, .pink, .orange, .yellow]
        return colors[index % colors.count].opacity(Double.random(in: 0.6...0.9))
    }
}
