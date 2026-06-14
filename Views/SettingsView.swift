// SettingsView.swift
// 设置页面 - 目标、提醒、健康、数据

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var showingResetAlert = false
    @State private var showingHealthAlert = false
    @State private var showingNotificationAlert = false
    @State private var healthAuthorized = false
    @State private var dailyGoalInput: String = ""
    @State private var showingExporter = false
    @State private var exportDataString = ""
    
    var body: some View {
        Form {
            // 饮水目标
            Section {
                HStack {
                    Text("每日目标")
                    Spacer()
                    TextField("2000", text: $dailyGoalInput)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onSubmit { applyDailyGoal() }
                    Text("ml")
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    dailyGoalInput = "\(appState.dailyGoal)"
                }
                .onChange(of: appState.dailyGoal) { newValue in
                    dailyGoalInput = "\(newValue)"
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([1500, 2000, 2500, 3000, 3500], id: \.self) { goal in
                            Button("\(goal)ml") {
                                appState.dailyGoal = goal
                                dailyGoalInput = "\(goal)"
                            }
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(appState.dailyGoal == goal ? Color.waterminderPrimary : Color(.tertiarySystemBackground))
                            .foregroundColor(appState.dailyGoal == goal ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("饮水目标")
            } footer: {
                Text("建议每日饮水 2000ml，可根据个人情况调整")
            }
            
            // 提醒设置
            Section {
                Toggle("开启提醒", isOn: $appState.reminderEnabled)
                    .onChange(of: appState.reminderEnabled) { newValue in
                        handleReminderToggle(newValue)
                    }
                    .tint(.waterminderPrimary)
                
                if appState.reminderEnabled {
                    Picker("提醒间隔", selection: $appState.reminderInterval) {
                        ForEach([30, 45, 60, 90, 120], id: \.self) { interval in
                            Text("每 \(interval) 分钟").tag(interval)
                        }
                    }
                    .onChange(of: appState.reminderInterval) { _ in
                        notificationManager.scheduleWaterReminder(interval: appState.reminderInterval)
                    }
                }
            } header: {
                Text("提醒设置")
            } footer: {
                Text("开启后，应用将按设定间隔发送喝水提醒")
            }
            
            // 健康App集成
            Section {
                Button(action: requestHealthAuthorization) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("连接健康App")
                            .foregroundColor(.primary)
                        Spacer()
                        if healthAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if healthAuthorized {
                    Text("已连接，喝水记录将自动同步到健康App")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("健康App")
            }
            
            // 外观设置
            Section {
                Picker("主题", selection: $appState.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Image(systemName: theme.icon)
                            Text(theme.rawValue)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("外观")
            }
            
            // 数据管理
            Section {
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.waterminderPrimary)
                        Text("导出数据")
                            .foregroundColor(.primary)
                    }
                }
                
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("重置所有数据")
                    }
                }
            } header: {
                Text("数据管理")
            }
            
            // 关于
            Section {
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
            } header: {
                Text("关于")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            healthAuthorized = healthManager.isAuthorized
        }
        .alert("重置确认", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("此操作将删除所有喝水记录和个人设置，且不可恢复。确定要继续吗？")
        }
        .alert("权限提示", isPresented: $showingHealthAlert) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("请在系统设置中允许 WaterMinder 访问健康数据")
        }
        .alert("通知权限", isPresented: $showingNotificationAlert) {
            Button("取消", role: .cancel) { }
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("请在系统设置中允许 WaterMinder 发送通知")
        }
    }
    
    // MARK: - Private Methods
    
    private func applyDailyGoal() {
        if let value = Int(dailyGoalInput), value > 0, value <= 10000 {
            appState.dailyGoal = value
        } else {
            dailyGoalInput = "\(appState.dailyGoal)"
        }
    }
    
    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    notificationManager.scheduleWaterReminder(interval: appState.reminderInterval)
                } else {
                    appState.reminderEnabled = false
                    showingNotificationAlert = true
                }
            }
        } else {
            notificationManager.cancelWaterReminders()
        }
    }
    
    private func requestHealthAuthorization() {
        Task {
            _ = await healthManager.requestAuthorization()
            await MainActor.run {
                healthAuthorized = healthManager.isAuthorized
                if !healthAuthorized {
                    showingHealthAlert = true
                }
            }
        }
    }
    
    private func exportData() {
        let exportData = ExportData(
            version: "1.0.0",
            exportDate: ISO8601DateFormatter().string(from: Date()),
            dailyGoal: appState.dailyGoal,
            totalRecords: recordStore.items.count,
            currentStreak: recordStore.currentStreak,
            longestStreak: recordStore.longestStreak,
            records: recordStore.items.map { record in
                ExportRecord(
                    id: record.id.uuidString,
                    date: ISO8601DateFormatter().string(from: record.createdAt),
                    amount: record.amount,
                    cupType: record.cupType.rawValue,
                    note: record.note ?? ""
                )
            }
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)
            
            // 保存到临时文件用于分享
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WaterMinder_Export_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("[SettingsView] Export error: \(error)")
        }
    }
    
    private func resetAllData() {
        recordStore.items.removeAll()
        recordStore.save()
        
        appState.dailyGoal = 2000
        appState.reminderEnabled = false
        appState.reminderInterval = 60
        appState.theme = .system
        appState.save()
        
        notificationManager.cancelWaterReminders()
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://pangtong.github.io/waterminder/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        // App Store review URL
        if let url = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Export Data Model
struct ExportData: Codable {
    let version: String
    let exportDate: String
    let dailyGoal: Int
    let totalRecords: Int
    let currentStreak: Int
    let longestStreak: Int
    let records: [ExportRecord]
}

struct ExportRecord: Codable {
    let id: String
    let date: String
    let amount: Int
    let cupType: String
    let note: String
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AppState.shared)
                .environmentObject(WaterRecordStore())
                .environmentObject(NotificationManager.shared)
                .environmentObject(HealthManager.shared)
        }
    }
}
