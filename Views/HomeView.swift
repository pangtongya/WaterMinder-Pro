// HomeView.swift
// 首页视图 - 显示今日喝水进度和快速记录

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var showingAddRecord = false
    @State private var selectedCupType: CupType = .medium
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 今日进度卡片
                    ProgressCardView(progress: recordStore.todayProgress, totalAmount: recordStore.todayTotalAmount, goal: appState.dailyGoal)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 快速记录按钮
                    QuickRecordView(selectedCupType: $selectedCupType)
                        .padding(.horizontal, 20)
                    
                    // 今日记录列表
                    TodayRecordsView()
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("WaterMinder")
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Progress Card View
struct ProgressCardView: View {
    let progress: Double
    let totalAmount: Int
    let goal: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                VStack(spacing: 4) {
                    Text("\(totalAmount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("ml / \(goal)ml")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // 进度文字
            Text(progressMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var progressMessage: String {
        let percentage = Int(progress * 100)
        if percentage >= 100 {
            return "🎉 今日目标已完成！"
        } else if percentage >= 75 {
            return "💪 快完成了，再加把劲！"
        } else if percentage >= 50 {
            return "👍 已经完成一半了！"
        } else if percentage >= 25 {
            return "🌊 继续喝水，保持健康！"
        } else {
            return "💧 开始今天的喝水之旅吧！"
        }
    }
}

// MARK: - Quick Record View
struct QuickRecordView: View {
    @Binding var selectedCupType: CupType
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("快速记录")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 杯型选择
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(CupType.allCases, id: \.self) { cupType in
                    CupTypeButton(cupType: cupType, isSelected: selectedCupType == cupType) {
                        selectedCupType = cupType
                        addWaterRecord(cupType: cupType)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func addWaterRecord(cupType: CupType) {
        let record = recordStore.addRecord(amount: cupType.defaultAmount, cupType: cupType)
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 同步到健康App
        Task {
            do {
                try await healthManager.saveWaterIntake(Double(record.amount))
            } catch {
                print("[HomeView] Health sync error: \(error)")
            }
        }
    }
}

// MARK: - Cup Type Button
struct CupTypeButton: View {
    let cupType: CupType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: cupType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(cupType.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(cupType.defaultAmount)ml")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// MARK: - Today Records View
struct TodayRecordsView: View {
    @EnvironmentObject var recordStore: WaterRecordStore
    
    var body: some View {
        VStack(spacing: 12) {
            Text("今日记录")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if recordStore.todayRecords.isEmpty {
                Text("还没有记录，点击上方按钮开始记录吧！")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recordStore.todayRecords) { record in
                        RecordRowView(record: record)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Record Row View
struct RecordRowView: View {
    let record: WaterRecordModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.cupType.icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.cupType.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(record.timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(record.formattedAmount)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState.shared)
            .environmentObject(WaterRecordStore())
            .environmentObject(HealthManager.shared)
    }
}
