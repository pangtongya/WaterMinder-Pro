// OnboardingView.swift
// 引导页面 - 5步引导流程

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var currentPage = 0
    @State private var dailyGoal: Int = 2000
    @State private var enableReminder: Bool = true
    @State private var reminderInterval: Int = 60
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    GoalSetupPage(dailyGoal: $dailyGoal)
                        .tag(1)
                    
                    ReminderSetupPage(enableReminder: $enableReminder, reminderInterval: $reminderInterval)
                        .tag(2)
                    
                    HealthPage()
                        .tag(3)
                    
                    CompletionPage()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 底部导航
                bottomBar(safeBottom: geometry.safeAreaInsets.bottom)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func bottomBar(safeBottom: CGFloat) -> some View {
        VStack(spacing: 20) {
            // 指示器
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.waterminderPrimary : Color.gray.opacity(0.25))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: currentPage)
                }
            }
            
            // 按钮
            HStack {
                if currentPage > 0 && currentPage < 4 {
                    Button("上一步") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(OnboardingSecondaryButtonStyle())
                }
                
                Spacer()
                
                if currentPage < 4 {
                    Button(currentPage == 3 ? "跳过" : "下一步") {
                        withAnimation {
                            currentPage = currentPage == 3 ? 4 : currentPage + 1
                        }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                } else {
                    Button("开始使用") {
                        completeOnboarding()
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, safeBottom + 20)
        .padding(.top, 16)
    }
    
    private func completeOnboarding() {
        appState.dailyGoal = dailyGoal
        appState.reminderEnabled = enableReminder
        appState.reminderInterval = reminderInterval
        
        if enableReminder {
            Task {
                _ = await notificationManager.requestAuthorization()
                notificationManager.scheduleWaterReminder(interval: reminderInterval)
            }
        }
        
        appState.hasCompletedOnboarding = true
        appState.save()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Onboarding Pages

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.waterminderPrimary, Color.waterminderAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("欢迎使用\nWaterMinder")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("智能喝水提醒\n帮您保持健康的水分摄入")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct GoalSetupPage: View {
    @Binding var dailyGoal: Int
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.waterminderPrimary.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "target")
                    .font(.system(size: 44))
                    .foregroundColor(.waterminderPrimary)
            }
            
            VStack(spacing: 8) {
                Text("设置每日饮水目标")
                    .font(.system(size: 24, weight: .semibold))
                Text("建议每日 2000ml，可根据需要调整")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                TextField("2000", value: $dailyGoal, formatter: NumberFormatter())
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                
                Text("毫升 / 天")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    ForEach([1500, 2000, 2500, 3000], id: \.self) { goal in
                        Button("\(goal)ml") {
                            dailyGoal = goal
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(dailyGoal == goal ? Color.waterminderPrimary : Color(.tertiarySystemBackground))
                        .foregroundColor(dailyGoal == goal ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct ReminderSetupPage: View {
    @Binding var enableReminder: Bool
    @Binding var reminderInterval: Int
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.waterminderPrimary.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "bell.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.waterminderPrimary)
            }
            
            VStack(spacing: 8) {
                Text("设置喝水提醒")
                    .font(.system(size: 24, weight: .semibold))
                Text("定时提醒您补充水分")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                Toggle("开启提醒", isOn: $enableReminder)
                    .tint(.waterminderPrimary)
                    .padding(.horizontal, 32)
                
                if enableReminder {
                    VStack(spacing: 12) {
                        Text("提醒间隔")
                            .font(.system(size: 15, weight: .medium))
                        
                        Picker("间隔", selection: $reminderInterval) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { interval in
                                Text("\(interval)分钟").tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct HealthPage: View {
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text("连接健康App")
                    .font(.system(size: 24, weight: .semibold))
                Text("将喝水记录同步到健康App\n获得更全面的健康数据")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: requestHealthAuthorization) {
                HStack {
                    Image(systemName: "link")
                    Text("连接健康App")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.red)
                .cornerRadius(12)
            }
            
            Text("可以稍后在设置中连接")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private func requestHealthAuthorization() {
        Task {
            _ = await healthManager.requestAuthorization()
        }
    }
}

struct CompletionPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.waterminderSuccess.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.waterminderSuccess)
            }
            
            VStack(spacing: 12) {
                Text("一切就绪！")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                
                Text("开始您的健康喝水之旅吧\n每一天都是更好的自己")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Button Styles

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(Color.waterminderPrimary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.waterminderPrimary)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(Color.waterminderPrimary.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState.shared)
            .environmentObject(NotificationManager.shared)
            .environmentObject(HealthManager.shared)
    }
}
