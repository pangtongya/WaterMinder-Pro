// BloomWidget.swift
// Bloom Widget —— 显示喝水进度和植物状态
// 支持：小(2x2)、中(4x2)、大(4x4) 三种尺寸

import WidgetKit
import SwiftUI

// MARK: - Widget 本地常量（Widget Extension 无法访问主 App 的 AppConstants）

enum WidgetConstants {
    static let appGroupIdentifier = "group.com.pangtong.bloom"
    static let widgetKind = "BloomWidget"

    enum WidgetKeys {
        static let todayIntake = "widget.todayIntake"
        static let dailyGoal = "widget.dailyGoal"
        static let plantName = "widget.plantName"
        static let plantHealth = "widget.plantHealth"
        static let plantStage = "widget.plantStage"
        static let plantSymbol = "widget.plantSymbol"
        static let isPaused = "widget.isPaused"
        static let lastUpdated = "widget.lastUpdated"
        static let dataDate = "widget.dataDate"
    }
}

// MARK: - Widget 本地化字符串

enum WidgetL {
    static let plantHealth = NSLocalizedString("Plant Health", comment: "Widget plant health label")
    static let status = NSLocalizedString("Status", comment: "Widget status label")
    static let updatedAt = NSLocalizedString("Updated at", comment: "Widget updated at")
    static let pauseCare = NSLocalizedString("Paused", comment: "Widget pause label")
    static let pauseCareFull = NSLocalizedString("Pause Care", comment: "Widget full pause label")
    static let ml = NSLocalizedString("ml", comment: "Milliliters abbreviation")
    static let bloomWidgetName = NSLocalizedString("Bloom Progress", comment: "Widget name")
    static let bloomWidgetDesc = NSLocalizedString("View your hydration progress and plant status", comment: "Widget description")
    static let noData = NSLocalizedString("No Data", comment: "No data available")
}

// MARK: - Widget 植物视觉组件（内联，避免修改 pbxproj）

/// 极简版植物绘制 — 专为 Widget 设计
/// 通过阶段和健康度决定植物外观，不依赖主 App 的复杂绘制逻辑
struct WidgetPlantView: View {
    let stage: String      // "Seed" / "Sprout" / "Growing" / "Blooming" / "Mature"
    let health: Double     // 0 - 100
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 背景光晕（根据健康度）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.healthColor(health).opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
            
            // 植物主体
            plantBody
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    private var plantBody: some View {
        switch stage.lowercased() {
        case "seed":
            SeedPlant(size: size, color: Color.healthColor(health))
        case "sprout":
            SproutPlant(size: size, color: Color.healthColor(health))
        case "growing":
            GrowingPlant(size: size, color: Color.healthColor(health))
        case "blooming":
            BloomingPlant(size: size, color: Color.healthColor(health), hasFlower: false)
        case "mature":
            BloomingPlant(size: size, color: Color.healthColor(health), hasFlower: true)
        default:
            SeedPlant(size: size, color: Color.healthColor(health))
        }
    }
}

/// 🌰 种子阶段：土堆 + 小嫩芽
struct SeedPlant: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: w * 0.15, y: h * 0.75))
                    path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.75),
                                    control: CGPoint(x: w * 0.5, y: h * 0.85))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.9))
                    path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.9))
                    path.closeSubpath()
                }
                .fill(Color.brown.opacity(0.3))
                
                Circle()
                    .fill(color)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .offset(y: size * 0.02)
            }
        }
    }
}

/// 🌱 发芽阶段：小茎 + 两片叶子
struct SproutPlant: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let centerX = geo.size.width * 0.5
                    path.move(to: CGPoint(x: centerX, y: geo.size.height * 0.8))
                    path.addLine(to: CGPoint(x: centerX, y: geo.size.height * 0.45))
                }
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.28, height: size * 0.18)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -size * 0.15, y: -size * 0.05)
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.28, height: size * 0.18)
                    .rotationEffect(.degrees(35))
                    .offset(x: size * 0.15, y: -size * 0.05)
                
                Circle()
                    .fill(color)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(y: -size * 0.1)
            }
        }
    }
}

/// 🌿 成长阶段：较长的茎 + 更多叶子
struct GrowingPlant: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let centerX = geo.size.width * 0.5
                    path.move(to: CGPoint(x: centerX, y: geo.size.height * 0.85))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX, y: geo.size.height * 0.25),
                        control: CGPoint(x: centerX + size * 0.03, y: geo.size.height * 0.55)
                    )
                }
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round))
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.32, height: size * 0.22)
                    .rotationEffect(.degrees(-40))
                    .offset(x: -size * 0.18, y: size * 0.15)
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.32, height: size * 0.22)
                    .rotationEffect(.degrees(40))
                    .offset(x: size * 0.18, y: size * 0.15)
                
                Ellipse()
                    .fill(color.opacity(0.9))
                    .frame(width: size * 0.26, height: size * 0.18)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -size * 0.15, y: -size * 0.02)
                
                Ellipse()
                    .fill(color.opacity(0.9))
                    .frame(width: size * 0.26, height: size * 0.18)
                    .rotationEffect(.degrees(30))
                    .offset(x: size * 0.15, y: -size * 0.02)
                
                Circle()
                    .fill(color)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(y: -size * 0.18)
            }
        }
    }
}

