// OnboardingView.swift
// 应用引导页面

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
        VStack {
            // 页面内容
            TabView(selection: $currentPage) {
                WelcomePageView()
                    .tag(0)
                
                GoalSetupPageView(dailyGoal: $dailyGoal)
                    .tag(1)
                
                ReminderSetupPageView(enableReminder: $enableReminder, reminderInterval: $reminderInterval)
                    .tag(2)
                
                HealthIntegrationPageView()
                    .tag(3)
                
                CompletionPageView()
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // 底部按钮
            VStack(spacing: 16) {
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // 导航按钮
                HStack {
                    if currentPage > 0 {
                        Button("上一步") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    if currentPage < 4 {
                        Button(currentPage == 3 ? "跳过" : "下一步") {
                            withAnimation {
                                if currentPage == 3 {
                                    currentPage = 4
                                } else {
                                    currentPage += 1
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("开始使用") {
                            completeOnboarding()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Private Methods
    
    private func completeOnboarding() {
        // 保存设置
        appState.dailyGoal = dailyGoal
        appState.reminderEnabled = enableReminder
        appState.reminderInterval = reminderInterval
        
        // 设置提醒
        if enableReminder {
            Task {
                await notificationManager.requestAuthorization()
                notificationManager.scheduleWaterReminder(interval: reminderInterval)
            }
        }
        
        // 标记引导完成
        appState.hasCompletedOnboarding = true
        appState.save()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Welcome Page
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 应用图标
            Image(systemName: "drop.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("欢迎使用 WaterMinder")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("智能喝水提醒，帮您保持健康的水分摄入")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

// MARK: - Goal Setup Page
struct GoalSetupPageView: View {
    @Binding var dailyGoal: Int
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("设置每日饮水目标")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("建议每日饮水 \(2000)ml，您可以根据需要调整")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 目标选择器
            VStack(spacing: 16) {
                TextField("2000", value: $dailyGoal, formatter: NumberFormatter())
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                
                Text("毫升 (ml)")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                // 快捷设置
                HStack(spacing: 12) {
                    ForEach([1500, 2000, 2500, 3000], id: \.self) { goal in
                        Button("\(goal)ml") {
                            dailyGoal = goal
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(dailyGoal == goal ? Color.blue : Color(.tertiarySystemBackground))
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

// MARK: - Reminder Setup Page
struct ReminderSetupPageView: View {
    @Binding var enableReminder: Bool
    @Binding var reminderInterval: Int
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("设置喝水提醒")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("开启提醒后，我们会定时提醒您喝水")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 提醒设置
            VStack(spacing: 20) {
                Toggle("开启提醒", isOn: $enableReminder)
                    .padding(.horizontal, 32)
                
                if enableReminder {
                    VStack(spacing: 12) {
                        Text("提醒间隔")
                            .font(.system(size: 16, weight: .medium))
                        
                        Picker("间隔", selection: $reminderInterval) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { interval in
                                Text("\(interval)分钟").tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 32)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Health Integration Page
struct HealthIntegrationPageView: View {
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("连接健康App")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("将您的喝水记录同步到健康App，获得更全面的健康数据")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: requestHealthAuthorization) {
                HStack {
                    Image(systemName: "link")
                    Text("连接健康App")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    private func requestHealthAuthorization() {
        Task {
            await healthManager.requestAuthorization()
        }
    }
}

// MARK: - Completion Page
struct CompletionPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("设置完成！")
                    .font(.system(size: 28, weight: .bold))
                
                Text("现在开始您的健康喝水之旅吧！")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
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
