// SettingsView.swift
// 设置页面

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var showingResetAlert = false
    @State private var showingHealthAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // 饮水目标设置
                Section(header: Text("饮水目标")) {
                    HStack {
                        Text("每日目标")
                        Spacer()
                        TextField("2000", text: $appState.dailyGoalText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("ml")
                            .foregroundColor(.secondary)
                    }
                    
                    // 快捷设置按钮
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {                        let quickGoals = [1500, 2000, 2500, 3000]
                            ForEach(quickGoals, id: \.self) { goal in
                                Button("\(goal)ml") {
                                    appState.dailyGoal = goal
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(appState.dailyGoal == goal ? Color.blue : Color(.tertiarySystemBackground))
                                .foregroundColor(appState.dailyGoal == goal ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 提醒设置
                Section(header: Text("提醒设置")) {
                    Toggle("开启提醒", isOn: $appState.reminderEnabled)
                        .onChange(of: appState.reminderEnabled) { newValue in
                            handleReminderToggle(newValue)
                        }
                    
                    if appState.reminderEnabled {
                        Picker("提醒间隔", selection: $appState.reminderInterval) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { interval in
                                Text("\(interval)分钟").tag(interval)
                            }
                        }
                        .onChange(of: appState.reminderInterval) { _ in
                            notificationManager.scheduleWaterReminder(interval: appState.reminderInterval)
                        }
                    }
                }
                
                // 健康App集成
                Section(header: Text("健康App")) {
                    Button(action: requestHealthAuthorization) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("连接健康App")
                            Spacer()
                            if healthManager.isAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    if healthManager.isAuthorized {
                        Text("已连接，喝水记录将自动同步")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 外观设置
                Section(header: Text("外观")) {
                    Picker("主题", selection: $appState.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.rawValue)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 数据管理
                Section(header: Text("数据管理")) {
                    Button("导出数据") {
                        exportData()
                    }
                    
                    Button("重置所有数据") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("隐私政策") {
                        openPrivacyPolicy()
                    }
                    
                    Button("评价我们") {
                        rateApp()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("设置")
            .alert("重置确认", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("此操作将删除所有喝水记录和个人设置，且不可恢复。确定要继续吗？")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    notificationManager.scheduleWaterReminder(interval: appState.reminderInterval)
                } else {
                    appState.reminderEnabled = false
                    showingHealthAlert = true
                }
            }
        } else {
            notificationManager.cancelWaterReminders()
        }
    }
    
    private func requestHealthAuthorization() {
        Task {
            let granted = await healthManager.requestAuthorization()
            if !granted {
                showingHealthAlert = true
            }
        }
    }
    
    private func exportData() {
        // TODO: 实现数据导出功能
        print("[SettingsView] Export data")
    }
    
    private func resetAllData() {
        // TODO: 实现数据重置功能
        print("[SettingsView] Reset all data")
    }
    
    private func openPrivacyPolicy() {
        // TODO: 打开隐私政策页面
        print("[SettingsView] Open privacy policy")
    }
    
    private func rateApp() {
        // TODO: 打开App Store评价页面
        print("[SettingsView] Rate app")
    }
}

// MARK: - AppState Extension
extension AppState {
    var dailyGoalText: String {
        get { "\(dailyGoal)" }
        set {
            if let value = Int(newValue), value > 0 {
                dailyGoal = value
            }
        }
    }
}

// MARK: - HealthManager Extension
extension HealthManager {
    var isAuthorized: Bool {
        // TODO: 实际检查授权状态
        false
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState.shared)
            .environmentObject(NotificationManager.shared)
            .environmentObject(HealthManager.shared)
    }
}