/// 🌸 开花/成熟阶段：完整的植物 + 花朵
struct BloomingPlant: View {
    let size: CGFloat
    let color: Color
    let hasFlower: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let centerX = geo.size.width * 0.5
                    path.move(to: CGPoint(x: centerX, y: geo.size.height * 0.9))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX, y: geo.size.height * 0.2),
                        control: CGPoint(x: centerX + size * 0.04, y: geo.size.height * 0.55)
                    )
                }
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round))
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.34, height: size * 0.24)
                    .rotationEffect(.degrees(-45))
                    .offset(x: -size * 0.2, y: size * 0.2)
                
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.34, height: size * 0.24)
                    .rotationEffect(.degrees(45))
                    .offset(x: size * 0.2, y: size * 0.2)
                
                Ellipse()
                    .fill(color.opacity(0.9))
                    .frame(width: size * 0.28, height: size * 0.2)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -size * 0.17, y: size * 0.02)
                
                Ellipse()
                    .fill(color.opacity(0.9))
                    .frame(width: size * 0.28, height: size * 0.2)
                    .rotationEffect(.degrees(30))
                    .offset(x: size * 0.17, y: size * 0.02)
                
                if hasFlower {
                    ZStack {
                        ForEach(0..<5, id: \.self) { i in
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.7, blue: 0.85),
                                            Color(red: 1.0, green: 0.55, blue: 0.75)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: size * 0.22, height: size * 0.32)
                                .offset(y: -size * 0.12)
                                .rotationEffect(.degrees(Double(i) * 72))
                        }
                        Circle()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.2))
                            .frame(width: size * 0.15, height: size * 0.15)
                    }
                    .offset(y: -size * 0.3)
                } else {
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.75, blue: 0.88),
                                            Color(red: 1.0, green: 0.6, blue: 0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: size * 0.15, height: size * 0.22)
                                .offset(y: -size * 0.08)
                                .rotationEffect(.degrees(Double(i - 1) * 30))
                        }
                        Circle()
                            .fill(color)
                            .frame(width: size * 0.1, height: size * 0.1)
                    }
                    .offset(y: -size * 0.28)
                }
            }
        }
    }
}

// MARK: - Widget 数据模型

