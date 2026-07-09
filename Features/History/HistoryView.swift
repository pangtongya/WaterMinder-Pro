// HistoryView.swift
// 历史统计页 —— 图表 + 连胜 + 每日记录 + Pro 深度洞察
//
// 免费版：周/月柱状图 + 连胜 + 周均
// Pro 版：达标率分析 + 平均完成度 + 成长历程 + 月度对比

import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var plantEngine: PlantEngine

    @State private var period: Period = .week
    @State private var showPaywall = false

    enum Period: String, CaseIterable {
        case week
        case month
        var days: Int { self == .week ? 7 : 30 }
        var label: String {
            self == .week
                ? NSLocalizedString("本周", comment: "This week")
                : NSLocalizedString("本月", comment: "This month")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 统计摘要卡片
                SurfaceCard {
                    StatsCard(stats: [
                        ("🔥", "\(waterStore.currentStreak)", NSLocalizedString("当前连胜", comment: "Current streak")),
                        ("🏆", "\(waterStore.longestStreak)", NSLocalizedString("最长连胜", comment: "Longest streak")),
                        ("💧", "\(waterStore.weekAverage)", NSLocalizedString("周均 ml", comment: "Weekly avg ml"))
                    ])
                }
                .padding(.horizontal, 16)

                // 图表区域
                SurfaceCard(padding: 16) {
                    VStack(spacing: 20) {
                        // 分段选择器
                        SegmentedPicker(
                            selection: Binding(
                                get: { period.label },
                                set: { newValue in
                                    period = newValue == Period.week.label ? .week : .month
                                }
                            ),
                            options: Period.allCases.map { $0.label }
                        )

                        // 柱状图
                        chartView
                            .frame(height: 180)
                    }
                }
                .padding(.horizontal, 16)

                // Pro 深度洞察卡片
                proInsightCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .background(Color.bloomBackground)
        .navigationTitle(L.waterLog)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeManager)
        }
    }

    var isPro: Bool { storeManager.isPro }

    // MARK: - Pro 深度洞察卡

    private var proInsightCard: some View {
        SurfaceCard(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题与 Badge
                HStack(spacing: 8) {
                    Text("PRO")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.22)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.bloomGoldMuted)
                        .foregroundStyle(Color.bloomGold)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(L.deepInsights)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.bloomTextPrimary)
                }

                // 洞察数据行
                VStack(spacing: 12) {
                    insightRow(
                        label: NSLocalizedString("达标率", comment: "Achievement rate"),
                        value: "\(achievementRate)%",
                        color: achievementRate >= 60 ? .bloomSuccess : .bloomWarning,
                        detail: NSLocalizedString("近30天", comment: "Last 30 days")
                    )

                    Divider()

                    insightRow(
                        label: NSLocalizedString("平均完成度", comment: "Average completion"),
                        value: "\(avgCompletionPercent)%",
                        color: avgCompletionPercent >= 70 ? .bloomSuccess : .bloomWater,
                        detail: NSLocalizedString("日均", comment: "Daily average")
                    )

                    Divider()

                    insightRow(
                        label: NSLocalizedString("本期最佳", comment: "Best day of the period"),
                        value: "\(bestDayAmount)ml",
                        color: .bloomGold,
                        detail: bestDayLabel
                    )
                }

                // 锁定蒙层（非 Pro 用户）
                if !isPro {
                    Color.bloomSurface.opacity(0.6)
                        .blur(radius: 2)
                        .overlay {
                            VStack(spacing: 8) {
                                IconCircle(
                                    icon: "lock.fill",
                                    backgroundColor: Color.bloomFill,
                                    iconColor: Color.bloomTextSecondary,
                                    size: .medium
                                )
                                
                                Text(NSLocalizedString("升级 Pro 解锁完整洞察", comment: "Upgrade to Pro to unlock insights"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .onTapGesture {
            if !isPro {
                showPaywall = true
            }
        }
    }

    private func insightRow(label: String, value: String, color: Color, detail: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.bloomTextSecondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextTertiary)
            }
        }
    }

    // MARK: - 统计计算

    private var periodData: [(date: Date, amount: Int)] {
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -(period.days - 1), to: end) ?? Date()
        return waterStore.dailyTotals(from: start, to: end)
    }

    private var totalDays: Int { periodData.count }

    private var achievedDays: Int {
        periodData.filter { $0.amount >= userStore.dailyGoal }.count
    }

    private var achievementRate: Int {
        guard totalDays > 0 else { return 0 }
        return Int(Double(achievedDays) / Double(totalDays) * 100)
    }

    private var avgDailyMl: Int {
        guard totalDays > 0 else { return 0 }
        return periodData.reduce(0) { $0 + $1.amount } / totalDays
    }

    private var avgCompletionPercent: Int {
        guard userStore.dailyGoal > 0 else { return 0 }
        return min(Int(Double(avgDailyMl) / Double(userStore.dailyGoal) * 100), 999)
    }

    private var bestDayAmount: Int {
        periodData.map(\.amount).max() ?? 0
    }

    private var bestDayLabel: String {
        guard let best = periodData.max(by: { $0.amount < $1.amount }) else {
            return NSLocalizedString("暂无数据", comment: "No data")
        }
        let f = DateFormatter()
        f.locale = Locale.current
        // 正确判断中文语言环境
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        f.dateFormat = period == .week ? "EEEE" : (isChinese ? "M月d日" : "MMM d")
        return f.string(from: best.date)
    }

    // MARK: - 图表

    private var chartView: some View {
        let data = periodData
        let goal = userStore.dailyGoal

        return Chart {
            ForEach(data, id: \.date) { item in
                BarMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("水量", item.amount)
                )
                .foregroundStyle(
                    item.amount >= goal
                        ? Color.bloomSuccess.opacity(0.8)
                        : Color.bloomWater.opacity(0.7)
                )
                .cornerRadius(6)
            }
            
            // 目标线（虚线）
            RuleMark(y: .value("目标", goal))
                .foregroundStyle(Color.bloomGold.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(NSLocalizedString("目标 \(goal)", comment: "Goal"))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomWarning)
                        .padding(.trailing, 4)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: period == .week ? .dateTime.weekday(.abbreviated) : .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: 0...Int(Double(goal) * 1.5))
    }
}
