// HistoryView.swift
// 记录页面 - 图表 + 历史记录

import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var appState: AppState
    
    @State private var selectedDate = Date()
    @State private var selectedPeriod: Period = .week
    @State private var editingRecord: WaterRecordModel?
    @State private var showingAnalysisReport = false
    
    enum Period: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡片
                streakCard
                    .padding(.horizontal, 16)
                
                // 周期选择器 + 图表
                VStack(spacing: 8) {
                    Picker("周期", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    chartView
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                }
                
                // 日期选择 + 当日记录
                VStack(spacing: 0) {
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    Divider()
                    
                    if recordsForSelectedDate.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "cup.and.saucer")
                                .font(.system(size: 28))
                                .foregroundColor(.waterminderSecondary.opacity(0.4))
                            Text("当天没有喝水记录")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    } else {
                        // 当日统计摘要
                        HStack(spacing: 0) {
                            statItem(value: "\(recordsForSelectedDate.reduce(0) { $0 + $1.amount })", label: "总摄入", unit: "ml")
                            Divider().frame(height: 36)
                            statItem(value: "\(recordsForSelectedDate.count)", label: "记录次数", unit: "次")
                        }
                        .padding(.vertical, 12)
                        
                        Divider()
                        
                        ForEach(Array(recordsForSelectedDate.enumerated()), id: \.element.id) { index, record in
                            RecordDetailRowView(record: record)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteRecord(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        editingRecord = record
                                    } label: {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    .tint(.waterminderPrimary)
                                }
                            
                            if index < recordsForSelectedDate.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 16)
                
                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("喝水记录")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: showAnalysisReport) {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
        .sheet(isPresented: $showingAnalysisReport) {
            AnalysisReportView()
        }
        .sheet(item: $editingRecord) { record in
            EditRecordView(record: record)
        }
    }
    
    // MARK: - Private Methods
    
    private func showAnalysisReport() {
        showingAnalysisReport = true
    }
    
    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 0) {
            streakStat(
                icon: "flame.fill",
                color: .orange,
                value: "\(recordStore.currentStreak)",
                label: "当前连胜"
            )
            Divider().frame(height: 40)
            streakStat(
                icon: "trophy.fill",
                color: .yellow,
                value: "\(recordStore.longestStreak)",
                label: "最长连胜"
            )
            Divider().frame(height: 40)
            streakStat(
                icon: "drop.fill",
                color: .waterminderPrimary,
                value: "\(recordStore.thisWeekAverage)",
                label: "周均 ml"
            )
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    
    private func streakStat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart
    @ViewBuilder
    private var chartView: some View {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -(selectedPeriod.days - 1), to: endDate) ?? Calendar.current.startOfDay(for: Date())  // Fallback: today
        let data = recordStore.dailyAmounts(from: startDate, to: endDate)
        
        Chart {
            ForEach(data, id: \.date) { item in
                BarMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("饮水量", item.amount)
                )
                .foregroundStyle(
                    item.amount >= appState.dailyGoal
                        ? Color.waterminderSuccess.gradient
                        : Color.waterminderPrimary.gradient
                )
                .cornerRadius(4)
            }
            
            RuleMark(
                y: .value("目标", appState.dailyGoal)
            )
            .foregroundStyle(Color.waterminderWarning)
            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
            .annotation(position: .top, alignment: .trailing) {
                Text("目标 \(appState.dailyGoal)ml")
                    .font(.system(size: 10))
                    .foregroundColor(.waterminderWarning)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: selectedPeriod == .week
                    ? .dateTime.weekday(.abbreviated)
                    : .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Int.self) {
                        Text("\(amount)")
                            .font(.system(size: 10))
                    }
                }
            }
        }
    }
    
    private func statItem(value: String, label: String, unit: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.waterminderPrimary)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var recordsForSelectedDate: [WaterRecordModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        return recordStore.items.filter { record in
            record.createdAt >= startOfDay && record.createdAt < endOfDay
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Private Methods
    
    private func deleteRecord(_ record: WaterRecordModel) {
        recordStore.deleteRecord(record)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Record Detail Row View
struct RecordDetailRowView: View {
    let record: WaterRecordModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.waterminderPrimary.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: record.cupType.icon)
                    .font(.system(size: 15))
                    .foregroundColor(.waterminderPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.cupType.rawValue)
                    .font(.system(size: 15, weight: .medium))
                
                HStack(spacing: 6) {
                    Text(record.timeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let note = record.note, !note.isEmpty {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Text(record.formattedAmount)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.waterminderPrimary)
        }
    }
}

// MARK: - Edit Record View
struct EditRecordView: View {
    let record: WaterRecordModel
    @EnvironmentObject var recordStore: WaterRecordStore
    @Environment(\.dismiss) var dismiss
    
    @State private var amount: String
    @State private var selectedCupType: CupType
    @State private var note: String
    
    init(record: WaterRecordModel) {
        self.record = record
        self._amount = State(initialValue: "\(record.amount)")
        self._selectedCupType = State(initialValue: record.cupType)
        self._note = State(initialValue: record.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("水量")
                        Spacer()
                        TextField("水量", text: $amount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("ml")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("杯型", selection: $selectedCupType) {
                        ForEach(CupType.allCases, id: \.self) { cupType in
                            HStack {
                                Image(systemName: cupType.icon)
                                Text(cupType.rawValue)
                            }
                            .tag(cupType)
                        }
                    }
                } header: {
                    Text("喝水信息")
                }
                
                Section {
                    TextField("可选备注", text: $note)
                } header: {
                    Text("备注")
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveRecord() }
                        .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountInt = Int(amount), amountInt > 0 else { return false }
        return true
    }
    
    private func saveRecord() {
        guard let amountInt = Int(amount) else { return }
        
        recordStore.updateRecord(record, amount: amountInt, cupType: selectedCupType, note: note.isEmpty ? nil : note)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Analysis Report View
struct AnalysisReportView: View {
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 本周摘要
                    reportSection(title: "本周饮水摘要", icon: "drop.fill", color: .waterminderPrimary) {
                        VStack(spacing: 12) {
                            reportRow(label: "平均每日饮水量", value: "\(recordStore.thisWeekAverage) ml")
                            reportRow(label: "达标天数", value: "\(goalMetDaysThisWeek) 天")
                            reportRow(label: "最佳饮水日", value: "\(bestDayThisWeek) ml")
                            reportRow(label: "总记录次数", value: "\(recordStore.thisWeekRecords.count) 次")
                        }
                    }
                    
                    // 建议
                    reportSection(title: "个性化建议", icon: "lightbulb.fill", color: .waterminderAccent) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.waterminderSuccess)
                                    Text(suggestion)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    // 本月趋势
                    reportSection(title: "本月趋势", icon: "chart.line.uptrend.xyaxis", color: .waterminderSecondary) {
                        VStack(spacing: 12) {
                            reportRow(label: "本月平均饮水量", value: "\(monthlyAverage) ml")
                            reportRow(label: "本月达标率", value: String(format: "%.1f%%", goalMetRateThisMonth * 100))
                        }
                    }
                }
                .padding(.top, 4)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("饮水分析报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var goalMetDaysThisWeek: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? Date()
        let dailyTotals = recordStore.dailyAmounts(from: weekAgo, to: today)
        return dailyTotals.filter { $0.amount >= appState.dailyGoal }.count
    }
    
    private var bestDayThisWeek: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? Date()
        let dailyTotals = recordStore.dailyAmounts(from: weekAgo, to: today)
        return dailyTotals.map { $0.amount }.max() ?? 0
    }
    
    private var monthlyAverage: Int {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? Date()
        let dailyTotals = recordStore.dailyAmounts(from: monthAgo, to: today)
        guard !dailyTotals.isEmpty else { return 0 }
        let total = dailyTotals.reduce(0) { $0 + $1.amount }
        return total / dailyTotals.count
    }
    
    private var goalMetRateThisMonth: Double {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? Date()
        let dailyTotals = recordStore.dailyAmounts(from: monthAgo, to: today)
        guard !dailyTotals.isEmpty else { return 0 }
        let goalMetDays = dailyTotals.filter { $0.amount >= appState.dailyGoal }.count
        return Double(goalMetDays) / Double(dailyTotals.count)
    }
    
    private var suggestions: [String] {
        var result: [String] = []
        let average = recordStore.thisWeekAverage
        let goal = appState.dailyGoal
        
        if average < goal {
            result.append("您本周平均饮水量为\(average)ml，低于目标\(goal)ml。建议增加饮水量，保持健康！")
        } else {
            result.append("恭喜！您本周平均饮水量为\(average)ml，已达到目标\(goal)ml。请继续保持！")
        }
        
        if goalMetDaysThisWeek < 3 {
            result.append("您本周只有\(goalMetDaysThisWeek)天达标，建议设置提醒，帮助您养成喝水习惯。")
        }
        
        if recordStore.currentStreak == 0 {
            result.append("您目前没有连胜记录，从今天开始，争取连续达标7天吧！")
        } else if recordStore.currentStreak >= 7 {
            result.append("太棒了！您已连续达标\(recordStore.currentStreak)天，继续保持这个好习惯！")
        }
        
        return result
    }
    
    // MARK: - Helper Views
    
    private func reportSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal, 16)
    }
    
    private func reportRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryView()
                .environmentObject(WaterRecordStore())
                .environmentObject(AppState.shared)
        }
    }
}
