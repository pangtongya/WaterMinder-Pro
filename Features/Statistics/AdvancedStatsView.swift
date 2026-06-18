// AdvancedStatsView.swift
// 高级统计 —— Pro 用户的深度数据分析

import SwiftUI
import Charts

struct AdvancedStatsView: View {
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var achievementStore: AchievementStore
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

        /// 时间范围的天数
        var days: Int {
            switch self {
            case .week:    return 7
            case .month:   return 30
            case .quarter: return 90
            case .year:    return 365
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
        let prevStats = calculatePreviousPeriodStats()

        return VStack(spacing: 12) {
            // 顶部 —— 今日概览
            todayOverviewCard

            // 底部 —— 四格总览
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ComparisonStatCard(
                    title: NSLocalizedString("平均每日", comment: "Average daily"),
                    value: "\(stats.averageDaily)ml",
                    icon: "chart.bar.fill",
                    color: .bloomWater,
                    previousValue: prevStats.averageDaily,
                    unit: "ml"
                )

                ComparisonStatCard(
                    title: NSLocalizedString("达标率", comment: "Goal completion rate"),
                    value: "\(stats.goalCompletionRate)%",
                    icon: "target",
                    color: .bloomPrimary,
                    previousValue: prevStats.goalCompletionRate,
                    unit: "%"
                )

                ComparisonStatCard(
                    title: NSLocalizedString("总喝水量", comment: "Total intake"),
                    value: "\(stats.totalAmount / 1000)L",
                    icon: "drop.fill",
                    color: .blue,
                    previousValue: prevStats.totalAmount / 1000,
                    unit: "L"
                )

                ComparisonStatCard(
                    title: NSLocalizedString("最长连续", comment: "Longest streak"),
                    value: "\(stats.longestStreak)天",
                    icon: "flame.fill",
                    color: .orange,
                    previousValue: prevStats.longestStreak,
                    unit: NSLocalizedString("天", comment: "days")
                )
            }
        }
    }

    // MARK: - 今日概览卡片

