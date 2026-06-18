# WaterMinder Pro 代码审查报告（三）：改进实施方案

> 基于问题报告（文档一）和改进计划（文档二），制定以下具体实施步骤

---

## 实施原则

1. **版本控制优先**：每次修改都通过 git 提交，保留清晰的 commit message
2. **分步实施**：按优先级分组实施，每个 P0 问题单独一个 commit
3. **充分测试**：每次修改后进行构建验证
4. **可回退性**：每个 commit 都可独立回退

---

## 第一阶段：P0 问题修复（解除上架阻塞）

### Step 1.1：修复 Info.plist 配置
**目标文件**：`Info.plist`

**操作步骤**：
1. 删除 `NSUserNotificationUsageDescription`（macOS key）
2. 添加 HealthKit 权限描述
3. 添加出口合规性声明
4. 添加 App Group 权限（如需 Widget 通信）

**Info.plist 应包含的关键条目**：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>WaterMinder</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSHealthShareUsageDescription</key>
    <string>WaterMinder 需要读取您的健康数据，以提供更准确的饮水建议。</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>WaterMinder 需要写入您的饮水量记录，帮助您追踪每日饮水目标。</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
</dict>
</plist>
```

**Git 提交**：
```
git add Info.plist
git commit -m "fix: update Info.plist with correct iOS keys and HealthKit permissions"
```

---

### Step 1.2：修复隐私声明文件
**目标文件**：`PrivacyInfo.xcprivacy`

**操作步骤**：
1. 更新 `PrivacyInfo.xcprivacy` 移除错误的数据类型声明
2. 确保只声明实际使用的数据类型

**修复后的 PrivacyInfo.xcprivacy**：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Git 提交**：
```
git add PrivacyInfo.xcprivacy
git commit -m "fix: update privacy manifest to accurately reflect data collection"
```

---

### Step 1.3：删除语法错误文件
**目标文件**：`Features/Garden/GardenView.swift.broken`

**操作步骤**：
1. 确认主 `GardenView.swift` 文件完整且可编译
2. 删除 `.broken` 后缀文件

**Git 提交**：
```
git rm Features/Garden/GardenView.swift.broken
git commit -m "chore: remove broken GardenView file"
```

---

### Step 1.4：完善本地化
**目标文件**：`L.swift`、`en.lproj/Localizable.strings`、`zh-Hans.lproj/Localizable.strings`

**操作步骤**：
1. 补充 `en.lproj/Localizable.strings` 中的空翻译占位
2. 创建 `zh-Hans.lproj/Localizable.strings` 中文翻译
3. 将所有硬编码中文替换为 `L.xxx` 调用

**创建 zh-Hans.lproj**：
```bash
mkdir -p Resources/zh-Hans.lproj
cp Resources/en.lproj/Localizable.strings Resources/zh-Hans.lproj/
# 然后编辑 zh-Hans.lproj/Localizable.strings 填入中文翻译
```

**需要替换的中文硬编码位置**：
- `GardenView.swift`：多处 Text() 中的中文
- `RootView.swift`：Tab Item labels
- `OnboardingView.swift`：所有中文文本
- `SettingsView.swift`：设置项文字
- `PaywallView.swift`：付费墙文字
- `L.swift`：补充缺失的 key

**Git 提交**：
```
git add Resources/zh-Hans.lproj/
git add Resources/en.lproj/Localizable.strings
git commit -m "feat: add Chinese localization and complete English translations"
```

---

## 第二阶段：P1 问题修复（质量提升）

### Step 2.1：创建常量管理文件
**新建文件**：`Core/Utils/AppConstants.swift`

**内容**：
```swift
import Foundation

enum AppConstants {
    // App Group
    static let appGroupID = "group.com.waterminder.bloom"

    // Widget
    static let widgetKind = "BloomWidget"
    static let widgetRefreshIntentName = "RefreshIntent"

    // UserDefaults Keys
    enum UserDefaultsKeys {
        static let isPro = "isPro"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
    }

