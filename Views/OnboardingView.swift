// OnboardingView.swift
// 引导页面 - 欢迎 + 目标设置（1页完整版）

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGoal: Int = 2000
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图标
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
            
            // 文案
            VStack(spacing: 16) {
                Text("WaterMinder")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                
                Text("简单记录每一次喝水\n保持健康的饮水习惯")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 目标设置
            VStack(spacing: 12) {
                Text("每日饮水目标")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([1500, 2000, 2500, 3000], id: \.self) { goal in
                            Button("\(goal)ml") {
                                selectedGoal = goal
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedGoal == goal ? Color.waterminderPrimary : Color(.tertiarySystemBackground))
                            .foregroundColor(selectedGoal == goal ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
            
            // 开始按钮
            Button(action: completeOnboarding) {
                Text("开始使用")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.waterminderPrimary)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
    
    private func completeOnboarding() {
        // 使用用户选择的目标
        appState.dailyGoal = selectedGoal
        appState.reminderEnabled = false
        appState.reminderInterval = 60
        appState.hasCompletedOnboarding = true
        appState.save()
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
}
