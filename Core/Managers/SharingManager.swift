// SharingManager.swift
// 社交分享管理器 —— 生成漂亮的植物状态分享卡片

import Foundation
import SwiftUI
import UIKit

@MainActor
final class SharingManager: ObservableObject {
    static let shared = SharingManager()
    
    private init() {}
    
    // MARK: - 成就系统集成
    
    var achievementStore: AchievementStore?
    
    /// 记录分享并更新成就
    func recordShare() {
        achievementStore?.updateSocialProgress(totalShares: 1)
    }
    
    // MARK: - 生成分享图片
    
    /// 生成植物状态分享卡片
    func generatePlantShareCard(
        plant: Plant,
        waterStore: WaterStore,
        achievementStore: AchievementStore
    ) async -> UIImage {
        let shareData = PlantShareData(
            plantName: plant.name,
            plantSymbol: plant.species.symbol,
            plantStage: plant.stage.name,
            health: plant.health,
            todayIntake: waterStore.todayTotal,
            dailyGoal: waterStore.dailyGoal,
            achievements: achievementStore.unlockedCount,
            totalRecords: waterStore.records.count,
            totalAmount: waterStore.records.reduce(0) { $0 + $1.amount }
        )
        
        let view = SharePlantCardView(data: shareData)
        return await renderToImage(view: view, size: CGSize(width: 1080, height: 1350))
    }
    
    /// 生成成就分享卡片
    func generateAchievementCard(achievement: Achievement) async -> UIImage {
        let view = ShareAchievementCardView(achievement: achievement)
        return await renderToImage(view: view, size: CGSize(width: 1080, height: 1080))
    }
    
    // MARK: - 渲染为图片
    
    private func renderToImage<V: View>(view: V, size: CGSize) async -> UIImage {
        let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))

        // 强制使用浅色模式渲染（分享卡片无论系统什么主题都应该是明亮、色彩鲜艳的）
        controller.view.overrideUserInterfaceStyle = .light

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIImage()
        }

        window.addSubview(controller.view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }

        controller.view.removeFromSuperview()
        return image
    }
    
    // MARK: - 分享
    
    /// 分享图片
    func shareImage(_ image: UIImage, from viewController: UIViewController?) {
        guard let vc = viewController ?? topViewController() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // iPad 支持
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = vc.view
            popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        vc.present(activityVC, animated: true)
    }
    
    /// 分享成就（自动生成卡片并分享）
    func shareAchievement(_ achievement: Achievement, from viewController: UIViewController? = nil) {
        Task {
            let image = await generateAchievementCard(achievement: achievement)
            shareImage(image, from: viewController)
        }
    }
    
    // MARK: - Helper
    
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}

// MARK: - 分享数据

struct PlantShareData {
    let plantName: String
    let plantSymbol: String
    let plantStage: String
    let health: Double
    let todayIntake: Int
    let dailyGoal: Int
    let achievements: Int
    let totalRecords: Int
    let totalAmount: Int
}

// MARK: - 分享卡片视图

struct SharePlantCardView: View {
    let data: PlantShareData
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [Color.bloomPrimary.opacity(0.8), Color.bloomWater.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 标题
                Text("Bloom")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                // 植物图标
                Text(data.plantSymbol)
                    .font(.system(size: 120))
                
                // 植物信息
                VStack(spacing: 16) {
                    Text(data.plantName)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(data.plantStage)
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // 健康度
                VStack(spacing: 12) {
                    Text(L.health)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(Int(data.health))%")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding()
                
                // 今日进度
                HStack(spacing: 40) {
                    StatItem(label: NSLocalizedString("今日喝水", comment: "Today's water intake"),
                             value: "\(data.todayIntake)ml")
                    StatItem(label: NSLocalizedString("目标", comment: "Goal"),
                             value: "\(data.dailyGoal)ml")
                }
                
                // 统计信息
                HStack(spacing: 40) {
                    StatItem(label: NSLocalizedString("总次数", comment: "Total records"),
                             value: "\(data.totalRecords)")
                    StatItem(label: NSLocalizedString("总水量", comment: "Total amount"),
                             value: "\(data.totalAmount / 1000)L")
                }
                
                Spacer()
                
                // 底部标识
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                    Text(L.bloomTagline)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(60)
        }
    }
}

struct ShareAchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bloomGold, Color.bloomPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 图标
                Image(systemName: achievement.icon)
                    .font(.system(size: 120))
                    .foregroundColor(.white)
                
                // 成就信息
                VStack(spacing: 20) {
                    Text(L.achievementUnlocked)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(achievement.title)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                    Text(L.bloomTagline)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(60)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
