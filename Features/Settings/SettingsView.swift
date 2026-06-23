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
    @EnvironmentObject var healthSyncService: HealthSyncService
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

    // MARK: - HealthKit 相关状态
    
    @State private var showHealthPermissionSheet = false
    @State private var showHealthPrivacyInfo = false
    @State private var showDeleteHealthDataConfirm = false
    @State private var isClearingHealthData = false
    @State private var bloomDataCount: Int? = nil
    @State private var showSyncResult = false
    @State private var syncResultMessage = ""
    @State private var selectedPermissionMode: HealthManager.PermissionMode = .readWrite

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
                        Text("Pro".localized)
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
        .onAppear {
            healthAuthorized = healthManager.isAuthorized
            refreshBloomDataCount()
        }
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
        .sheet(isPresented: $showHealthPermissionSheet) {
            HealthPermissionSheetView(
                selectedMode: $selectedPermissionMode,
                onConfirm: { mode in
                    Task {
                        await requestHealthAuthorization(mode: mode)
                    }
                }
            )
        }
        .sheet(isPresented: $showHealthPrivacyInfo) {
            HealthPrivacyInfoView()
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
            Button(L.ok, role: .cancel) {}
        } message: {
            Text("数据已成功恢复".localized)
        }
        .alert("恢复失败".localized, isPresented: $showBackupError) {
            Button(L.ok, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("健康权限".localized, isPresented: $showHealthAlert) {
            Button("取消".localized, role: .cancel) {}
            Button(L.goToSettings) { openSettings() }
        } message: {
            Text("请在系统设置中允许 Bloom 访问健康数据".localized)
        }
        .alert("通知权限".localized, isPresented: $showNotificationAlert) {
            Button("取消".localized, role: .cancel) {}
            Button(L.goToSettings) { openSettings() }
        } message: {
            Text("请在系统设置中允许 Bloom 发送通知".localized)
        }
        .alert("恢复购买成功".localized, isPresented: $showRestoreSuccess) {
            Button("好的".localized, role: .cancel) {}
        } message: {
            Text(L.proThankYou)
        }
        .alert("恢复购买失败".localized, isPresented: $showRestoreError) {
            Button("好的".localized, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("暂停养护".localized, isPresented: $showPauseConfirm) {
            Button("取消".localized, role: .cancel) { }
            Button("暂停".localized, role: .destructive) {
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
            Button("取消".localized, role: .cancel) { }
        } message: {
            Text("确定要恢复养护吗？植物将重新开始生长。".localized)
        }
        .alert(NSLocalizedString("清除健康数据", comment: "Clear Health data"),
               isPresented: $showDeleteHealthDataConfirm) {
            Button(NSLocalizedString("取消", comment: "Cancel"), role: .cancel) { }
            Button(NSLocalizedString("清除", comment: "Clear"), role: .destructive) {
                clearHealthData()
            }
        } message: {
            Text(String(format: NSLocalizedString("将删除所有由 Bloom 写入健康 App 的喝水记录（共 %@ 条）。此操作不可撤销。", comment: "Confirm delete all Bloom Health data"),
                        bloomDataCount != nil ? "\(bloomDataCount!)" : "--"))
        }
        .alert(NSLocalizedString("同步结果", comment: "Sync result"),
               isPresented: $showSyncResult) {
            Button(L.ok, role: .cancel) { }
        } message: {
            Text(syncResultMessage)
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
                Text(plantEngine.plant.species.localizedName)
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
                        Text(String(format: L.daysRemaining, plantEngine.plant.remainingPauseDays))
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
                Task {
                    await notificationManager.scheduleSmartReminder(
                        intervalMinutes: interval,
                        health: plantEngine.plant.health,
                        plantName: plantEngine.plant.name
                    )
                }
            }
        )
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    userStore.setReminder(enabled: true)
                    await notificationManager.scheduleSmartReminder(
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
            // 权限状态 + 连接/管理按钮
            healthStatusRow

            // 已授权时显示详细设置
            if healthAuthorized && healthManager.authorizationStatus == .authorized {
                healthDetailSettings
            }
        } header: {
            Text(L.healthApp)
        } footer: {
            healthSectionFooter
        }
    }

    private var healthStatusRow: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(healthAuthorized ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(healthAuthorized ? NSLocalizedString("已连接健康 App", comment: "Health App connected") : L.connectHealth)
                    .foregroundStyle(.primary)

                Text(healthManager.authorizationStatus.localizedDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !healthAuthorized {
                Button {
                    showHealthPermissionSheet = true
                } label: {
                    Text(NSLocalizedString("连接", comment: "Connect button"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bloomPrimary)
                        .clipShape(Capsule())
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private var healthDetailSettings: some View {
        // 写入开关
        Toggle(isOn: Binding(
            get: { healthManager.writeEnabled },
            set: { newValue in
                healthManager.writeEnabled = newValue
                Haptics.light()
            }
        )) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
                    .frame(width: 22)
                Text(NSLocalizedString("写入健康 App", comment: "Write to Health App"))
            }
        }
        .tint(Color.bloomPrimary)

        // 读取开关
        Toggle(isOn: Binding(
            get: { healthManager.readEnabled },
            set: { newValue in
                healthManager.readEnabled = newValue
                Haptics.light()
            }
        )) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.green)
                    .frame(width: 22)
                Text(NSLocalizedString("从健康 App 读取", comment: "Read from Health App"))
            }
        }
        .tint(Color.bloomPrimary)

        // 同步频率（仅读取开启时显示）
        if healthManager.readEnabled {
            Picker(selection: Binding(
                get: { healthSyncService.syncFrequency },
                set: { newValue in
                    healthSyncService.syncFrequency = newValue
                    Haptics.light()
                }
            )) {
                ForEach(HealthSyncService.SyncFrequency.allCases, id: \.self) { freq in
                    Text(freq.localizedDescription).tag(freq)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                        .frame(width: 22)
                    Text(NSLocalizedString("同步频率", comment: "Sync frequency"))
                }
            }
            .pickerStyle(.menu)
        }

        // 上次同步时间
        if let lastSync = healthSyncService.lastSyncTime {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .frame(width: 22)
                Text(NSLocalizedString("上次同步", comment: "Last sync"))
                Spacer()
                Text(lastSync.relativeDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }

        // 同步数据量统计
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.purple)
                .frame(width: 22)
            Text(NSLocalizedString("已同步数据量", comment: "Synced data count"))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: NSLocalizedString("写入 %@ 条", comment: "Written count"),
                            "\(healthSyncService.totalWrittenRecords)"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("读取 %@ 条", comment: "Read count"),
                            "\(healthSyncService.totalSyncedRecords)"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }

        // 立即同步按钮
        if healthManager.readEnabled {
            Button {
                Task {
                    await performManualSync()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.bloomPrimary)
                        .frame(width: 22)
                    Text(NSLocalizedString("立即同步", comment: "Sync now"))
                        .foregroundStyle(.primary)
                    Spacer()
                    if healthSyncService.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(healthSyncService.isSyncing)
        }

        // 同步错误提示
        if let error = healthSyncService.lastSyncError, !healthSyncService.isSyncing {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if let recovery = healthSyncService.lastSyncErrorRecovery {
                    Text(recovery)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                }
            }
            .padding(.vertical, 4)
        }

        // 重新授权
        Button {
            openSettings()
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.gray)
                    .frame(width: 22)
                Text(NSLocalizedString("在系统设置中管理权限", comment: "Manage permissions in Settings"))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }

        // 隐私说明
        Button {
            showHealthPrivacyInfo = true
        } label: {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.blue)
                    .frame(width: 22)
                Text(NSLocalizedString("数据使用说明", comment: "Data usage explanation"))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }

        // 清除健康数据
        Button(role: .destructive) {
            showDeleteHealthDataConfirm = true
            refreshBloomDataCount()
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                    .frame(width: 22)
                Text(NSLocalizedString("删除 Bloom 写入的健康数据", comment: "Delete Bloom Health data"))
                    .foregroundStyle(.red)
                Spacer()
                if isClearingHealthData {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .disabled(isClearingHealthData)
    }

    @ViewBuilder
    private var healthSectionFooter: some View {
        if !healthAuthorized {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("Bloom 仅请求饮水量数据，用于：", comment: "Health data usage explanation"))
                Text("• " + NSLocalizedString("将你的喝水记录同步到健康 App", comment: "Sync water records to Health"))
                Text("• " + NSLocalizedString("从健康 App 读取其他 App 记录的喝水数据", comment: "Read water data from other apps"))
                Button {
                    showHealthPrivacyInfo = true
                } label: {
                    Text(NSLocalizedString("了解更多", comment: "Learn more"))
                        .font(.footnote)
                        .foregroundColor(.bloomPrimary)
                }
            }
        } else {
            Text(NSLocalizedString("喝水记录自动同步，数据仅存储在本地和健康 App 中", comment: "Health sync footer when authorized"))
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
            Button {
                handleCloudSyncTap()
            } label: {
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(cloudIconColor)
                    Text("iCloud 同步".localized)
                        .foregroundStyle(.primary)
                    Spacer()
                    syncStatusView
                }
            }
            .disabled(cloudSyncManager.isSyncing)
            
            if let lastSync = cloudSyncManager.lastSyncDate {
                HStack {
                    Text("上次同步".localized)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(lastSync.relativeDescription)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
            }
            
            if case .failed(let error) = cloudSyncManager.syncStatus {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error.errorDescription ?? "同步失败".localized)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        if error.canRetry {
                            Button {
                                Task {
                                    await cloudSyncManager.retryLastSync()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("重试".localized)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.bloomPrimary)
                                .clipShape(Capsule())
                            }
                        }
                        
                        if error.showsSettingsButton {
                            Button {
                                cloudSyncManager.openSystemSettings()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("去设置".localized)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.bloomPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.bloomPrimary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("iCloud".localized)
        } footer: {
            Text(cloudSectionFooter)
        }
    }
    
    private var syncStatusView: some View {
        Group {
            if cloudSyncManager.isSyncing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(syncProgressText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else if case .failed = cloudSyncManager.syncStatus {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            } else if cloudSyncManager.isSyncAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("未登录".localized)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var cloudIconColor: Color {
        if cloudSyncManager.isSyncing {
            return .orange
        } else if case .failed = cloudSyncManager.syncStatus {
            return .orange
        } else if cloudSyncManager.isSyncAvailable {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private var syncProgressText: String {
        switch cloudSyncManager.syncProgress {
        case .downloading:
            return NSLocalizedString("下载中", comment: "Downloading")
        case .merging:
            return NSLocalizedString("合并中", comment: "Merging")
        case .uploading:
            return NSLocalizedString("上传中", comment: "Uploading")
        }
    }
    
    private var cloudSectionFooter: String {
        if !cloudSyncManager.isSyncAvailable {
            return NSLocalizedString("请在系统设置中登录 iCloud 以启用同步", comment: "Sign in to iCloud in Settings to enable sync")
        } else if case .failed(let error) = cloudSyncManager.syncStatus {
            return error.recoverySuggestion ?? "自动同步到 iCloud，多设备数据保持一致".localized
        } else if cloudSyncManager.isSyncing {
            return NSLocalizedString("正在同步数据，请稍候...", comment: "Syncing data, please wait...")
        } else {
            return "自动同步到 iCloud，多设备数据保持一致".localized
        }
    }
    
    private func handleCloudSyncTap() {
        if cloudSyncManager.isSyncAvailable && !cloudSyncManager.isSyncing {
            if case .failed(let error) = cloudSyncManager.syncStatus, error.canRetry {
                Task {
                    await cloudSyncManager.retryLastSync()
                }
            } else {
                Task {
                    await cloudSyncManager.syncAll()
                }
            }
        } else if !cloudSyncManager.isSyncAvailable {
            cloudSyncManager.openSystemSettings()
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
            Text("Bloom Pro".localized)
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本".localized)
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
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
                openURL(AppConstants.URLs.privacyPolicy)
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
            Button {
                openURL(AppConstants.URLs.termsOfService)
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.orange)
                    Text("服务条款".localized)
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
    
    /// 从 Bundle 获取 App 版本号
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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

    // MARK: - HealthKit 操作方法

    private func requestHealthAuthorization(mode: HealthManager.PermissionMode) async {
        showHealthPermissionSheet = false
        let granted = await healthManager.requestAuthorization(mode: mode)
        await MainActor.run {
            healthAuthorized = granted
            if !granted {
                showHealthAlert = true
            } else {
                Haptics.success()
                // 授权成功后执行一次同步
                if mode != .writeOnly {
                    Task {
                        await healthSyncService.sync(waterStore: waterStore, plantEngine: plantEngine)
                    }
                }
            }
        }
    }

    private func performManualSync() async {
        Haptics.light()
        await healthSyncService.sync(waterStore: waterStore, plantEngine: plantEngine)
        await MainActor.run {
            if healthSyncService.lastSyncError == nil {
                syncResultMessage = String(format: NSLocalizedString("同步完成，新增 %d 条记录", comment: "Sync completed with new records"),
                                           healthSyncService.newRecordsCount)
            } else {
                syncResultMessage = healthSyncService.lastSyncError ?? NSLocalizedString("同步失败", comment: "Sync failed")
            }
            showSyncResult = true
        }
    }

    private func clearHealthData() {
        isClearingHealthData = true
        Task {
            do {
                let count = try await healthManager.deleteAllBloomData()
                await MainActor.run {
                    isClearingHealthData = false
                    healthSyncService.resetStats()
                    bloomDataCount = 0
                    syncResultMessage = String(format: NSLocalizedString("已删除 %d 条健康数据", comment: "Deleted N health records"),
                                               count)
                    showSyncResult = true
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    isClearingHealthData = false
                    errorMessage = error.localizedDescription
                    showRestoreError = true
                }
            }
        }
    }

    private func refreshBloomDataCount() {
        guard healthManager.isReadAuthorized else {
            bloomDataCount = nil
            return
        }
        Task {
            do {
                let count = try await healthManager.getBloomDataCount()
                await MainActor.run {
                    bloomDataCount = count
                }
            } catch {
                await MainActor.run {
                    bloomDataCount = nil
                }
            }
        }
    }
}

// MARK: - 健康权限说明 Sheet

struct HealthPermissionSheetView: View {
    @Binding var selectedMode: HealthManager.PermissionMode
    var onConfirm: (HealthManager.PermissionMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部图标
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 20)

                    Text(NSLocalizedString("连接健康 App", comment: "Connect Health App title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(NSLocalizedString("Bloom 需要访问你的健康数据，以提供完整的植物养成体验。", comment: "Health permission explanation"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // 数据用途说明
                    VStack(alignment: .leading, spacing: 12) {
                        permissionItem(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .blue,
                            title: NSLocalizedString("写入数据", comment: "Write data"),
                            description: NSLocalizedString("将你在 Bloom 中记录的喝水数据同步到健康 App", comment: "Write data description")
                        )
                        permissionItem(
                            icon: "square.and.arrow.down.fill",
                            iconColor: .green,
                            title: NSLocalizedString("读取数据", comment: "Read data"),
                            description: NSLocalizedString("从健康 App 读取其他 App 记录的喝水数据", comment: "Read data description")
                        )
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // 隐私承诺
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text(NSLocalizedString("隐私承诺", comment: "Privacy promise"))
                                .font(.headline)
                        }
                        Text("• " + NSLocalizedString("仅请求饮水量数据，不读取其他健康信息", comment: "Only request water data"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("• " + NSLocalizedString("数据仅保存在本地和健康 App 中", comment: "Data stored locally and Health"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("• " + NSLocalizedString("不会上传到任何第三方服务器", comment: "No upload to third parties"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("• " + NSLocalizedString("可随时在设置中关闭或删除数据", comment: "Can disable or delete anytime"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // 权限模式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("选择权限模式", comment: "Choose permission mode"))
                            .font(.headline)

                        ForEach([
                            HealthManager.PermissionMode.readWrite,
                            .writeOnly,
                            .readOnly
                        ], id: \.self) { mode in
                            Button {
                                selectedMode = mode
                                Haptics.light()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(modeTitle(mode))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(modeDescription(mode))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedMode == mode ? .bloomPrimary : .gray)
                                        .font(.system(size: 22))
                                }
                                .padding(14)
                                .background(selectedMode == mode ? Color.bloomPrimary.opacity(0.1) : Color(.tertiarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedMode == mode ? Color.bloomPrimary : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onConfirm(selectedMode)
                        Haptics.light()
                    } label: {
                        Text(NSLocalizedString("继续", comment: "Continue"))
                            .fontWeight(.semibold)
                            .foregroundColor(.bloomPrimary)
                    }
                }
            }
        }
    }

    private func modeTitle(_ mode: HealthManager.PermissionMode) -> String {
        switch mode {
        case .readWrite:
            return NSLocalizedString("读写（推荐）", comment: "Read & Write (Recommended)")
        case .writeOnly:
            return NSLocalizedString("仅写入", comment: "Write only")
        case .readOnly:
            return NSLocalizedString("仅读取", comment: "Read only")
        }
    }

    private func modeDescription(_ mode: HealthManager.PermissionMode) -> String {
        switch mode {
        case .readWrite:
            return NSLocalizedString("完整的双向同步体验", comment: "Full two-way sync experience")
        case .writeOnly:
            return NSLocalizedString("只将 Bloom 的记录同步到健康 App", comment: "Only sync Bloom records to Health")
        case .readOnly:
            return NSLocalizedString("只从健康 App 读取其他记录", comment: "Only read other records from Health")
        }
    }

    private func permissionItem(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 健康隐私说明页

struct HealthPrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部
                    HStack {
                        Image(systemName: "hand.raised.shield")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("健康数据隐私", comment: "Health data privacy"))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(NSLocalizedString("你的数据安全是我们的首要任务", comment: "Your data security is our priority"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)

                    // 数据收集说明
                    privacySection(
                        icon: "drop.fill",
                        iconColor: .bloomWater,
                        title: NSLocalizedString("我们收集什么数据", comment: "What data we collect"),
                        items: [
                            NSLocalizedString("仅请求饮水量（dietaryWater）数据", comment: "Only request dietary water data"),
                            NSLocalizedString("不读取步数、心率、睡眠等其他健康数据", comment: "No steps, heart rate, sleep data"),
                            NSLocalizedString("不读取你的个人身份信息", comment: "No personal identifiable information")
                        ]
                    )

                    // 数据用途
                    privacySection(
                        icon: "leaf.fill",
                        iconColor: .green,
                        title: NSLocalizedString("数据如何使用", comment: "How data is used"),
                        items: [
                            NSLocalizedString("用于植物养成游戏：你喝水，植物成长", comment: "For plant growth game"),
                            NSLocalizedString("生成喝水统计和趋势分析", comment: "Generate water statistics and trends"),
                            NSLocalizedString("在各设备间同步你的喝水记录", comment: "Sync water records across devices"),
                            NSLocalizedString("不会用于广告或用户画像", comment: "Not used for ads or user profiling")
                        ]
                    )

                    // 数据存储
                    privacySection(
                        icon: "lock.shield.fill",
                        iconColor: .blue,
                        title: NSLocalizedString("数据如何存储", comment: "How data is stored"),
                        items: [
                            NSLocalizedString("数据保存在设备本地", comment: "Data stored locally on device"),
                            NSLocalizedString("通过 iCloud 同步时使用端到端加密", comment: "End-to-end encryption with iCloud"),
                            NSLocalizedString("健康 App 数据由 Apple 安全管理", comment: "Health data managed securely by Apple"),
                            NSLocalizedString("我们没有自己的服务器存储你的数据", comment: "We don't have our own servers for your data")
                        ]
                    )

                    // 用户控制权
                    privacySection(
                        icon: "gearshape.fill",
                        iconColor: .orange,
                        title: NSLocalizedString("你的控制权", comment: "Your control"),
                        items: [
                            NSLocalizedString("可随时开启或关闭健康 App 同步", comment: "Enable or disable Health sync anytime"),
                            NSLocalizedString("可单独控制写入和读取权限", comment: "Separate write and read permission controls"),
                            NSLocalizedString("可一键删除所有 Bloom 写入的健康数据", comment: "One-tap delete all Bloom Health data"),
                            NSLocalizedString("可在系统设置中完全撤销授权", comment: "Revoke full authorization in Settings")
                        ]
                    )

                    // 隐私政策链接
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("了解更多", comment: "Learn more"))
                            .font(.headline)

                        Link(destination: URL(string: AppConstants.URLs.privacyPolicy)!) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text(NSLocalizedString("查看完整隐私政策", comment: "View full privacy policy"))
                                    .foregroundColor(.bloomPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(10)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.done) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.bloomPrimary)
                }
            }
        }
    }

    private func privacySection(icon: String, iconColor: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .padding(.top, 2)
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