struct WidgetData: Codable {
    let currentIntake: Int
    let dailyGoal: Int
    let plantName: String
    let plantHealth: Double
    let plantStage: String
    let plantSymbol: String
    let isPaused: Bool
    let lastUpdated: Date
    let dataDate: String
    
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(currentIntake) / Double(dailyGoal))
    }
    
    /// 检查数据是否为今日的（防止设备时钟偏移导致显示错误日期）
    var isDataForToday: Bool {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date()) == dataDate
    }
    
    var healthEmoji: String {
        switch plantHealth {
        case 80...100: return "🌿"
        case 60..<80: return "🌱"
        case 40..<60: return "🌾"
        case 20..<40: return "😟"
        default: return "🥀"
        }
    }
    
    /// 健康度对应的颜色（供进度条和图标着色）
    var healthDisplayColor: Color {
        Color.healthColor(plantHealth)
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return SimpleEntry(
            date: Date(),
            data: WidgetData(
                currentIntake: 1500,
                dailyGoal: 2000,
                plantName: "Plant",
                plantHealth: 75.0,
                plantStage: "Growing",
                plantSymbol: "🌱",
                isPaused: false,
                lastUpdated: Date(),
                dataDate: df.string(from: Date())
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let data = loadWidgetData()
        let entry = SimpleEntry(date: Date(), data: data)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let data = loadWidgetData()
        let entry = SimpleEntry(date: Date(), data: data)
        
        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadWidgetData() -> WidgetData {
        // 从共享 App Group 读取数据
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayString = df.string(from: Date())
        
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupIdentifier) else {
            return WidgetData(
                currentIntake: 0,
                dailyGoal: 2000,
                plantName: "Bloom",
                plantHealth: 50.0,
                plantStage: "Seed",
                plantSymbol: "🌰",
                isPaused: false,
                lastUpdated: Date(),
                dataDate: todayString
            )
        }
        
        let currentIntake = defaults.integer(forKey: WidgetConstants.WidgetKeys.todayIntake)
        let dailyGoal = defaults.integer(forKey: WidgetConstants.WidgetKeys.dailyGoal)
        let plantName = defaults.string(forKey: WidgetConstants.WidgetKeys.plantName) ?? "Plant"
        let plantHealth = defaults.double(forKey: WidgetConstants.WidgetKeys.plantHealth)
        let plantStage = defaults.string(forKey: WidgetConstants.WidgetKeys.plantStage) ?? "Seed"
        let plantSymbol = defaults.string(forKey: WidgetConstants.WidgetKeys.plantSymbol) ?? "🌰"
        let isPaused = defaults.bool(forKey: WidgetConstants.WidgetKeys.isPaused)
        let dataDate = defaults.string(forKey: WidgetConstants.WidgetKeys.dataDate) ?? todayString
        
        return WidgetData(
            currentIntake: currentIntake,
            dailyGoal: dailyGoal > 0 ? dailyGoal : 2000,
            plantName: plantName,
            plantHealth: plantHealth > 0 ? plantHealth : 50.0,
            plantStage: plantStage,
            plantSymbol: plantSymbol,
            isPaused: isPaused,
            lastUpdated: Date(),
            dataDate: dataDate
        )
    }
}

// MARK: - Widget View

struct BloomWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - 小尺寸 Widget (2x2)

struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 10) {
            // 真实植物视觉（左侧）
            WidgetPlantView(stage: data.plantStage, health: data.plantHealth, size: 70)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.plantName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(data.plantStage)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 进度条
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.bloomPrimary, .bloomGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50 * data.progressPercentage, height: 6)
                }
                
                HStack(spacing: 3) {
                    Text("\(data.currentIntake)")
                        .font(.system(size: 11, weight: .bold))
                    Text("/ \(data.dailyGoal)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                if data.isPaused {
                    Label(WidgetL.pauseCare, systemImage: "pause.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - 中尺寸 Widget (4x2)

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：真实植物视觉
            WidgetPlantView(stage: data.plantStage, health: data.plantHealth, size: 100)
            
            // 中间：文字信息
            VStack(alignment: .leading, spacing: 6) {
                Text(data.plantName)
                    .font(.system(size: 15, weight: .semibold))
                Text(data.plantStage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                if data.isPaused {
                    Label(WidgetL.pauseCareFull, systemImage: "pause.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
                
                HStack(spacing: 12) {
                    Label("\(Int(data.plantHealth))%", systemImage: "leaf.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.healthColor(data.plantHealth))
                    
                    Spacer()
                    
                    Text(data.lastUpdated, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧：进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: data.progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [.bloomPrimary, .bloomGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(data.currentIntake)")
                        .font(.system(size: 24, weight: .bold))
                    Text(WidgetL.ml)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 90, height: 90)
        }
        .padding()
    }
}

// MARK: - 大尺寸 Widget (4x4)

struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部：真实植物视觉 + 文字
            HStack {
                WidgetPlantView(stage: data.plantStage, health: data.plantHealth, size: 130)
                    .padding(.leading, -6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.plantName)
                        .font(.system(size: 18, weight: .semibold))
                    Text(data.plantStage)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%@ %@", WidgetL.updatedAt, DateFormatter.localizedString(from: data.lastUpdated, dateStyle: .none, timeStyle: .short)))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                if data.isPaused {
                    Label(WidgetL.pauseCare, systemImage: "pause.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
            }
            
            // 中间：大进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                
                Circle()
                    .trim(from: 0, to: data.progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [.bloomPrimary, .bloomGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(data.currentIntake)")
                        .font(.system(size: 36, weight: .bold))
                    Text("/ \(data.dailyGoal)ml")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("\(Int(data.progressPercentage * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.bloomPrimary)
                }
            }
            .frame(width: 140, height: 140)
            
            // 底部：健康度显示
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(WidgetL.plantHealth)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Text("\(Int(data.plantHealth))%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.healthColor(data.plantHealth))
                        // 小型健康度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.healthColor(data.plantHealth))
                                .frame(width: 50 * CGFloat(data.plantHealth / 100), height: 6)
                        }
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Widget 定义

struct BloomWidget: Widget {
    let kind: String = "BloomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BloomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(WidgetL.bloomWidgetName)
        .description(WidgetL.bloomWidgetDesc)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget 颜色扩展（与主 App 颜色保持一致）

extension Color {
    static let bloomPrimary = Color(red: 0.25, green: 0.75, blue: 0.55)
    static let bloomGold = Color(red: 1.0, green: 0.85, blue: 0.2)
    static let bloomDeep = Color(red: 0.15, green: 0.6, blue: 0.45)
    static let bloomSuccess = Color(red: 0.3, green: 0.7, blue: 0.5)
    
    /// 根据健康度返回对应颜色（绿色 -> 黄褐 -> 枯褐）
    static func healthColor(_ health: Double) -> Color {
        switch health {
        case 80...100: return Color(red: 0.25, green: 0.75, blue: 0.55)
        case 60..<80: return Color(red: 0.4, green: 0.7, blue: 0.5)
        case 40..<60: return Color(red: 0.5, green: 0.6, blue: 0.45)
        case 20..<40: return Color(red: 0.6, green: 0.55, blue: 0.4)
        default: return Color(red: 0.55, green: 0.45, blue: 0.35)
        }
    }
}
