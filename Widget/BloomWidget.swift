// BloomWidget.swift
// Bloom Widget —— 显示喝水进度和植物状态
// 支持：小(2x2)、中(4x2)、大(4x4) 三种尺寸

import WidgetKit
import SwiftUI

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
    
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(currentIntake) / Double(dailyGoal))
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
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            data: WidgetData(
                currentIntake: 1500,
                dailyGoal: 2000,
                plantName: "Plant",
                plantHealth: 75.0,
                plantStage: "Growing",
                plantSymbol: "🌱",
                isPaused: false,
                lastUpdated: Date()
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
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else {
            return WidgetData(
                currentIntake: 0,
                dailyGoal: 2000,
                plantName: "Bloom",
                plantHealth: 50.0,
                plantStage: "Seed",
                plantSymbol: "🌰",
                isPaused: false,
                lastUpdated: Date()
            )
        }
        
        let currentIntake = defaults.integer(forKey: AppConstants.WidgetKeys.todayIntake)
        let dailyGoal = defaults.integer(forKey: AppConstants.WidgetKeys.dailyGoal)
        let plantName = defaults.string(forKey: AppConstants.WidgetKeys.plantName) ?? "Plant"
        let plantHealth = defaults.double(forKey: AppConstants.WidgetKeys.plantHealth)
        let plantStage = defaults.string(forKey: AppConstants.WidgetKeys.plantStage) ?? "Seed"
        let plantSymbol = defaults.string(forKey: AppConstants.WidgetKeys.plantSymbol) ?? "🌰"
        let isPaused = defaults.bool(forKey: AppConstants.WidgetKeys.isPaused)
        
        return WidgetData(
            currentIntake: currentIntake,
            dailyGoal: dailyGoal > 0 ? dailyGoal : 2000,
            plantName: plantName,
            plantHealth: plantHealth > 0 ? plantHealth : 50.0,
            plantStage: plantStage,
            plantSymbol: plantSymbol,
            isPaused: isPaused,
            lastUpdated: Date()
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
        VStack(spacing: 8) {
            // 植物状态
            HStack {
                Text(data.plantSymbol)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.plantName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(data.plantStage)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if data.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                }
            }
            
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: data.progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.8, blue: 0.6), Color.bloom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(data.currentIntake)")
                        .font(.system(size: 20, weight: .bold))
                    Text("/ \(data.dailyGoal)ml")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            
            // 植物健康
            HStack(spacing: 4) {
                Text(data.healthEmoji)
                    .font(.system(size: 12))
                Text("\(Int(data.plantHealth))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - 中尺寸 Widget (4x2)

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：植物
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(data.plantSymbol)
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.plantName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(data.plantStage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                if data.isPaused {
                    Label(WidgetL.pauseCareFull, systemImage: "pause.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
                
                HStack(spacing: 12) {
                    Label("\(Int(data.plantHealth))%", systemImage: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    
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
                            colors: [Color.bloom, Color.bloomPrimary],
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
        VStack(spacing: 16) {
            // 顶部：植物状态
            HStack {
                Text(data.plantSymbol)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.plantName)
                        .font(.system(size: 18, weight: .semibold))
                    Text(data.plantStage)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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
                            colors: [Color.bloom, Color.bloomPrimary, Color.bloomGold],
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
            
            // 底部：统计信息
            HStack(spacing: 20) {
                VStack {
                    Text(WidgetL.plantHealth)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(Int(data.plantHealth))%")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Divider()
                
                VStack {
                    Text(WidgetL.status)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(data.healthEmoji)
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                Text(String(format: "%@ %@", WidgetL.updatedAt, DateFormatter.localizedString(from: data.lastUpdated, dateStyle: .none, timeStyle: .short)))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
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

// MARK: - 颜色扩展

extension Color {
    static let bloom = Color(red: 0.2, green: 0.8, blue: 0.6)
    static let bloomPrimary = Color(red: 0.25, green: 0.75, blue: 0.55)
    static let bloomGold = Color(red: 1.0, green: 0.85, blue: 0.2)
}
