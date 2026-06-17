// OnboardingView.swift
// 引导页 —— 3 步建立情感，chickenfocus 心理学落地
//
// 第1步 概念建立：会动的植物 + "养活它只需你好好喝水"，点浇水按钮→瞬间绽放
// 第2步 个性化：设每日目标 + 给植物起名（情感依恋的关键）
// 第3步 通知权限：用户已爱上这株植物后，再请求通知——"好让它在渴的时候告诉你"

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var plantEngine: PlantEngine
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var step = 1
    @State private var plantName = "小绿"
    @State private var selectedGoal = 2000
    @State private var demoWatered = false  // 第1步浇水演示

    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            progressDots
                .padding(.top, 8)

            // 步骤内容
            TabView(selection: $step) {
                stepOneConcept.tag(1)
                stepTwoPersonalize.tag(2)
                stepThreePermission.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - 进度点

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= step ? Color.bloomPrimary : Color(.tertiarySystemFill))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: step)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - 第1步：概念建立

    private var stepOneConcept: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("🌱 Bloom")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color.bloomPrimary)

            // 演示植物（点击浇水会绽放）
            demoPlant

            VStack(spacing: 10) {
                Text("养活一株植物".localized)
                    .font(.system(size: 24, weight: .bold))
                Text("只需要你好好喝水".localized)
                    .font(.system(size: 24, weight: .bold))
                Text("你每喝一口水，它就长大一点".localized)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            nextButton(title: demoWatered ? "开始养护" : "先浇一次水试试") {
                if demoWatered {
                    withAnimation { step = 2 }
                } else {
                    waterDemo()
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 50)
    }

    private var demoPlant: some View {
        // 演示植物：浇水前蔫，浇水后绽放
        let demoPlant = Plant(
            name: "小绿",
            stage: demoWatered ? .seedling : .seed,
            health: demoWatered ? 90 : 40
        )
        return AnimatedPlantView(plant: demoPlant)
            .frame(width: 200, height: 260)
    }

    private func waterDemo() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            demoWatered = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - 第2步：个性化

    private var stepTwoPersonalize: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("认识一下你的植物".localized)
                .font(.system(size: 24, weight: .bold))

            // 植物名字输入
            VStack(alignment: .leading, spacing: 8) {
                Text("给它起个名字".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                TextField("小绿", text: $plantName)
                    .font(.system(size: 18, weight: .medium))
                    .padding(14)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: plantName) { _ in
                        if plantName.count > 8 { plantName = String(plantName.prefix(8)) }
                    }
            }

            // 目标设置
            VStack(alignment: .leading, spacing: 8) {
                Text("每日喝水目标".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach([1500, 2000, 2500, 3000], id: \.self) { goal in
                        Button {
                            Haptics.light()
                            selectedGoal = goal
                        } label: {
                            Text("\(goal)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(selectedGoal == goal ? .white : .primary)
                                .background(selectedGoal == goal ? Color.bloomPrimary : Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                Text("ml / 天 · 建议成人每日 2000ml".localized)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            nextButton(title: "下一步") {
                withAnimation { step = 3 }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 50)
    }

    // MARK: - 第3步：通知权限

    private var stepThreePermission: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("🔔")
                .font(.system(size: 56))

            VStack(spacing: 10) {
                Text("让 \(plantName) 在渴的时候")
                    .font(.system(size: 24, weight: .bold))
                Text("能告诉你".localized)
                    .font(.system(size: 24, weight: .bold))

                Text("开启通知，它口渴时会提醒你来浇水。\n不开启也可以，但你可能会忘了它。".localized)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 12) {
                nextButton(title: "开启通知") {
                    finishOnboarding(enableNotification: true)
                }

                Button {
                    finishOnboarding(enableNotification: false)
                } label: {
                    Text("暂不开启".localized)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 50)
    }

    // MARK: - 完成

    private func finishOnboarding(enableNotification: Bool) {
        // 保存用户配置
        userStore.setDailyGoal(selectedGoal)
        userStore.setReminder(enabled: enableNotification)

        // 种下新植物（用用户起的名字和目标）
        plantEngine.plantNew(
            speciesID: PlantSpecies.sunflower.id,
            name: plantName.isEmpty ? "小绿" : plantName
        )

        // 通知权限
        if enableNotification {
            userStore.setReminderInterval(60)
            Task {
                let granted = await notificationManager.requestAuthorization()
                if granted {
                    notificationManager.scheduleReminder(
                        intervalMinutes: 60,
                        health: 70,
                        plantName: plantName
                    )
                }
            }
        }

        // 完成引导
        userStore.completeOnboarding()
        Haptics.success()
    }

    // MARK: - 通用按钮

    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.bloomPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - 触觉反馈工具

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserStore())
        .environmentObject(PlantEngine())
        .environmentObject(NotificationManager.shared)
}
