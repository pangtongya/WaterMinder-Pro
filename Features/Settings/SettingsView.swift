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

    @ObservedObject private var backupManager = DataBackupManager.shared
    
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
        ScrollView {
            VStack(spacing: 24) {
                // 我的植物
                plantSection
                
                // 每日目标
                goalSection
                
                // 提醒
                reminderSection
                
                // 外观
                themeSection
                
                // 健康 App
                healthSection
                
                // iCloud
                cloudSection
                
                // Bloom Pro
                proSection
                
                // 数据备份
                backupSection
                
                // 关于
                achievementAndStatsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.bloomBackground)
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
        VStack(spacing: 8) {
            SectionHeader("我的植物".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    // 植物名字
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "sprout",
                            backgroundColor: Color.bloomPrimaryMuted,
                            iconColor: Color.bloomPrimary
                        )
                        
                        Text("植物名字".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        TextField("小绿", text: nameBinding)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 可以添加编辑功能
                    }
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 品种
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "flower-2",
                            backgroundColor: Color.bloomWaterMuted,
                            iconColor: Color.bloomWater
                        )
                        
                        Text("品种".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        Text(plantEngine.plant.species.localizedName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                        
                        Text(plantEngine.plant.species.symbol)
                            .font(.system(size: 13))
                            .accessibilityHidden(true)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 暂停/恢复养护
                    if plantEngine.plant.isPaused {
                        Button {
                            showResumeAlert = true
                            Haptics.light()
                        } label: {
                            HStack(spacing: 12) {
                                IconCircle(
                                    icon: "pause-circle",
                                    backgroundColor: Color.bloomWarning.opacity(0.15),
                                    iconColor: Color.bloomWarning
                                )
                                
                                Text("恢复养护".localized)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.bloomTextPrimary)
                                
                                Spacer()
                                
                                Text(String(format: L.daysRemaining, plantEngine.plant.remainingPauseDays))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.bloomTextSecondary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            showPauseConfirm = true
                            Haptics.light()
                        } label: {
                            HStack(spacing: 12) {
                                IconCircle(
                                    icon: "pause-circle",
                                    backgroundColor: Color.bloomWarning.opacity(0.15),
                                    iconColor: Color.bloomWarning
                                )
                                
                                Text("暂停养护".localized)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.bloomTextPrimary)
                                
                                Spacer()
                                
                                Text("出差/旅行".localized)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.bloomTextSecondary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
        VStack(spacing: 8) {
            SectionHeader("每日目标".localized)
            
            SurfaceCard(padding: 16) {
                VStack(spacing: 12) {
                    // 目标选择按钮
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([1500, 2000, 2500, 3000, 3500], id: \.self) { goal in
                                Button {
                                    Haptics.light()
                                    userStore.setDailyGoal(goal)
                                } label: {
                                    Text("\(goal)ml")
                                        .font(.system(size: 13, weight: userStore.dailyGoal == goal ? .semibold : .medium))
                                        .foregroundStyle(userStore.dailyGoal == goal ? .white : Color.bloomTextSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            userStore.dailyGoal == goal ?
                                            Color.bloomPrimary :
                                            Color.bloomSurfaceSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 提示文本
                    Text("建议成人每日饮水 2000ml".localized)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - 提醒

    private var reminderSection: some View {
        VStack(spacing: 8) {
            SectionHeader("提醒".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    // 喝水提醒 Toggle
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "bell",
                            backgroundColor: Color.bloomPrimaryMuted,
                            iconColor: Color.bloomPrimary
                        )
                        
                        Text("喝水提醒".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: reminderBinding)
                            .labelsHidden()
                            .tint(Color.bloomPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if userStore.reminderEnabled {
                        Divider()
                            .padding(.leading, 68)
                        
                        // 提醒间隔
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "clock",
                                backgroundColor: Color.bloomWaterMuted,
                                iconColor: Color.bloomWater
                            )
                            
                            Text("提醒间隔".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Menu {
                                ForEach([30, 60, 90, 120], id: \.self) { interval in
                                    Button {
                                        handleIntervalChange(interval)
                                    } label: {
                                        Text(String(format: NSLocalizedString("每 %d 分钟", comment: "Every X minutes"), interval))
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(String(format: NSLocalizedString("每 %d 分钟", comment: "Every X minutes"), userStore.reminderInterval))
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.bloomTextSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color.bloomTextTertiary)
                                }
                            }
                            .menuStyle(.borderlessButton)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { userStore.reminderEnabled },
            set: { enabled in handleReminderToggle(enabled) }
        )
    }

    private func handleIntervalChange(_ interval: Int) {
        Haptics.light()
        userStore.setReminderInterval(interval)
        Task {
            await notificationManager.scheduleSmartReminder(
                intervalMinutes: interval,
                health: plantEngine.plant.health,
                plantName: plantEngine.plant.name
            )
        }
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

    // MARK: - 主题

    private var themeSection: some View {
        VStack(spacing: 8) {
            SectionHeader("外观".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    // 模式选择
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "sun-moon",
                            backgroundColor: Color.bloomFill,
                            iconColor: Color.bloomTextSecondary
                        )
                        
                        Text("模式".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        SegmentedPicker(
                            selection: Binding(
                                get: { userStore.theme.rawValue },
                                set: { newValue in
                                    if let theme = AppTheme(rawValue: newValue) {
                                        userStore.setTheme(theme)
                                        Haptics.light()
                                    }
                                }
                            ),
                            options: AppTheme.allCases.map { $0.rawValue },
                            fullWidth: false,
                            fontSize: 11
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 主题颜色
                    NavigationLink(destination: ThemePickerView().environmentObject(userStore)) {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "palette",
                                backgroundColor: Color.bloomPrimaryMuted,
                                iconColor: Color.bloomPrimary
                            )
                            
                            Text("主题颜色".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.bloomPrimary)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.bloomPrimary.opacity(0.3), lineWidth: 1.5)
                                )
                            
                            Text(ThemeManager.shared.currentTheme.name)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.bloomTextTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 健康 App

    private var healthSection: some View {
        VStack(spacing: 8) {
            SectionHeader(L.healthApp)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    // 权限状态
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "heart-pulse",
                            backgroundColor: Color.bloomError.opacity(0.15),
                            iconColor: Color.bloomError
                        )
                        
                        Text(L.connectHealth)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        if healthAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.bloomPrimary)
                                    .accessibilityHidden(true)
                                Text(NSLocalizedString("已连接", comment: "Connected"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.bloomPrimary)
                            }
                        } else {
                            Button {
                                showHealthPermissionSheet = true
                                Haptics.light()
                            } label: {
                                Text(NSLocalizedString("连接", comment: "Connect button"))
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.bloomPrimary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // 已授权时的详细设置
                    if healthAuthorized && healthManager.authorizationStatus == .authorized {
                        Divider()
                            .padding(.leading, 68)
                        
                        healthDetailSettings
                    }
                }
            }
            
            // 未授权时的说明
            if !healthAuthorized {
                Text(NSLocalizedString("Bloom 仅请求饮水量数据，用于将你的喝水记录同步到健康 App，并读取其他 App 记录的喝水数据", comment: "Health data usage explanation"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bloomTextTertiary)
                    .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private var healthDetailSettings: some View {
        // 写入开关
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                IconCircle(
                    icon: "square.and.arrow.up",
                    backgroundColor: Color.bloomInfo.opacity(0.15),
                    iconColor: Color.bloomInfo,
                    size: .small
                )
                
                Text(NSLocalizedString("写入健康 App", comment: "Write to Health App"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.bloomTextPrimary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { healthManager.writeEnabled },
                    set: { newValue in
                        healthManager.writeEnabled = newValue
                        Haptics.light()
                    }
                ))
                    .labelsHidden()
                    .tint(Color.bloomPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.leading, 60)
            
            // 读取开关
            HStack(spacing: 12) {
                IconCircle(
                    icon: "square.and.arrow.down",
                    backgroundColor: Color.bloomSuccess.opacity(0.15),
                    iconColor: Color.bloomSuccess,
                    size: .small
                )
                
                Text(NSLocalizedString("从健康 App 读取", comment: "Read from Health App"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.bloomTextPrimary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { healthManager.readEnabled },
                    set: { newValue in
                        healthManager.readEnabled = newValue
                        Haptics.light()
                    }
                ))
                    .labelsHidden()
                    .tint(Color.bloomPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if healthManager.readEnabled {
                Divider()
                    .padding(.leading, 60)
                
                // 同步频率
                HStack(spacing: 12) {
                    IconCircle(
                        icon: "arrow.clockwise",
                        backgroundColor: Color.bloomWarning.opacity(0.15),
                        iconColor: Color.bloomWarning,
                        size: .small
                    )
                    
                    Text(NSLocalizedString("同步频率", comment: "Sync frequency"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(HealthSyncService.SyncFrequency.allCases, id: \.self) { freq in
                            Button {
                                healthSyncService.syncFrequency = freq
                                Haptics.light()
                            } label: {
                                Text(freq.localizedDescription)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(healthSyncService.syncFrequency.localizedDescription)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.bloomTextTertiary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 60)
                
                // 立即同步
                Button {
                    Task {
                        await performManualSync()
                    }
                } label: {
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "arrow.triangle.2.circlepath",
                            backgroundColor: Color.bloomPrimaryMuted,
                            iconColor: Color.bloomPrimary,
                            size: .small
                        )
                        
                        Text(NSLocalizedString("立即同步", comment: "Sync now"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        if healthSyncService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(healthSyncService.isSyncing)
            }
            
            Divider()
                .padding(.leading, 60)
            
            // 隐私说明
            Button {
                showHealthPrivacyInfo = true
                Haptics.light()
            } label: {
                HStack(spacing: 12) {
                    IconCircle(
                        icon: "hand.raised.fill",
                        backgroundColor: Color.bloomInfo.opacity(0.15),
                        iconColor: Color.bloomInfo,
                        size: .small
                    )
                    
                    Text(NSLocalizedString("数据使用说明", comment: "Data usage explanation"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.leading, 60)
            
            // 清除健康数据
            Button {
                showDeleteHealthDataConfirm = true
                refreshBloomDataCount()
                Haptics.light()
            } label: {
                HStack(spacing: 12) {
                    IconCircle(
                        icon: "trash.fill",
                        backgroundColor: Color.bloomError.opacity(0.15),
                        iconColor: Color.bloomError,
                        size: .small
                    )
                    
                    Text(NSLocalizedString("删除 Bloom 写入的健康数据", comment: "Delete Bloom Health data"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomError)
                    
                    Spacer()
                    
                    if isClearingHealthData {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(isClearingHealthData)
        }
    }

    // MARK: - iCloud 同步

    private var cloudSection: some View {
        VStack(spacing: 8) {
            SectionHeader("iCloud".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    Button {
                        handleCloudSyncTap()
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "cloud",
                                backgroundColor: Color.bloomInfo.opacity(0.15),
                                iconColor: cloudIconColor
                            )
                            
                            Text("iCloud 同步".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            syncStatusView
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(cloudSyncManager.isSyncing)
                    
                    if let lastSync = cloudSyncManager.lastSyncDate {
                        Divider()
                            .padding(.leading, 68)
                        
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "clock",
                                backgroundColor: Color.bloomFill,
                                iconColor: Color.bloomTextSecondary,
                                size: .small
                            )
                            
                            Text("上次同步".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Text(lastSync.relativeDescription)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    if case .failed(let error) = cloudSyncManager.syncStatus {
                        Divider()
                            .padding(.leading, 68)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.bloomWarning)
                                    .font(.system(size: 14))
                                    .accessibilityHidden(true)
                                
                                Text(error.errorDescription ?? "同步失败".localized)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.bloomTextSecondary)
                            }
                            
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                            
                            HStack(spacing: 8) {
                                if error.canRetry {
                                    Button {
                                        Task {
                                            await cloudSyncManager.retryLastSync()
                                            Haptics.light()
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
                                    .buttonStyle(.plain)
                                }
                                
                                if error.showsSettingsButton {
                                    Button {
                                        cloudSyncManager.openSystemSettings()
                                        Haptics.light()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "gearshape.fill")
                                                .font(.system(size: 11, weight: .semibold))
                                            Text("去设置".localized)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(Color.bloomPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.bloomPrimary.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            Text(cloudSectionFooter)
                .font(.system(size: 12))
                .foregroundStyle(Color.bloomTextTertiary)
                .padding(.horizontal, 16)
        }
    }
    
    private var syncStatusView: some View {
        Group {
            if cloudSyncManager.isSyncing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .accessibilityHidden(true)
                    Text(syncProgressText)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
            } else if case .failed = cloudSyncManager.syncStatus {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.bloomWarning)
                    .accessibilityLabel("同步失败".localized)
            } else if cloudSyncManager.isSyncAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.bloomSuccess)
                    .accessibilityLabel(NSLocalizedString("已同步", comment: "Synced"))
            } else {
                Text("未登录".localized)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
        }
    }
    
    private var cloudIconColor: Color {
        if cloudSyncManager.isSyncing {
            return Color.bloomWarning
        } else if case .failed = cloudSyncManager.syncStatus {
            return Color.bloomWarning
        } else if cloudSyncManager.isSyncAvailable {
            return Color.bloomInfo
        } else {
            return Color.bloomTextSecondary
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
        VStack(spacing: 8) {
            SectionHeader("数据备份".localized)
            
            // 数据概览卡片
            SurfaceCard(padding: 16) {
                HStack(spacing: 0) {
                    summaryItem(
                        title: "喝水记录",
                        value: "\(waterStore.records.count)",
                        icon: "drop.fill",
                        color: Color.bloomWater
                    )
                    summaryItem(
                        title: "养成天数",
                        value: "\(daysSincePlanted)",
                        icon: "leaf.fill",
                        color: Color.bloomSuccess
                    )
                    summaryItem(
                        title: "成就",
                        value: "\(achievementStore.unlockedCount)/\(achievementStore.totalCount)",
                        icon: "trophy.fill",
                        color: Color.bloomGold
                    )
                    summaryItem(
                        title: "收藏品种",
                        value: "\(gardenStore.items.count)",
                        icon: "tray.full.fill",
                        color: Color.bloomWarning
                    )
                }
            }
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
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
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "square.and.arrow.up",
                                backgroundColor: Color.bloomInfo.opacity(0.15),
                                iconColor: Color.bloomInfo
                            )
                            
                            Text("导出数据备份".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            if backupManager.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(backupManager.isExporting)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 导入按钮
                    Button {
                        showFilePicker = true
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "square.and.arrow.down",
                                backgroundColor: Color.bloomSuccess.opacity(0.15),
                                iconColor: Color.bloomSuccess
                            )
                            
                            Text("从备份恢复".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            if backupManager.isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(backupManager.isImporting)
                    
                    if let lastBackup = backupManager.lastBackupDate {
                        Divider()
                            .padding(.leading, 68)
                        
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "clock",
                                backgroundColor: Color.bloomFill,
                                iconColor: Color.bloomTextSecondary,
                                size: .small
                            )
                            
                            Text("上次备份".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Text(lastBackup.relativeDescription)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            Text("导出 JSON 文件可保存到 Files App，用于数据备份或迁移".localized)
                .font(.system(size: 12))
                .foregroundStyle(Color.bloomTextTertiary)
                .padding(.horizontal, 16)
        }
    }

    private func summaryItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .accessibilityHidden(true)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(Color.bloomTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var daysSincePlanted: Int {
        Calendar.current.dateComponents([.day], from: plantEngine.plant.plantedAt, to: Date()).day ?? 0
    }

    // MARK: - Pro

    private var proSection: some View {
        VStack(spacing: 8) {
            SectionHeader("Bloom Pro".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    if storeManager.isPro {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "sparkles",
                                backgroundColor: Color.bloomGoldMuted,
                                iconColor: Color.bloomGold
                            )
                            
                            Text("Bloom Pro 已解锁".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.bloomSuccess)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    } else {
                        Button {
                            showPaywall = true
                            Haptics.light()
                        } label: {
                            HStack(spacing: 12) {
                                IconCircle(
                                    icon: "sparkles",
                                    backgroundColor: Color.bloomGoldMuted,
                                    iconColor: Color.bloomGold
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("升级 Bloom Pro".localized)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.bloomTextPrimary)
                                    
                                    Text("解锁更多品种".localized)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.bloomTextSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color.bloomTextTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 成就和高级统计

    private var achievementAndStatsSection: some View {
        VStack(spacing: 8) {
            SectionHeader("关于".localized)
            
            SurfaceCard(padding: 0) {
                VStack(spacing: 0) {
                    // 成就
                    NavigationLink(destination: AchievementView().environmentObject(achievementStore)) {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "trophy",
                                backgroundColor: Color.bloomGoldMuted,
                                iconColor: Color.bloomGold
                            )
                            
                            Text("成就".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Text("\(achievementStore.unlockedCount)/\(achievementStore.totalCount)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.bloomTextTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 高级统计 (Pro teaser)
                    Button {
                        if userStore.isPro {
                            showAdvancedStats = true
                        } else {
                            showPaywall = true
                        }
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "bar-chart-3",
                                backgroundColor: Color.bloomGoldMuted,
                                iconColor: Color.bloomGold
                            )
                            
                            Text("高级统计".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            if !userStore.isPro {
                                Badge("Pro", style: .gold)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.bloomTextTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 隐私政策
                    Button {
                        openURL(AppConstants.URLs.privacyPolicy)
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "hand",
                                backgroundColor: Color.bloomInfo.opacity(0.15),
                                iconColor: Color.bloomInfo
                            )
                            
                            Text("隐私政策".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.bloomTextTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 版本号
                    HStack(spacing: 12) {
                        IconCircle(
                            icon: "info",
                            backgroundColor: Color.bloomFill,
                            iconColor: Color.bloomTextSecondary
                        )
                        
                        Text("版本".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.bloomTextPrimary)
                        
                        Spacer()
                        
                        Text(appVersion)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // 恢复购买
                    Button {
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
                        Haptics.light()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircle(
                                icon: "arrow.clockwise",
                                backgroundColor: Color.bloomPrimaryMuted,
                                iconColor: Color.bloomPrimary
                            )
                            
                            Text("恢复购买".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.bloomTextPrimary)
                            
                            Spacer()
                            
                            if isRestoringPurchase {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRestoringPurchase)
                }
            }
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        EmptyView()
    }
    
    /// 从 Bundle 获取 App 版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
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
                        .accessibilityHidden(true)
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
                            .buttonStyle(.plain)
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
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
                            .accessibilityHidden(true)
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
                    .accessibilityHidden(true)
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
                            .accessibilityHidden(true)
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