// OnboardingView.swift
// 引导页 —— Apple 风格全屏设计
//
// 第1页 欢迎页：养成喝水好习惯，让植物成长
// 第2页 核心玩法：每次喝水，植物都会茁壮成长
// 第3页 提醒功能：智能提醒，不再忘记喝水
// 第4页 开始设置：设置每日目标、植物命名、通知权限

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var currentPage = 0
    @State private var plantName = L.defaultPlantName
    @State private var selectedGoal = {
        let locale = Locale.current.identifier
        return locale.contains("US") ? 2400 : 2000
    }()
    @State private var selectedReminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    @State private var enableHealthKit = false
    @State private var showPlantAnimation = false
    @State private var contentOpacity: Double = 0
    @State private var iconScale: Double = 0.8
    @State private var bellBounce = false
    
    // 页面总数
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            // 渐变背景
            gradientBackground
            
            VStack(spacing: 0) {
                // 进度指示器
                pageIndicator
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                
                // 页面内容
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    gameplayPage.tag(1)
                    reminderPage.tag(2)
                    setupPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                contentOpacity = 1
                iconScale = 1.0
            }
        }
    }
    
    // MARK: - 渐变背景
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color.bloomPrimary.opacity(0.1),
                Color.bloomWater.opacity(0.15),
                Color.bloomSecondary.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - 页面指示器
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? Color.bloomPrimary : Color.bloomPrimary.opacity(0.3))
                    .frame(width: currentPage == index ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - 第1页：欢迎页
    
    private var welcomePage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 大图标
            ZStack {
                Circle()
                    .fill(Color.bloomPrimary.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color.bloomPrimary)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    .scaleEffect(iconScale)
            }
            
            VStack(spacing: 16) {
                Text("养成喝水好习惯")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomTextPrimary)
                
                Text("让植物茁壮成长")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomPrimary)
                
                Text("每次喝水，你的植物都会长大一点")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // 下一步按钮
            nextButton(title: "开始") {
                withAnimation {
                    currentPage = 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 40)
        .opacity(contentOpacity)
    }
    
    // MARK: - 第2页：核心玩法
    
    private var gameplayPage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 植物动画预览
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.bloomSurfaceSecondary)
                    .frame(width: 280, height: 320)
                    .shadow(color: Color.bloomPrimary.opacity(0.2), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    // 植物生长动画
                    AnimatedPlantView(
                        plant: Plant(
                            stage: showPlantAnimation ? .seedling : .seed,
                            health: showPlantAnimation ? 85 : 50
                        )
                    )
                    .frame(width: 140, height: 160)
                    
                    Text(showPlantAnimation ? "🌱 种子发芽了！" : "🌰 一颗小种子")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
            }
            .scaleEffect(iconScale)
            
            VStack(spacing: 16) {
                Text("每次喝水")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomTextPrimary)
                
                Text("植物都会茁壮成长")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomPrimary)
                
                Text("坚持喝水，看着你的植物从种子成长为美丽的花朵")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // 演示按钮
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showPlantAnimation = true
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("点击浇水试试")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.bloomWater)
                .clipShape(Capsule())
            }
            .opacity(showPlantAnimation ? 0 : 1)
            
            nextButton(title: "下一步") {
                withAnimation {
                    currentPage = 2
                    // 重置动画状态
                    showPlantAnimation = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 40)
        .opacity(contentOpacity)
    }
    
    // MARK: - 第3页：提醒功能
    
    private var reminderPage: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 提醒图标
            ZStack {
                Circle()
                    .fill(Color.bloomWater.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                VStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(Color.bloomWater)
                        .opacity(bellBounce ? 1 : 0.8)
                        .scaleEffect(bellBounce ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bellBounce)
                        .onAppear { bellBounce = true }
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.bloomPrimary)
                        .offset(y: -8)
                }
                .scaleEffect(iconScale)
            }
            
            VStack(spacing: 16) {
                Text("智能提醒")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomTextPrimary)
                
                Text("不再忘记喝水")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomWater)
                
                Text("植物口渴时会提醒你，让它保持生机勃勃")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.bloomTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            nextButton(title: "下一步") {
                withAnimation {
                    currentPage = 3
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 40)
        .opacity(contentOpacity)
    }
    
    // MARK: - 第4页：设置页
    
    private var setupPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 设置图标
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.bloomPrimary)
                .symbolEffect(.appear, options: .repeating.speed(0.3))
                .scaleEffect(iconScale)
            
            Text("开始设置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.bloomTextPrimary)
            
            // 设置内容
            VStack(spacing: 24) {
                // 植物命名
                VStack(alignment: .leading, spacing: 8) {
                    Text("给你的植物起个名字")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextSecondary)
                    
                    TextField("小绿", text: $plantName)
                        .font(.system(size: 18, weight: .medium))
                        .padding(16)
                        .background(Color.bloomSurfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: plantName) { _, _ in
                            if plantName.count > 8 {
                                plantName = String(plantName.prefix(8))
                            }
                        }
                }
                
                // 目标水量
                VStack(alignment: .leading, spacing: 8) {
                    Text("每日喝水目标")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextSecondary)
                    
                    // 目标选择按钮
                    HStack(spacing: 12) {
                        ForEach(Locale.current.identifier.contains("US") ? [1800, 2400, 3000, 3600] : [1500, 2000, 2500, 3000], id: \.self) { goal in
                            Button {
                                Haptics.light()
                                selectedGoal = goal
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(goal)")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    if Locale.current.identifier.contains("US") {
                                        Text("\(Int(Double(goal) / 29.574))oz")
                                            .font(.system(size: 11))
                                            .foregroundStyle(selectedGoal == goal ? .white.opacity(0.8) : .secondary)
                                    } else {
                                        Text("ml")
                                            .font(.system(size: 11))
                                            .foregroundStyle(selectedGoal == goal ? .white.opacity(0.8) : .secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(selectedGoal == goal ? .white : .primary)
                                .background(selectedGoal == goal ? Color.bloomPrimary : Color.bloomSurfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    Text(Locale.current.identifier.contains("US")
                         ? "基于美国标准：每天 8 杯 × 8oz ≈ 2400ml"
                         : "基于中国卫健委建议：每日 2000ml")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
                
                // HealthKit 权限（可选）
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.bloomDanger)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("连接健康 App（可选）")
                                .font(.system(size: 16, weight: .medium))
                            Text("同步喝水记录到健康 App")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.bloomTextSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $enableHealthKit)
                            .labelsHidden()
                            .tint(Color.bloomPrimary)
                    }
                    .padding(16)
                    .background(Color.bloomSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // 完成按钮
            finishButton
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 40)
        .opacity(contentOpacity)
    }
    
    // MARK: - 通用按钮
    
    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.bloomPrimary, Color.bloomSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private var finishButton: some View {
        Button {
            finishOnboarding()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("开始养护")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.bloomPrimary, Color.bloomSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - 完成引导
    
    private func finishOnboarding() {
        // 保存用户配置
        userStore.setDailyGoal(selectedGoal)
        
        // 种下新植物（用用户起的名字和目标）
        plantEngine.plantNew(
            speciesID: PlantSpecies.sunflower.id,
            name: plantName.isEmpty ? L.defaultPlantName : plantName
        )
        
        // 通知权限
        userStore.setReminder(enabled: true)
        userStore.setReminderInterval(60)
        
        Task {
            // 请求通知权限
            let notificationGranted = await notificationManager.requestAuthorization()
            
            if notificationGranted {
                await notificationManager.scheduleSmartReminder(
                    intervalMinutes: 60,
                    health: 70,
                    plantName: plantName
                )
            }
            
            // HealthKit 权限（如果用户开启了）
            if enableHealthKit {
                let healthGranted = await HealthManager.shared.requestAuthorization()
                if healthGranted {
                    HealthManager.shared.writeEnabled = true
                    HealthManager.shared.readEnabled = true
                }
            }
            
            // 完成引导
            userStore.completeOnboarding()
            Haptics.success()
        }
    }
}

// MARK: - 预览

#Preview {
    OnboardingView()
}