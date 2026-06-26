// HarvestView.swift
// 收获植物视图 - 庆祝植物成熟并保存到收藏

import SwiftUI

struct HarvestView: View {
    let plant: Plant
    let onHarvest: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showCelebration = false
    @State private var plantScale: CGFloat = 0.8
    @State private var isSharing = false
    @State private var shareImage: UIImage?
    @State private var showConfetti = false
    @State private var showSparkles = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.bloomPrimary.opacity(0.08),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
                
                if showSparkles {
                    SparkleView()
                        .allowsHitTesting(false)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 8)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.bloomGold.opacity(0.3), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 120
                                    )
                                )
                                .frame(width: 240, height: 240)
                                .scaleEffect(showCelebration ? 1.0 : 0.5)
                                .opacity(showCelebration ? 1 : 0)
                            
                            AnimatedPlantView(plant: plant)
                                .frame(height: 220)
                                .scaleEffect(plantScale)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: plantScale)
                        }
                        
                        VStack(spacing: 8) {
                            Text(String(format: L.plantMatured, plant.name))
                                .font(.title)
                                .fontWeight(.bold)
                            Text(L.congratulations + " " + String(format: L.reachedStageMsg, plant.stage.name))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.bloomGold)
                            Text(L.addedToCollectionHint)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.bloomGold.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)
                        
                        growthStatsCard
                            .padding(.horizontal, 20)
                        
                        shareButton
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 8)
                        
                        harvestButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
                .scrollIndicators(.hidden)
                .navigationTitle(L.harvestPlantTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $isSharing) {
            if let shareImage {
                ActivityViewController(activityItems: [shareImage])
            }
        }
        .onAppear {
            plantScale = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    showCelebration = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
                showSparkles = true
            }
        }
    }
    
    private var growthStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.bloomPrimary)
                Text(L.growthData)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            
            HStack(spacing: 12) {
                growthStatItem(
                    icon: "calendar",
                    value: "\(plant.ageInDays)",
                    label: L.daysCared,
                    color: .bloomPrimary
                )
                Divider().frame(height: 50)
                growthStatItem(
                    icon: "drop.fill",
                    value: "—",
                    label: L.totalWaterAmount,
                    color: .bloomWater
                )
                Divider().frame(height: 50)
                growthStatItem(
                    icon: "heart.fill",
                    value: "\(Int(plant.health))%",
                    label: L.peakHealth,
                    color: .bloomSuccess
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func growthStatItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var shareButton: some View {
        Button {
            shareHarvest()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                Text(L.shareHarvest)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.bloomPrimary.opacity(0.3), lineWidth: 1.5)
                    .background(Color.bloomPrimary.opacity(0.08))
            )
            .foregroundColor(.bloomPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    private var harvestButton: some View {
        Button {
            Haptics.success()
            onHarvest()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                Text(L.harvestAndSave)
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.bloomGold, Color.bloomPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.bloomPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(HarvestButtonStyle())
    }
    
    // TODO: 分享功能需要从外部传入 WaterStore 和 AchievementStore 实例
    // 目前使用 placeholder，实际使用时请通过环境对象或参数传入
    private func shareHarvest() {
        isSharing = true
        Task {
            // TODO: 修复分享卡片生成 - 需要从外部获取 store 实例
            // 临时使用默认值，避免编译错误
            await MainActor.run {
                shareImage = UIImage(systemName: "sparkles")
                isSharing = false
            }
        }
    }
}

struct HarvestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - 五彩纸屑动画

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                confettiPiece(at: i, in: geo.size)
            }
        }
        .onAppear { animate = true }
    }
    
    private func confettiPiece(at index: Int, in size: CGSize) -> some View {
        let colors: [Color] = [.bloomPrimary, .bloomGold, .bloomSuccess, .pink, .orange, .yellow, .purple, .red]
        let color = colors[index % colors.count]
        let size = CGFloat.random(in: 6...12)
        let delay = Double(index) * 0.05
        
        return Rectangle()
            .fill(color)
            .frame(width: size, height: size * CGFloat.random(in: 0.6...1.4))
            .rotationEffect(.degrees(animate ? Double.random(in: 0...720) : 0))
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: animate ? UIScreen.main.bounds.height + 50 : -50
            )
            .opacity(animate ? 0 : 1)
            .animation(
                Animation.easeOut(duration: Double.random(in: 2.0...3.5))
                    .delay(delay)
                    .repeatForever(autoreverses: false),
                value: animate
            )
    }
}

// MARK: - 闪光效果

struct SparkleView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<15, id: \.self) { i in
                sparkle(at: i, in: geo.size)
            }
        }
        .onAppear { animate = true }
    }
    
    private func sparkle(at index: Int, in size: CGSize) -> some View {
        let delay = Double(index) * 0.15
        let size = CGFloat.random(in: 8...16)
        
        return Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color.bloomGold)
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 100...400)
            )
            .scaleEffect(animate ? 1.2 : 0.3)
            .opacity(animate ? 0 : 0.8)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .delay(delay)
                    .repeatForever(autoreverses: false),
                value: animate
            )
    }
}

// MARK: - 庆祝粒子动画（保留原有）

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