    // Notifications
    enum NotificationIdentifiers {
        static let waterReminder = "waterReminder"
        static let goalAchieved = "goalAchieved"
        static let plantWilting = "plantWilting"
    }

    // Limits
    enum Limits {
        static let freeGardenMaxPlants = 5
        static let maxNotificationSize = 4096
    }
}
```

**Git 提交**：
```
git add Core/Utils/AppConstants.swift
git commit -m "refactor: extract constants to AppConstants enum"
```

---

### Step 2.2：统一 App Group ID 引用
**修改文件**：
- `Core/Managers/NotificationContent.swift`
- `Core/Managers/WidgetDataManager.swift`
- `Core/Managers/WidgetRefresher.swift`
- `Core/Stores/WaterStore.swift`
- `Core/Stores/UserStore.swift`

**操作**：将所有硬编码的 `"group.com.waterminder.bloom"` 替换为 `AppConstants.appGroupID`

**Git 提交**：
```
git add Core/Managers/NotificationContent.swift Core/Managers/WidgetDataManager.swift Core/Managers/WidgetRefresher.swift Core/Stores/WaterStore.swift Core/Stores/UserStore.swift
git commit -m "refactor: use AppConstants.appGroupID instead of hardcoded string"
```

---

### Step 2.3：完善 StoreManager 错误处理
**修改文件**：`Core/Managers/StoreManager.swift`

**操作**：
1. 将网络验证移至后台队列
2. 添加重试逻辑
3. 添加沙盒环境检测

**伪代码**：
```swift
// 在 updateProStatus 中
private func updateProStatus() async {
    await MainActor.run { isPro = false }

    // 检测沙盒环境
    #if targetEnvironment(simulator)
    if isSandboxEnvironment {
        await MainActor.run { isPro = true }
        return
    }
    #endif

    // 后台线程验证
    await Task.detached(priority: .userInitiated) {
        let isValid = await self.verifyPurchaseOnServer()
        await MainActor.run {
            self.isPro = isValid
        }
    }.value
}
```

**Git 提交**：
```
git add Core/Managers/StoreManager.swift
git commit -m "fix: improve StoreManager error handling and add sandbox detection"
```

---

### Step 2.4：实现 HealthKit 统一授权
**修改文件**：`Core/Managers/HealthManager.swift`

**操作**：
1. 添加 `requestAuthorizationIfNeeded()` 集中授权方法
2. 在 `BloomApp.swift` 启动时调用

**BloomApp.swift 修改**：
```swift
@main
struct BloomApp: App {
    @StateObject private var healthManager = HealthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserStore())
                .environmentObject(PlantEngine())
                // ... 其他 store
                .onAppear {
                    healthManager.requestAuthorizationIfNeeded()
                }
        }
    }
}
```

**Git 提交**：
```
git add Core/Managers/HealthManager.swift App/BloomApp.swift
git commit -m "feat: centralized HealthKit authorization flow"
```

---

### Step 2.5：实现后台任务调度
**新建文件**：`Core/Managers/BackgroundTaskManager.swift`

**内容概要**：
```swift
import BackgroundTasks
import Combine

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let healthEngine = PlantEngine.shared

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.waterminder.bloom.healthDecay",
            using: nil
        ) { task in
            self.handleHealthDecayTask(task as! BGAppRefreshTask)
        }
    }

    func scheduleHealthDecayTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.waterminder.bloom.healthDecay")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1小时后

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }

    private func handleHealthDecayTask(_ task: BGAppRefreshTask) {
        scheduleHealthDecayTask() // 重新调度下一次

        let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date ?? Date()
        let hoursSinceLastActive = Calendar.current.dateComponents([.hour], from: lastActiveDate, to: Date()).hour ?? 0

        if hoursSinceLastActive > 0 {
            healthEngine.applyOfflineDecay(hours: hoursSinceLastActive)
        }

        task.setTaskCompleted(success: true)
    }
}
```

**修改 PlantEngine.swift**：
```swift
func applyOfflineDecay(hours: Int) {
    for _ in 0..<hours {
        let decay = HealthCalculator.calculateHealthDecay(for: plant)
        plant.health = max(0, plant.health - decay)
    }
    PersistenceManager.shared.save()
}
```

**Git 提交**：
```
git add Core/Managers/BackgroundTaskManager.swift
git commit -m "feat: implement background health decay task"
```

---

### Step 2.6：实现 DataBackupManager 备份功能
**修改文件**：`Core/Managers/DataBackupManager.swift`

**操作**：
1. 实现 `performBackup()` 方法
2. 实现 `restoreFromBackup()` 方法
3. 添加备份文件管理

**Git 提交**：
```
git add Core/Managers/DataBackupManager.swift
git commit -m "feat: implement full backup and restore functionality"
```

---

### Step 2.7：完成 TODO 功能
**修改文件**：多个

**GardenView.swift** - 实现付费墙显示：
```swift
Button("升级 Pro") {
    // 触发付费墙显示
    NotificationCenter.default.post(name: .showPaywall, object: nil)
}
```

**SharingManager.swift** - 实现分享服务：
```swift
// 移除通讯录依赖，改为只分享到系统分享表
func generateShareCard(...) -> UIImage {
    // 生成不含个人联系人的分享图
}
```

**Git 提交**：
```
git add Features/Garden/GardenView.swift Core/Managers/SharingManager.swift
git commit -m "feat: complete TODO implementations for paywall and sharing"
```

---

### Step 2.8：重构 View 业务逻辑
**修改文件**：`Features/Garden/GardenView.swift`

**操作**：将 `waterPlant()` 移至 `PlantEngine`

**PlantEngine 新增方法**：
```swift
func waterPlant(amount: Int, waterStore: WaterStore, healthManager: HealthManager) async {
    waterStore.add(amount: amount, cupType: .medium)
    self.water(amount: amount)

    if waterStore.isGoalMetToday {
        self.processGoalMet()
    }

    if healthManager.isAuthorized {
        try? await healthManager.saveWater(amount)
    }
}
```

**GardenView 简化**：
```swift
private func waterPlant(_ cup: CupType) {
    Task {
        await plantEngine.waterPlant(
            amount: cup.defaultAmount,
            waterStore: waterStore,
            healthManager: healthManager
        )
        splashTrigger += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
```

**Git 提交**：
```
git add Core/Stores/PlantEngine.swift Features/Garden/GardenView.swift
git commit -m "refactor: move business logic from GardenView to PlantEngine"
```

---

### Step 2.9：迁移敏感数据到 Keychain
**新建文件**：`Core/Utils/KeychainManager.swift`

**内容概要**：
```swift
import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.waterminder.bloom"

    func save(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }

    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

**修改 UserStore.swift**：
```swift
// 将 @AppStorage("isPro") 替换为 Keychain 存储
var isPro: Bool {
    get {
        guard let data = KeychainManager.shared.load(for: "isPro") else { return false }
        return Bool.from(data: data) ?? false
    }
    set {
        if let data = newValue.yesData {
            KeychainManager.shared.save(data, for: "isPro")
        } else {
            KeychainManager.shared.delete(for: "isPro")
        }
        objectWillChange.send()
    }
}
```

**Git 提交**：
```
git add Core/Utils/KeychainManager.swift Core/Stores/UserStore.swift
git commit -m "security: migrate sensitive data to Keychain"
```

---

## 第三阶段：P2 问题修复（打磨优化）

### Step 3.1：清理未使用代码
**Git 命令**：
```bash
# 移除 GardenView.swift 中未使用的 import Charts
git add Features/Garden/GardenView.swift
git commit -m "chore: remove unused Chart import"

# 移除被注释的 import Social
git add Core/Managers/SharingManager.swift
git commit -m "chore: remove commented Social framework import"
```

---

### Step 3.2：启用 Preview 代码
**修改文件**：`Features/Statistics/AdvancedStatsView.swift`

**操作**：删除多余的 `//` 前缀，启用 Preview

**Git 提交**：
```
git add Features/Statistics/AdvancedStatsView.swift
git commit -m "chore: enable SwiftUI Preview for AdvancedStatsView"
```

---

### Step 3.3：优化植物动画性能
**修改文件**：`UI/PlantCanvas/AnimatedPlantView.swift`

**操作**：
1. 添加 `animation(_:value:)` 修剪选项
2. 使用 `drawingGroup()` 优化渲染性能

**Git 提交**：
```
git add UI/PlantCanvas/AnimatedPlantView.swift
git commit -m "perf: optimize plant animations"
```

---

### Step 3.4：实现数据归档
**修改文件**：`Core/Stores/WaterStore.swift`

**操作**：
1. 添加 `archiveOldRecords()` 方法
2. 定期归档 90 天前的数据

**Git 提交**：
```
git add Core/Stores/WaterStore.swift
git commit -m "perf: implement data archival for old water records"
```

---

## 第四阶段：App Store 上架准备

### Step 4.1：创建隐私政策页面
**操作**：
1. 创建 `https://yourdomain.com/privacy.html` 隐私政策页面
2. 创建 `https://yourdomain.com/support.html` 支持页面
3. 更新 `app-store-metadata.md` 添加这些 URL

---

### Step 4.2：准备合规截图
**操作**：
1. 准备 6.7"、6.5"、5.5" 截图
2. 录制 App Preview 视频（15-30 秒）
3. 截图需展示实际功能，不可使用占位图

---

### Step 4.3：配置 App Store Connect
**操作**：
1. 创建 App Store Connect 应用记录
2. 填写所有必需的元数据
3. 上传构建版本（通过 Xcode Organizer）
4. 完成内容版权和出口合规性声明
5. 选择正确的年龄分级

---

## 版本控制策略

### Git 分支模型
```
main (保护分支)
├── fix/privacy-info          # P0: 隐私问题修复
├── fix/notification-keys     # P0: 通知配置修复
├── fix/localization          # P0: 本地化完善
├── refactor/app-constants    # P1: 常量提取
├── refactor/keychain         # P1: 安全改进
├── feat/background-tasks     # P1: 后台任务
├── feat/backup-restore       # P1: 备份功能
├── perf/animations           # P2: 动画优化
└── appstore/preparation      # 上架准备
```

### Commit 规范
```
<type>: <subject>

<body>

<footer>
```

**Type**:
- `fix:` - Bug 修复
- `feat:` - 新功能
- `refactor:` - 重构
- `perf:` - 性能优化
- `security:` - 安全改进
- `chore:` - 构建/工具/辅助任务
- `docs:` - 文档更新

### 回退操作
```bash
# 查看最近 commits
git log --oneline -10

# 回退到特定 commit
git revert <commit-hash>

# 或者创建新分支回退
git checkout -b revert-branch main
git revert <commit-hash>
git merge revert-branch
```

---

## 测试计划

### 构建验证（每次修改后）
```bash
xcodebuild -project WaterMinder.xcodeproj \
  -scheme Bloom \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### 功能测试清单
- [ ] 启动 App 无崩溃
- [ ] 完成 onboarding 流程
- [ ] 记录喝水并验证植物动画
- [ ] 验证 HealthKit 数据同步
- [ ] 验证推送通知接收
- [ ] 验证内购流程（沙盒）
- [ ] 验证 Widget 显示
- [ ] 验证数据备份/恢复
- [ ] 验证分享功能

### 审核前检查清单
- [ ] 隐私政策 URL 可访问
- [ ] 支持页面 URL 可访问
- [ ] 所有截图符合 Apple 规范
- [ ] App 名称和描述无违规词汇
- [ ] 年龄分级与内容匹配
- [ ] 出口合规性已声明
- [ ] HealthKit 使用已披露

---

## 实施时间估算

| 阶段 | 任务数 | 建议时间 |
|------|--------|---------|
| P0 修复 | 4 | 2-3 小时 |
| P1 修复 | 9 | 6-8 小时 |
| P2 修复 | 4 | 2-3 小时 |
| App Store 准备 | 3 | 2-3 小时 |
| **总计** | **20** | **12-17 小时** |

---

*实施方案已制定。建议按 P0 → P1 → P2 的顺序依次实施，每个 commit 都经过构建验证后再进行下一步。*
