// PlantView.swift
// 植物视图 —— 包装 PlantCanvas，加上摇摆动画和平滑过渡
//
// TimelineView 驱动 time 参数，让健康时植物轻轻摇摆，蔫了静止。
// 健康度/阶段变化用 withAnimation 平滑过渡（由外部触发）。

import SwiftUI

@MainActor
final class PlantImageCache {
    static let shared = PlantImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let maxCacheSize = 50
    
    private init() {
        cache.countLimit = maxCacheSize
    }
    
    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
}

struct PlantView: View {
    let plant: Plant
    var animationPhase: Double = 0

    var body: some View {
        let state = PlantVisualState(plant: plant, time: animationPhase)
        PlantCanvas(state: state)
            .scaleEffect(plant.health > 80 ? 1.0 : 0.97)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: plant.health)
    }
}

struct CachedPlantView: View {
    let plant: Plant
    let size: CGSize
    
    @State private var cachedImage: UIImage?
    @State private var isAnimating = false
    
    private var cacheKey: String {
        "\(plant.speciesID)_\(plant.stage.rawValue)_\(Int(plant.health))_\(Int(size.width))x\(Int(size.height))"
    }
    
    var body: some View {
        ZStack {
            if let image = cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeIn(duration: 0.2), value: isAnimating)
            } else {
                PlantView(plant: plant)
            }
        }
        .onAppear {
            loadCachedImage()
        }
        .onChange(of: plant.stage) { _, _ in
            loadCachedImage()
        }
        .onChange(of: plant.health) { _, _ in
            loadCachedImage()
        }
    }
    
    private func loadCachedImage() {
        let key = cacheKey
        
        if let cached = PlantImageCache.shared.image(for: key) {
            cachedImage = cached
            withAnimation { isAnimating = true }
            return
        }
        
        Task {
            let image = await renderPlant()
            await MainActor.run {
                PlantImageCache.shared.setImage(image, for: key)
                cachedImage = image
                withAnimation { isAnimating = true }
            }
        }
    }
    
    private func renderPlant() async -> UIImage {
        await MainActor.run {
            let renderer = ImageRenderer(content: PlantView(plant: plant).frame(width: size.width, height: size.height))
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage ?? UIImage()
        }
    }
}

/// 带自动摇摆动画的植物视图（用于主界面）
struct AnimatedPlantView: View {
    let plant: Plant

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            PlantView(plant: plant, animationPhase: timeline.date.timeIntervalSinceReferenceDate)
        }
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
