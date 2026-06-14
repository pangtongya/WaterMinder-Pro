// WaterMinderWidget.swift
// 桌面 + 锁屏小组件

import WidgetKit
import SwiftUI

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), progress: 0.35, totalAmount: 700, goal: 2000, streakDays: 3)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), progress: 0.5, totalAmount: 1000, goal: 2000, streakDays: 5)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.pangtong.WaterMinder")
        let progress = defaults?.double(forKey: "todayProgress") ?? 0.0
        let totalAmount = defaults?.integer(forKey: "todayTotalAmount") ?? 0
        let goal = defaults?.integer(forKey: "dailyGoal") ?? 2000
        let streakDays = defaults?.integer(forKey: "currentStreak") ?? 0
        
        let entry = SimpleEntry(
            date: Date(),
            progress: progress,
            totalAmount: totalAmount,
            goal: goal,
            streakDays: streakDays
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let totalAmount: Int
    let goal: Int
    let streakDays: Int
}

// MARK: - Widget Views
struct WaterMinderWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryRectangular:
            rectangularWidget
        default:
            smallWidget
        }
    }
    
    // MARK: - Small Widget
    private var smallWidget: some View {
        ZStack {
            Color(.systemBackground)
            
            VStack(spacing: 8) {
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: min(entry.progress, 1.0))
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(entry.totalAmount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("ml")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                if entry.streakDays > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("\(entry.streakDays)天")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
        }
    }
    
    // MARK: - Medium Widget
    private var mediumWidget: some View {
        ZStack {
            Color(.systemBackground)
            
            HStack(spacing: 16) {
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: min(entry.progress, 1.0))
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(entry.progress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("\(entry.totalAmount)ml")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日饮水")
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 4) {
                        Text("目标")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(entry.goal)ml")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    if entry.streakDays > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("连续 \(entry.streakDays) 天达标")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    
                    if entry.progress >= 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("目标已达成！")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Lock Screen Circular
    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            Circle()
                .trim(from: 0, to: min(entry.progress, 1.0))
                .stroke(
                    Color.waterminderPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(4)
            
            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
        }
    }
    
    // MARK: - Lock Screen Rectangular
    private var rectangularWidget: some View {
        HStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .font(.system(size: 16))
                .foregroundColor(.waterminderPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("饮水 \(entry.totalAmount)ml / \(entry.goal)ml")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(Int(entry.progress * 100))% 完成")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color.waterminderPrimary, Color.waterminderAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Widget
extension Color {
    static let waterminderPrimary = Color(red: 0.23, green: 0.51, blue: 0.96)
    static let waterminderAccent = Color(red: 0.02, green: 0.71, blue: 0.83)
}

// MARK: - Widget Definition
struct WaterMinderWidget: Widget {
    let kind: String = "WaterMinderWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WaterMinderWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("饮水进度")
        .description("查看今日饮水进度和连胜天数")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Preview
struct WaterMinderWidget_Previews: PreviewProvider {
    static var previews: some View {
        WaterMinderWidgetEntryView(entry: SimpleEntry(
            date: Date(),
            progress: 0.65,
            totalAmount: 1300,
            goal: 2000,
            streakDays: 5
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
