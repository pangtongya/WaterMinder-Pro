// HomeView.swift
// 首页 - 喝水进度、快速记录、连胜展示

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var selectedCupType: CupType = .medium
    @State private var showCelebration = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 连胜 + 进度环卡片
                ProgressSection(
                    progress: recordStore.todayProgress,
                    totalAmount: recordStore.todayTotalAmount,
                    goal: appState.dailyGoal,
                    streakDays: recordStore.currentStreak,
                    onGoalReached: { showCelebration = true }
                )
                .padding(.horizontal, 20)
                
                // 快速记录
                QuickRecordView(selectedCupType: $selectedCupType)
                    .padding(.horizontal, 20)
                
                // 今日记录
                TodayRecordsView()
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 80)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("WaterMinder")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if showCelebration {
                SimpleCelebrationView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showCelebration = false
                    }
                }
            }
        }
    }
}

// MARK: - Progress Section
struct ProgressSection: View {
    let progress: Double
    let totalAmount: Int
    let goal: Int
    let streakDays: Int
    let onGoalReached: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 进度环
            ZStack {
                // 外层发光效果
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // 背景环
                Circle()
                    .stroke(Color(.systemGray6).opacity(0.5), lineWidth: 18)
                    .frame(width: 190, height: 190)

                // 进度环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.02, green: 0.71, blue: 0.83), // Teal
                                Color(red: 0.00, green: 0.48, blue: 0.83)   // Blue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                    .shadow(color: Color.cyan.opacity(progress * 0.5), radius: progress * 15)

                // 中心文字
                VStack(spacing: 2) {
                    Text("\(totalAmount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    Text("/ \(goal) ml")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 24)
            
            // 百分比
            HStack(spacing: 4) {
                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "drop.fill")
                    .font(.system(size: 13))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color.progressColor(progress))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.progressColor(progress).opacity(0.1))
            .cornerRadius(20)
            .padding(.top, 12)
            
            // 连胜条
            if streakDays > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("连续 \(streakDays) 天达标")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .onChange(of: progress) { newValue in
            if newValue >= 1.0 {
                onGoalReached()
            }
        }
    }
}

// MARK: - Quick Record View
struct QuickRecordView: View {
    @Binding var selectedCupType: CupType
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("快速记录")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            
            HStack(spacing: 10) {
                ForEach(CupType.allCases, id: \.self) { cupType in
                    CupButton(cupType: cupType, isSelected: selectedCupType == cupType) {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        selectedCupType = cupType
                        addWaterRecord(cupType: cupType)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    
    private func addWaterRecord(cupType: CupType) {
        let record = recordStore.addRecord(amount: cupType.defaultAmount, cupType: cupType)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            do {
                try await healthManager.saveWaterIntake(Double(record.amount))
            } catch {
                print("[HomeView] Health sync error: \(error)")
            }
        }
    }
}

// MARK: - Cup Button
struct CupButton: View {
    let cupType: CupType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.waterminderPrimary : Color(.tertiarySystemBackground))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: cupType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : .waterminderPrimary)
                }
                
                Text(cupType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .waterminderPrimary : .secondary)
                
                Text("\(cupType.defaultAmount)ml")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? .waterminderPrimary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Today Records View
struct TodayRecordsView: View {
    @EnvironmentObject var recordStore: WaterRecordStore
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("今日记录")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                if !recordStore.todayRecords.isEmpty {
                    Text("\(recordStore.todayRecords.count) 次")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 8)
            
            if recordStore.todayRecords.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.12),
                                        Color.cyan.opacity(0.03)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "drop.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.cyan)
                    }

                    VStack(spacing: 4) {
                        Text("今天还没记录喝水")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("点击上方按钮，开始健康饮水之旅 💧")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recordStore.todayRecords.enumerated()), id: \.element.id) { index, record in
                        RecordRowView(record: record)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                        
                        if index < recordStore.todayRecords.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Record Row View
struct RecordRowView: View {
    let record: WaterRecordModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.waterminderPrimary.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: record.cupType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.waterminderPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.cupType.rawValue)
                    .font(.system(size: 15, weight: .medium))
                Text(record.timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(record.formattedAmount)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.waterminderPrimary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 64))
                
                Text("目标达成！")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("太棒了！今天的饮水目标已完成")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: dismiss) {
                    Text("继续加油")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.waterminderPrimary)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.5
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(AppState.shared)
                .environmentObject(WaterRecordStore())
                .environmentObject(HealthManager.shared)
        }
    }
}
