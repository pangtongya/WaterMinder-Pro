// SettingsView.swift
// 设置页 —— 目标、提醒、主题、健康App、Pro、关于、数据备份

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var gardenStore: GardenStore
    @EnvironmentObject var waterStore: WaterStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    @EnvironmentObject var achievementStore: AchievementStore

    @StateObject private var backupManager = DataBackupManager.shared
    
    @State private var healthAuthorized = false
    @State private var showPaywall = false
    @State private var showAdvancedStats = false
    @State private var showHealthAlert = false
    @State private var showNotificationAlert = false
    @State private var showFilePicker = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreError = false
    @State private var showBackupSuccess = false
    @State private var showBackupError = false
    @State private var errorMessage = ""
    @State private var exportedFileURL: URL?
    @State private var showExportSheet = false
    @State private var showPauseConfirm = false
    @State private var showResumeAlert = false
    @State private var isRestoringPurchase = false

    var body: some View {
        Form {
            // 植物
            plantSection

            // 饮水目标
            goalSection

            // 提醒
            reminderSection

            // 健康 App
            healthSection

            // 外观
            themeSection

            // iCloud 同步
            cloudSection

            // 数据备份与恢复
            backupSection

            // Pro
            proSection


            // 成就
            NavigationLink(destination: AchievementView().environmentObject(achievementStore)) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.bloomGold)
                    Text("成就".localized)
                    Spacer()
                    Text("\(achievementStore.unlockedCount)/\(achievementStore.totalCount)")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // 高级统计 (Pro teaser)
            Button {
                if userStore.isPro {
                    showAdvancedStats = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label {
                        Text("高级统计".localized)
                            .foregroundColor(.bloomGold)
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.bloomGold)
                    }
                    Spacer()
                    if !userStore.isPro {
                        Text("Pro")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.bloomGold)
                            .clipShape(Capsule())
                    }
                }
            }
            // 关于
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.settings)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { healthAuthorized = healthManager.isAuthorized }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeManager)
        }
        .sheet(isPresented: $showAdvancedStats) {
            AdvancedStatsView()
                .environmentObject(waterStore)
                .environmentObject(userStore)
                .environmentObject(achievementStore)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ActivityViewController(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            Task {
                do {
                    let urls = try result.get()
                    guard let fileURL = urls.first else { return }
                    await restoreBackup(from: fileURL)
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showRestoreError = true
                    }
                }
            }
        }
        .alert("恢复成功".localized, isPresented: $showBackupSuccess) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("数据已成功恢复".localized)
        }
        .alert("恢复失败".localized, isPresented: $showBackupError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("健康权限".localized, isPresented: $showHealthAlert) {
            Button("取消", role: .cancel) {}
            Button("去设置".localized) { openSettings() }
        } message: {
            Text("请在系统设置中允许 Bloom 访问健康数据".localized)
        }
        .alert("通知权限".localized, isPresented: $showNotificationAlert) {
            Button("取消", role: .cancel) {}
            Button("去设置".localized) { openSettings() }
        } message: {
            Text("请在系统设置中允许 Bloom 发送通知".localized)
        }
        .alert("恢复购买成功", isPresented: $showRestoreSuccess) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(L.proThankYou)
        }
        .alert("恢复购买失败", isPresented: $showRestoreError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("暂停养护".localized, isPresented: $showPauseConfirm) {
            Button("取消", role: .cancel) { }
            Button("暂停", role: .destructive) {
                plantEngine.pauseCare()
                Haptics.light()
            }
        } message: {
            Text("暂停期间植物不会枯萎，最长可暂停14天。出差/旅行时非常有用。".localized)
        }
        .alert("恢复养护".localized, isPresented: $showResumeAlert) {
            Button("恢复".localized) {
                plantEngine.resumeCare()
                Haptics.success()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要恢复养护吗？植物将重新开始生长。".localized)
        }
    }

    // MARK: - 植物设置

    private var plantSection: some View {
        Section {
            HStack {
                Text("植物名字".localized)
                Spacer()
                TextField("小绿", text: nameBinding)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }

            HStack {
                Text("品种".localized)
                Spacer()
                Text(plantEngine.plant.species.name)
                    .foregroundStyle(.secondary)
                Text(plantEngine.plant.species.symbol)
            }

            // 暂停/恢复养护
            if plantEngine.plant.isPaused {
                Button(role: .destructive) {
                    showResumeAlert = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                        Text("恢复养护".localized)
                        Spacer()
                        Text(String(format: NSLocalizedString("剩余 %d 天", comment: ""), plantEngine.plant.remainingPauseDays))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    showPauseConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text("暂停养护".localized)
                        Spacer()
                        Text("出差/旅行".localized)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("我的植物".localized)
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { plantEngine.plant.name },
            set: { newName in plantEngine.rename(to: newName) }
        )
    }

    // MARK: - 目标

    private var goalSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([1500, 2000, 2500, 3000, 3500], id: \.self) { goal in
                        Button("\(goal)ml") {
                            Haptics.light()
                            userStore.setDailyGoal(goal)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(userStore.dailyGoal == goal ? Color.bloomPrimary : Color(.tertiarySystemBackground))
                        .foregroundStyle(userStore.dailyGoal == goal ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("每日目标".localized)
        } footer: {
            Text("建议成人每日饮水 2000ml".localized)
        }
    }

    // MARK: - 提醒

    private var reminderSection: some View {
        Section {
            Toggle("喝水提醒", isOn: reminderBinding)
                .tint(Color.bloomPrimary)

            if userStore.reminderEnabled {
                Picker("提醒间隔", selection: intervalBinding) {
                    ForEach([30, 60, 90, 120], id: \.self) {
                        Text(String(format: NSLocalizedString("每 %d 分钟", comment: "Every X minutes"), $0)).tag($0)
                    }
                }
            }
        } header: {
            Text("提醒".localized)
        } footer: {
            Text("开启后，植物口渴时会提醒你来浇水".localized)
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { userStore.reminderEnabled },
            set: { enabled in handleReminderToggle(enabled) }
        )
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { userStore.reminderInterval },
            set: { interval in
                userStore.setReminderInterval(interval)
                notificationManager.scheduleReminder(
                    intervalMinutes: interval,
                    health: plantEngine.plant.health,
                    plantName: plantEngine.plant.name
                )
            }
        )
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    userStore.setReminder(enabled: true)
                    notificationManager.scheduleReminder(
                        intervalMinutes: userStore.reminderInterval,
                        health: plantEngine.plant.health,
                        plantName: plantEngine.plant.name
                    )
                } else {
                    userStore.setReminder(enabled: false)
                    showNotificationAlert = true
                }
            }
        } else {
            userStore.setReminder(enabled: false)
            notificationManager.cancelReminders()
        }
    }

    // MARK: - 健康 App

    private var healthSection: some View {
        Section {
            Button {
                Task {
                    let granted = await healthManager.requestAuthorization()
                    await MainActor.run {
                        healthAuthorized = granted
                        if !granted { showHealthAlert = true }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                    Text("连接健康 App".localized).foregroundStyle(.primary)
                    Spacer()
                    if healthAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("健康 App".localized)
        } footer: {
            Text(healthAuthorized ? "已连接，喝水记录自动同步" : "同步喝水记录到健康 App")
        }
    }

    // MARK: - 主题

    private var themeSection: some View {
        Section {
            Picker("模式", selection: themeBinding) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Label(theme.rawValue, systemImage: theme.icon).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            
            // 主题颜色选择器
            NavigationLink(destination: ThemePickerView().environmentObject(userStore)) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.bloomPrimary)
                    Text("主题颜色".localized)
                    Spacer()
                    Text(ThemeManager.shared.currentTheme.name)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("外观".localized)
        }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(
            get: { userStore.theme },
            set: { userStore.setTheme($0) }
        )
    }

    // MARK: - iCloud 同步

    private var cloudSection: some View {
        Section {
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundStyle(cloudSyncManager.isSyncAvailable ? .blue : .secondary)
                Text("iCloud 同步".localized)
                Spacer()
                if cloudSyncManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if cloudSyncManager.isSyncAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("未登录".localized)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("自动同步到 iCloud，多设备数据保持一致".localized)
        }
    }

    // MARK: - 数据备份与恢复

    private var backupSection: some View {
        Section {
            // 数据概览卡片
            dataSummaryCard
                .listRowBackground(Color(.systemGroupedBackground))
            // 导出按钮
            Button {
                Task {
                    do {
                        let fileURL = try await backupManager.exportAllData(
                            waterStore: waterStore,
                            plantEngine: plantEngine,
                            gardenStore: gardenStore,
                            userStore: userStore,
                            achievementStore: achievementStore
                        )
                        await MainActor.run {
                            exportedFileURL = fileURL
                            showExportSheet = true
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            showRestoreError = true
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.blue)
                    Text("导出数据备份".localized)
                    Spacer()
                    if backupManager.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(backupManager.isExporting)

            // 导入按钮
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.green)
                    Text("从备份恢复".localized)
                    Spacer()
                    if backupManager.isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(backupManager.isImporting)

            // 上次备份时间
            if let lastBackup = backupManager.lastBackupDate {
                HStack {
                    Text("上次备份".localized)
                    Spacer()
                    Text(lastBackup.relativeDescription)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
            }
        } header: {
            Text("数据备份".localized)
        } footer: {
            Text("导出 JSON 文件可保存到 Files App，用于数据备份或迁移".localized)
        }
    }

    // 数据概览卡片
    private var dataSummaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(
                title: "喝水记录",
                value: "\(waterStore.records.count)",
                icon: "drop.fill",
                color: .bloomWater
            )
            summaryItem(
                title: "养成天数",
                value: "\(daysSincePlanted)",
                icon: "leaf.fill",
                color: .green
            )
            summaryItem(
                title: "成就",
                value: "\(achievementStore.unlockedCount)/\(achievementStore.totalCount)",
                icon: "trophy.fill",
                color: .bloomGold
            )
            summaryItem(
                title: "收藏品种",
                value: "\(gardenStore.items.count)",
                icon: "tray.full.fill",
                color: .orange
            )
        }
        .padding(.vertical, 8)
    }

    private func summaryItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var daysSincePlanted: Int {
        Calendar.current.dateComponents([.day], from: plantEngine.plant.plantedAt, to: Date()).day ?? 0
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            if storeManager.isPro {
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(Color.bloomGold)
                    Text("Bloom Pro 已解锁".localized)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(Color.bloomGold)
                        Text("升级 Bloom Pro".localized).foregroundStyle(.primary)
                        Spacer()
                        Text("解锁更多品种".localized)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Bloom Pro")
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本".localized)
                Spacer()
                Text("1.0.0").foregroundStyle(.secondary)
            }
            Button("恢复购买".localized) {
                Task {
                    isRestoringPurchase = true
                    await storeManager.restore()
                    isRestoringPurchase = false
                    
                    if storeManager.isPro {
                        showRestoreSuccess = true
                    } else {
                        errorMessage = "未找到已购买的记录".localized
                        showRestoreError = true
                    }
                }
            }
            .disabled(isRestoringPurchase)
            .overlay {
                if isRestoringPurchase {
                    ProgressView()
                }
            }
            Button {
                openURL("https://pangtongya.github.io/WaterMinder-Pro/privacy-policy.html")
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.blue)
                    Text("隐私政策".localized)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("关于".localized)
        }
    }

    // MARK: - 工具

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func restoreBackup(from fileURL: URL) async {
        do {
            let backup = try await backupManager.importBackup(from: fileURL)
            backupManager.restoreData(
                from: backup,
                waterStore: waterStore,
                plantEngine: plantEngine,
                gardenStore: gardenStore,
                userStore: userStore,
                achievementStore: achievementStore,
                merge: true
            )
            await MainActor.run {
                showBackupSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showBackupError = true
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date 扩展

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// #Preview {
//     NavigationStack {
//         SettingsView()
//             .environmentObject(UserStore())
//             .environmentObject(PlantEngine())
//             .environmentObject(GardenStore())
//             .environmentObject(WaterStore())
//             .environmentObject(NotificationManager.shared)
//             .environmentObject(HealthManager.shared)
//             .environmentObject(StoreManager.shared)
//             .environmentObject(CloudSyncManager.shared)
//     }
// }
