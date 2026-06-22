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
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡
                statsCard

                // 图表
                VStack(spacing: 8) {
                    Picker("周期", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period == .week
                                 ? NSLocalizedString("本周", comment: "This week")
                                 : NSLocalizedString("本月", comment: "This month")).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartView
                        .frame(height: 200)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)

                // Pro 深度洞察（免费用户看到锁定卡片）
                proInsightCard
                    .padding(.horizontal, 20)

                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.waterLog)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeManager)
        }
    }

    var isPro: Bool { storeManager.isPro }

    // MARK: - 统计卡

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(icon: "flame.fill", color: .orange,
                     value: "\(waterStore.currentStreak)",
                     label: NSLocalizedString("当前连胜", comment: "Current streak"))
            Divider().frame(height: 40)
            statItem(icon: "trophy.fill", color: .yellow,
                     value: "\(waterStore.longestStreak)",
                     label: NSLocalizedString("最长连胜", comment: "Longest streak"))
            Divider().frame(height: 40)
            statItem(icon: "drop.fill", color: .bloomWater,
                     value: "\(waterStore.weekAverage)",
                     label: NSLocalizedString("周均 ml", comment: "Weekly avg ml"))
        }
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
                Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
            }
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pro 深度洞察卡

    private var proInsightCard: some View {
        Group {
            if isPro {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L.deepInsights).font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("PRO".localized).font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.bloomGold)
                            .clipShape(Capsule())
                    }

                    // 达标率
                    insightRow(
                        label: NSLocalizedString("本期达标率", comment: "Period achievement rate"),
                        value: "\(achievementRate)%",
                        color: achievementRate >= 60 ? .bloomSuccess : .bloomWarning,
                        detail: String(format: NSLocalizedString("%d / %d 天达标", comment: ""), achievedDays, totalDays)
                    )

                    // 平均完成度
                    insightRow(
                        label: NSLocalizedString("平均目标完成度", comment: "Average goal completion"),
                        value: "\(avgCompletionPercent)%",
                        color: avgCompletionPercent >= 70 ? .bloomSuccess : .bloomWater,
                        detail: String(format: NSLocalizedString("平均每天 %d ml", comment: ""), avgDailyMl)
                    )

                    // 最佳一天
                    insightRow(
                        label: NSLocalizedString("本期最佳", comment: "Best day of the period"),
                        value: "\(bestDayAmount) ml",
                        color: .bloomGold,
                        detail: bestDayLabel
                    )

                    Divider()

                    // 成长历程
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill").foregroundStyle(Color.bloomPrimary)
                        Text(L.plantGrowthJourney)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(String(format: NSLocalizedString("%@ · %@ · 种植 %d 天", comment: ""),
                                    plantEngine.plant.species.localizedName,
                                    plantEngine.plant.stage.name,
                                    plantEngine.plant.ageInDays))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                // 锁定状态：展示 Pro 洞察的预览 + 升级按钮
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.bloomGold)
                        Text(L.deepDataInsights).font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("PRO".localized).font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.bloomGold)
                            .clipShape(Capsule())
                    }

                    Text(L.deepInsightsExplain)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        showPaywall = true
                    } label: {
                        Text("解锁 Bloom Pro".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.bloomPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func insightRow(label: String, value: String, color: Color, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13)).foregroundStyle(.secondary)
                Text(detail).font(.system(size: 11)).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
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
                        : Color.bloomWater.opacity(0.6)
                )
                .cornerRadius(4)
            }
            RuleMark(y: .value("目标", goal))
                .foregroundStyle(Color.bloomGold.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: period == .week ? .dateTime.weekday(.abbreviated) : .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in AxisGridLine(); AxisValueLabel() }
        }
    }
}
