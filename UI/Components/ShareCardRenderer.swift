// ShareCardRenderer.swift
// 分享卡片渲染器 —— 使用 SwiftUI ImageRenderer 将植物状态卡片渲染为 UIImage

import SwiftUI
import UIKit

// MARK: - 分享卡片视图

/// 植物收获分享卡片视图（4:5 比例，适合社交媒体分享）
struct HarvestShareCardView: View {
    let plant: Plant

    var body: some View {
        ZStack {
            // 渐变背景：bloomPrimary 浅色到白色
            LinearGradient(
                colors: [
                    Color.bloomPrimary.opacity(0.18),
                    Color.bloomPrimary.opacity(0.06),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // 顶部品牌
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)
                    Text("Bloom")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.bloomTextPrimary)
                }

                Spacer().frame(height: 28)

                // 植物阶段 emoji + 光晕
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.bloomGold.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 110
                            )
                        )
                        .frame(width: 200, height: 200)

                    Text(plant.stage.emoji)
                        .font(.system(size: 96))
                }

                Spacer().frame(height: 20)

                // 植物名称
                Text(plant.name)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.bloomTextPrimary)
                    .multilineTextAlignment(.center)

                // 种类 · 阶段
                HStack(spacing: 6) {
                    Text(plant.species.localizedName)
                    Text("·")
                    Text(plant.stage.name)
                }
                .font(.system(size: 18))
                .foregroundStyle(Color.bloomTextSecondary)
                .padding(.top, 6)

                Spacer().frame(height: 32)

                // 统计信息卡
                HStack(spacing: 0) {
                    statBlock(
                        value: "\(Int(plant.health))%",
                        label: L.health,
                        color: Color.healthColor(plant.health)
                    )

                    Divider()
                        .frame(height: 44)
                        .background(Color.bloomDivider)

                    statBlock(
                        value: "\(plant.ageInDays)",
                        label: L.daysCared,
                        color: Color.bloomWater
                    )
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.bloomSurface)
                        .shadow(color: Color.bloomPrimary.opacity(0.08), radius: 12, x: 0, y: 6)
                )

                Spacer()

                // 底部品牌 tagline
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomGold)
                    Text(L.shareCardTagline)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 40)
            .padding(.top, 44)
            .padding(.bottom, 32)
        }
    }

    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.bloomTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 渲染器

/// 使用 ImageRenderer API 将分享卡片视图渲染为 UIImage
enum ShareCardRenderer {
    /// 渲染植物收获分享卡片
    /// - Parameter plant: 当前植物
    /// - Returns: 渲染后的 UIImage（4:5 比例，1080×1350 像素）
    @MainActor
    static func renderHarvestCard(plant: Plant) -> UIImage? {
        let cardView = HarvestShareCardView(plant: plant)
            .frame(width: 540, height: 675)
            // 分享卡片固定使用浅色模式，保证明亮、色彩鲜艳
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
