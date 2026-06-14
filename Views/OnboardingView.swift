// OnboardingView.swift
// 引导页面 - 极简1步：欢迎+开始使用

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
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
        // 使用默认设置：目标2000ml，不开启提醒，稍后可在设置中调整
        appState.dailyGoal = 2000
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
