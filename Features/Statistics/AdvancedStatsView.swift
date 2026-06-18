// AdvancedStatsView.swift
// 高级统计 —— Pro 用户的深度数据分析

import SwiftUI
import Charts

struct AdvancedStatsView: View {
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var userStore: UserStore
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week    = "周"
        case month   = "月"
        case quarter = "季"
        case year    = "年"

        var localizedTitle: String {
            switch self {
            case .week:    return NSLocalizedString("周", comment: "Week")
            case .month:   return NSLocalizedString("月", comment: "Month")
            case .quarter: return NSLocalizedString("季", comment: "Quarter")
            case .year:    return NSLocalizedString("年", comment: "Year")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 时间范围选择器
                timeRangeSelector
                
                // 核心统计卡片
                statsOverview
                
                // 喝水趋势图
                trendChart
                
                // 最佳喝水时间
                bestTimeCard
                
                // 每周习惯分析
                weeklyHabitCard
                
                // 成就进度汇总
                achievementSummary
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.advancedStats)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - 时间范围选择器
    
    private var timeRangeSelector: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.localizedTitle).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - 核心统计卡片
    
    private var statsOverview: some View {
        let stats = calculateStats()
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: NSLocalizedString("平均每日", comment: "Average daily"),
                value: "\(stats.averageDaily)ml",
                icon: "chart.bar.fill",
                color: .bloomWater
            )

            StatCard(
                title: NSLocalizedString("达标率", comment: "Goal completion rate"),
                value: "\(stats.goalCompletionRate)%",
                icon: "target",
                color: .bloomPrimary
            )

            StatCard(
                title: NSLocalizedString("总喝水量", comment: "Total intake"),
                value: "\(stats.totalAmount / 1000)L",
                icon: "drop.fill",
                color: .blue
            )

            StatCard(
                title: NSLocalizedString("最长连续", comment: "Longest streak"),
                value: "\(stats.longestStreak)天",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - 趋势图
    
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.waterTrend)
                .font(.system(size: 16, weight: .semibold))

            Chart {
                ForEach(getChartData(), id: \.date) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("水量", point.amount)
                    )
                    .foregroundStyle(Color.bloomWater)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("水量", point.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.bloomWater.opacity(0.3), .bloomWater.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // 目标线
                RuleMark(y: .value("目标", waterStore.dailyGoal))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .frame(height: 200)
            .chartYAxisLabel("毫升")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - 最佳喝水时间

    private var bestTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.bloomGold)
                Text(L.peakHydrationTime)
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(NSLocalizedString("上午 9-10 点是你喝水最频繁的时段，继续保持！", comment: "Peak time explanation"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // 时间分布条
            HStack(spacing: 4) {
                ForEach(0..<24) { hour in
                    let intensity = hour >= 8 && hour <= 10 ? 1.0 : (hour >= 12 && hour <= 14 ? 0.7 : 0.2)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.bloomWater.opacity(intensity))
                        .frame(height: 30)
                }
            }
            .frame(height: 30)

            HStack {
                Text("00:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("12:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("23:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - 每周习惯分析

    private var weeklyHabitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.weeklyHabits)
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 8) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day == "三" || day == "五" ? Color.bloomPrimary : Color.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(day)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(day == "三" || day == "五" ? .white : .secondary)
                            )

                        Text(day)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(NSLocalizedString("周三、周五是你的喝水高峰日", comment: "Weekly habit explanation"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - 成就进度汇总

    private var achievementSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.bloomGold)
                Text(L.achievementProgress)
                    .font(.system(size: 16, weight: .semibold))
            }

            HStack {
                Text(L.unlocked)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text("12/20")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.bloomPrimary)
            }

            ProgressView(value: 12, total: 20)
                .tint(.bloomPrimary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 辅助方法
    
    private func calculateStats() -> DailyStats {
        // 这里应该根据 selectedTimeRange 计算真实数据
        // 简化示例
        return DailyStats(
            averageDaily: 1850,
            goalCompletionRate: 78,
            totalAmount: 45000,
            longestStreak: 14
        )
    }
    
    private func getChartData() -> [ChartDataPoint] {
        // 示例数据，实际应从 waterStore 计算
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let amount = [1800, 2100, 1950, 2300, 1700, 2050, 1900][daysAgo]
            return ChartDataPoint(date: date, amount: amount)
        }.reversed()
    }
}

// MARK: - 数据模型

struct DailyStats {
    let averageDaily: Int
    let goalCompletionRate: Int
    let totalAmount: Int
    let longestStreak: Int
}

struct ChartDataPoint {
    let date: Date
    let amount: Int
}

// MARK: - 统计卡片组件

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        AdvancedStatsView()
            .environmentObject(WaterStore())
            .environmentObject(UserStore())
    }
}