    private var todayOverviewCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = waterStore.records.filter {
            calendar.startOfDay(for: $0.createdAt) == today
        }
        let todayTotal = todayRecords.reduce(0) { $0 + $1.amount }
        let goal = userStore.dailyGoal
        let progress = goal > 0 ? min(Double(todayTotal) / Double(goal), 1.0) : 0
        let remaining = max(goal - todayTotal, 0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.bloomPrimary)
                Text(NSLocalizedString("今日概览", comment: "Today's overview"))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(today, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // 进度条（圆形比例）
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.bloomWater, .bloomPrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .bold))
                        Text("\(todayTotal)ml")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if todayTotal >= goal {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.bloomSuccess)
                            Text(NSLocalizedString("目标达成！", comment: "Goal reached!"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.bloomSuccess)
                        }
                    } else {
                        HStack {
                            Image(systemName: "drop.trianglebadge.exclamationmark")
                                .foregroundColor(.orange)
                            Text(String(format: NSLocalizedString("还差 %dml 达成目标", comment: "%dml to goal"), remaining))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }

                    Text(String(format: NSLocalizedString("已记录 %d 次", comment: "%d records logged"), todayRecords.count))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    let avgCup = todayRecords.count > 0 ? todayTotal / todayRecords.count : 0
                    if avgCup > 0 {
                        Text(String(format: NSLocalizedString("单次平均 %dml", comment: "Avg %dml per cup"), avgCup))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 趋势图

    private var trendChart: some View {
        let stats = calculateStats()
        let goal = userStore.dailyGoal
        let avg = stats.averageDaily
        let chartPoints = getChartData()
        let maxAmount = max(chartPoints.map { $0.amount }.max() ?? goal, goal)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.bloomWater)
                Text(L.waterTrend)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                // 图例
                HStack(spacing: 8) {
                    legendDot(color: .bloomWater, label: NSLocalizedString("实际", comment: "Actual"))
                    legendDot(color: .bloomSuccess, label: NSLocalizedString("平均", comment: "Avg"), dashed: true)
                    legendDot(color: .red, label: NSLocalizedString("目标", comment: "Goal"), dashed: true)
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            Chart {
                ForEach(chartPoints, id: \.date) { point in
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
                            colors: [.bloomWater.opacity(0.3), .bloomWater.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // 目标线
                RuleMark(y: .value("目标", goal))
                    .foregroundStyle(Color.red.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                // 平均线
                if avg > 0 {
                    RuleMark(y: .value("平均", avg))
                        .foregroundStyle(Color.bloomSuccess.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .frame(height: 200)
            .chartYAxisLabel("毫升")
            .chartYScale(domain: 0...max(Int(Double(maxAmount) * 1.1), 1000))

            // 图表下方的简短分析
            let trendText = trendAnalysis(current: stats.averageDaily, avg: avg, goal: goal)
            Text(trendText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func legendDot(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 3) {
            if dashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [3]))
                    .frame(width: 12, height: 0)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(label)
        }
    }

    /// 基于当前日平均与总目标的简单趋势分析
    private func trendAnalysis(current: Int, avg: Int, goal: Int) -> String {
        if goal <= 0 { return "" }
        let diff = current - goal
        let pct = Int(Double(current) / Double(goal) * 100)
        if current >= goal {
            return String(format: NSLocalizedString("平均 %dml / 天（达到目标的 %d%%），继续保持！", comment: "Analysis: good"), current, pct)
        } else if current >= goal / 2 {
            return String(format: NSLocalizedString("平均 %dml / 天（达到目标的 %d%%），还差 %dml 达标", comment: "Analysis: close"), current, pct, -diff)
        } else {
            return String(format: NSLocalizedString("平均 %dml / 天（达到目标的 %d%%），建议增加喝水频次", comment: "Analysis: need improvement"), current, pct)
        }
    }

    // MARK: - 最佳喝水时间

    private var bestTimeCard: some View {
        let distribution = hourlyDistribution()
        let peak = peakHours()
        let maxAmount = distribution.values.max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.bloomGold)
                Text(L.peakHydrationTime)
                    .font(.system(size: 16, weight: .semibold))
            }

            if peak.isEmpty {
                Text(NSLocalizedString("暂无足够数据分析高峰时段", comment: "No data for peak time"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                let peakText = peak.map { hour -> String in
                    String(format: "%02d:00", hour)
                }.joined(separator: "、")
                Text(String(format: NSLocalizedString("%s 是你喝水最频繁的时段，继续保持！", comment: "Peak time explanation"), peakText))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // 时间分布条（24小时）
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    let amount = distribution[hour] ?? 0
                    let intensity = maxAmount > 0 ? Double(amount) / Double(maxAmount) : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.bloomWater.opacity(intensity * 0.8 + 0.1))
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
        let distribution = weekdayDistribution()
        let peakDays = peakWeekdays()
        let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
        let maxAmount = distribution.values.max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Text(L.weeklyHabits)
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 8) {
                ForEach(1..<8, id: \.self) { weekday in
                    let amount = distribution[weekday] ?? 0
                    let intensity = maxAmount > 0 ? Double(amount) / Double(maxAmount) : 0
                    let isPeak = peakDays.contains(weekday)

                    VStack(spacing: 4) {
                        Circle()
                            .fill(isPeak ? Color.bloomPrimary : Color.gray.opacity(0.2 + intensity * 0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(weekdayNames[weekday - 1])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(isPeak ? .white : .secondary)
                            )

                        Text(weekdayNames[weekday - 1])
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if peakDays.isEmpty {
                Text(NSLocalizedString("暂无足够数据分析每周习惯", comment: "No weekly habit data"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                let peakDayNames = peakDays.map { weekdayNames[$0 - 1] }.joined(separator: "、")
                Text(String(format: NSLocalizedString("周%s 是你的喝水高峰日", comment: "Weekly habit explanation"), peakDayNames))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
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
                Text("\(achievementStore.unlockedCount)/\(achievementStore.totalCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.bloomPrimary)
            }

            ProgressView(value: Double(achievementStore.unlockedCount), total: Double(achievementStore.totalCount))
                .tint(.bloomPrimary)

            // 显示最近解锁的成就
            let recentUnlocked = achievementStore.achievements
                .filter { $0.isUnlocked }
                .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
                .prefix(3)

            if !recentUnlocked.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("最近解锁", comment: "Recently unlocked"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    ForEach(recentUnlocked, id: \.id) { achievement in
                        HStack {
                            Image(systemName: achievement.icon)
                                .foregroundColor(.bloomGold)
                                .font(.system(size: 12))
                            Text(achievement.title)
                                .font(.system(size: 13))
                            Spacer()
                            if let date = achievement.unlockedAt {
                                Text(date.relativeDescription)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 辅助方法

    /// 根据时间范围筛选记录
    private func filteredRecords() -> [WaterRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())!
        return waterStore.records.filter { $0.createdAt >= startDate }
    }

    /// 计算统计数据（基于真实数据）
    private func calculateStats() -> DailyStats {
        let records = filteredRecords()
        let calendar = Calendar.current
        let dailyGoal = userStore.dailyGoal

        // 按天分组计算每日总量
        var dailyTotals: [Date: Int] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.createdAt)
            dailyTotals[day, default: 0] += record.amount
        }

        let daysWithData = dailyTotals.keys.count
        let totalAmount = records.reduce(0) { $0 + $1.amount }

        // 平均每日（按有数据的天数）
        let averageDaily = daysWithData > 0 ? totalAmount / daysWithData : 0

        // 达标率（达标天数 / 总天数）
        let goalMetDays = dailyTotals.values.filter { $0 >= dailyGoal }.count
        let totalDaysInRange = selectedTimeRange.days
        let goalCompletionRate = totalDaysInRange > 0 ? (goalMetDays * 100) / totalDaysInRange : 0

        // 计算最长连续达标天数
        let sortedDays = dailyTotals.keys.sorted()
        var longestStreak = 0
        var currentStreak = 0
        for day in sortedDays {
            if dailyTotals[day]! >= dailyGoal {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return DailyStats(
            averageDaily: averageDaily,
            goalCompletionRate: goalCompletionRate,
            totalAmount: totalAmount,
            longestStreak: longestStreak
        )
    }

    /// 获取图表数据（基于真实数据）
    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())!

        // 按天分组
        var dailyTotals: [Date: Int] = [:]
        for record in waterStore.records where record.createdAt >= startDate {
            let day = calendar.startOfDay(for: record.createdAt)
            dailyTotals[day, default: 0] += record.amount
        }

        // 生成完整日期序列（即使某天没数据也要显示）
        return (0..<selectedTimeRange.days).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
            let amount = dailyTotals[date] ?? 0
            return ChartDataPoint(date: date, amount: amount)
        }.sorted { $0.date < $1.date }
    }

    /// 计算最佳喝水时段（小时分布）
    private func hourlyDistribution() -> [Int: Int] {
        let records = filteredRecords()
        var hourlyTotals: [Int: Int] = [:]
        for record in records {
            let hour = Calendar.current.component(.hour, from: record.createdAt)
            hourlyTotals[hour, default: 0] += record.amount
        }
        return hourlyTotals
    }

    /// 获取高峰时段（小时）
    private func peakHours() -> [Int] {
        let distribution = hourlyDistribution()
        let maxAmount = distribution.values.max() ?? 0
        guard maxAmount > 0 else { return [] }
        let threshold = Int(Double(maxAmount) * 0.7)
        return distribution.filter { $0.value >= threshold }.keys.sorted()
    }

    /// 计算每周习惯（按星期几统计）
    private func weekdayDistribution() -> [Int: Int] {
        let records = filteredRecords()
        var weekdayTotals: [Int: Int] = [:]
        for record in records {
            let weekday = Calendar.current.component(.weekday, from: record.createdAt)
            weekdayTotals[weekday, default: 0] += record.amount
        }
        return weekdayTotals
    }

    /// 获取高峰星期（weekday: 1=周日, 2=周一...）
    private func peakWeekdays() -> [Int] {
        let distribution = weekdayDistribution()
        let avgAmount = distribution.values.reduce(0, +) / max(distribution.count, 1)
        return distribution.filter { $0.value >= avgAmount }.keys.sorted()
    }

    // MARK: - 上一周期统计（用于环比对比）

    /// 计算"上一个相同长度周期"的统计，用于环比比较
    /// 例：本周时，返回"上周（-14到-7天）"的统计
    private func calculatePreviousPeriodStats() -> DailyStats {
        let calendar = Calendar.current
        let days = selectedTimeRange.days
        let startDate = calendar.date(byAdding: .day, value: -days * 2, to: Date())!
        let endDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        let prevRecords = waterStore.records.filter {
            $0.createdAt >= startDate && $0.createdAt < endDate
        }

        let dailyGoal = userStore.dailyGoal

        // 按天分组
        var dailyTotals: [Date: Int] = [:]
        for record in prevRecords {
            let day = calendar.startOfDay(for: record.createdAt)
            dailyTotals[day, default: 0] += record.amount
        }

        let totalAmount = prevRecords.reduce(0) { $0 + $1.amount }
        let daysWithData = dailyTotals.keys.count
        let averageDaily = daysWithData > 0 ? totalAmount / daysWithData : 0
        let goalMetDays = dailyTotals.values.filter { $0 >= dailyGoal }.count
        let goalCompletionRate = days > 0 ? (goalMetDays * 100) / days : 0

        // 最长连续达标天数
        let sortedDays = dailyTotals.keys.sorted()
        var longestStreak = 0
        var currentStreak = 0
        for day in sortedDays {
            if (dailyTotals[day] ?? 0) >= dailyGoal {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return DailyStats(
            averageDaily: averageDaily,
            goalCompletionRate: goalCompletionRate,
            totalAmount: totalAmount,
            longestStreak: longestStreak
        )
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

// MARK: - 统计卡片组件（支持环比对比）

struct ComparisonStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let previousValue: Int
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // 环比小指示器（上升/下降箭头 + 百分比）
            if previousValue > 0 {
                trendIndicator
            } else {
                Text(NSLocalizedString("新记录", comment: "No previous data"))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var trendIndicator: some View {
        // 计算当前值（从 value 字符串中提取数字：格式"1500ml"/"80%"/"10L"/"5天"）
        let currentInt = extractNumber(from: value)
        let diff = currentInt - previousValue
        let pctChange: Double
        if previousValue > 0 {
            pctChange = Double(diff) / Double(previousValue) * 100
        } else {
            pctChange = 0
        }

        let isUp = diff >= 0
        let isGood: Bool
        // "目标"和"最长连续" 上升=好；"平均"和"总量"上升=好
        // 所有情况下都是上升代表更好
        isGood = isUp

        let trendColor: Color = pctChange == 0 ? .gray : (isGood ? .bloomSuccess : .orange)
        let systemName = pctChange == 0 ? "minus" : (isUp ? "arrow.up.right" : "arrow.down.right")

        return HStack(spacing: 3) {
            Image(systemName: systemName)
                .font(.system(size: 9))
            Text(String(format: "%d%%", Int(abs(pctChange))))
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor.opacity(0.1))
        .clipShape(Capsule())
    }

    /// 从字符串（如"1500ml"/"80%"/"10L"/"5天"）中提取整数
    private func extractNumber(from string: String) -> Int {
        let digits = string.filter { $0.isNumber }
        return Int(digits) ?? 0
    }
}

// 保留的极简卡片（未使用，但保留兼容）
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

// // #Preview {
//     NavigationStack {
//         AdvancedStatsView()
//             .environmentObject(WaterStore())
//             .environmentObject(UserStore())
//     }
