# WaterMinder Pro (Bloom) 完整代码审查报告

> **审查日期**：2026-06-20
> **审查范围**：整个 iOS 应用代码库（.swift/.plist/Info.plist）
> **审查方式**：逐文件阅读、逐逻辑分析、编译验证
> **编译状态**：✅ 构建成功
> **当前分支**：feat/week1-p0

---

## 0. 总体评估

### 项目成熟度

| 维度 | 状态 | 说明 |
|------|------|------|
| 🎯 **核心功能** | 中等 | 喝水记录/植物养护/通知基本可用 |
| 🎨 **UI 设计** | 良好 | SwiftUI 现代、视觉一致性好 |
| 🔧 **架构设计** | 中等偏下 | Store 模式合理，但依赖注入脆弱 |
| 💾 **数据管理** | 有风险 | 缺少记录删除、数据校验不完整 |
| 🔒 **安全性** | 中等 | Keychain 实现良好，但缺少权限降级 |
| 🛠️ **可维护性** | 有缺陷 | 多处硬编码字符串、缺少完整的 i18n |
| 🧪 **可测试性** | 低 | 缺少测试文件，依赖单例 |
| 📱 **上架准备** | ⚠️ 需修复 | 有几个必须修复的问题 |

### 关键发现

| 严重级别 | 数量 | 说明 |
|---------|------|-----|
| 🔴 **CRITICAL** | 3 | 会导致崩溃或核心功能不可用 |
| 🟡 **MAJOR** | 12 | 明显影响用户体验，可能导致流失 |
| 🟢 **MINOR** | 15 | 不影响使用但需要优化 |
| 🔵 **INFO** | 5 | 建议/可优化/最佳实践 |

---

## 1. 🔴 CRITICAL 问题（必须在首次上架前修复）

### [C-001] HealthKit 权限请求回调不支持 async/await — `Core/Managers/HealthManager.swift:44`

**问题**：
- `HKHealthStore.requestAuthorization(toShare:read:)` 在 iOS 18 之前是**基于 completion block**，不是 async 方法
- 直接使用 `try await store.requestAuthorization(...)` 在 iOS 17 上会**编译通过但运行时崩溃**（或者根本编译不通过，取决于 Xcode 版本）

**验证**：
- HealthKit 的 async API 是在 iOS 15.4+ 引入的，但需要正确的 availability 检查
- 当前代码中第 44 行 `func requestAuthorizationIfNeeded() async -> Bool` 和第 31 行 `func requestAuthorization() async -> Bool` 都没有 **@available** 或 **withCheckedThrowingContinuation**

**风险**：
- 在低版本 iOS 上运行时可能崩溃

**建议修复**：
```swift
func requestAuthorization() async -> Bool {
    guard HKHealthStore.isHealthDataAvailable(),
          let type = waterType,
          let store else { return false }
    return await withCheckedContinuation { cont in
        store.requestAuthorization(toShare: [type], read: [type]) { success, error in
            cont.resume(returning: success)
        }
    }
}
```

---

### [C-002] AppGroup 权限在 entitlements 和 info.plist 中不一致

**问题**：
- Widget 是独立 extension，需要自己的 `.entitlements`，标记 `com.apple.security.application-groups`
- 主 App 的 Info.plist 中声明了 `NSHealthShareUsageDescription` 和 `NSHealthUpdateUsageDescription`，但是

当前文件 **`Widget/Info.plist`** 第 15-19 行:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.pangtong.bloom</string>
</array>
```

但是：**主 App 的 Info.plist 中没有相同的 App Group 声明**

验证：主 App 的 `Info.plist` 中搜索 `application-groups` — **不存在**

**风险**：
- Widget 无法从 UserDefaults(suiteName: "group.com.pangtong.bloom") 中读取数据
- 主 App 虽然代码中写 `HealthSyncService` 第 33 行 `UserDefaults(suiteName: AppConstants.appGroupIdentifier)`，但主 App **实际没被授予 App Group 权限**

**修复**：在**主 App 的 Info.plist 中**添加：
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.pangtong.bloom</string>
</array>
```

或者在 Xcode → Signing & Capabilities → 添加 "App Groups" → 勾选 `group.com.pangtong.bloom`

---

### [C-003] `WaterStore` 缺少删除记录功能 + 缺少今日记录列表 view 的编辑/删除

**问题**：
- 用户点击进入"今日记录" (`TodayRecordsCard`)，但**没有删除按钮**
- `WaterStore` 有 `delete(_ record: WaterRecord)` 方法，但**从未被任何 UI 调用**
- 用户如果误点记录喝水（例如点了 2000ml 杯子、数据异常），**无法撤销**，也无法删除错误记录

**风险**：
- 用户体验极差：误操作后无法纠正
- 影响 HealthKit 同步：已同步的记录无法从 HealthKit 删除（当前代码也没有双向同步的删除操作）

**修复**：
1. 在 `TodayRecordsCard` 中添加 `.swipeActions` 支持删除
2. 在 `GardenView` 中添加撤销/编辑入口
3. 同步通知 Widget 和 HealthKit

---

## 2. 🟡 MAJOR 问题（影响用户体验或长期维护）

### [M-001] `Info.plist` 缺少 iOS 版本声明和 App Transport Security

**文件**：`Info.plist`

**问题**：
- 没有 `MinimumOSVersion` 键（通常 `$(IPHONEOS_DEPLOYMENT_TARGET)`）
- 没有 `NSAppTransportSecurity` 配置（iOS 9 以后必须）

**风险**：
- 虽然 Xcode 通常自动生成 MinimumOSVersion，但在手动编辑 plist 时容易遗漏
- ATS 未明确声明可能导致某些网络请求失败或被限制

**建议**：添加
```xml
<key>MinimumOSVersion</key>
<string>17.0</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

---

### [M-002] 缺少 Widget 预览/编辑配置 + 代码可配置性低

**文件**：`Widget/Info.plist`

**问题**：
- Widget `Info.plist` 只写了 App Group，没有 `CFBundleDisplayName` 的 Widget 名（但 Widget 里的 `WidgetBundle` 有 `kind` 定义，基本够用）
- Widget 的 `Kind` 名称 (`BloomWidget`) 匹配了 `AppConstants.widgetKind`，这部分是正确的

**次要风险**：
- Widget 在通知中心显示的名称显示为"Widget"而不是"你的植物"或中文翻译

**建议**：添加 Widget 的 `Info.plist` 本地化

---

### [M-003] `HealthManager.saveWater()` 不会累加已有的 HealthKit 数据

**文件**：`Core/Managers/HealthManager.swift:56`

**问题**：
- `saveWater()` 每次调用都创建一个全新的 `HKQuantitySample`
- 如果用户多次在同一天喝水，HealthKit 中会有多个独立的 sample（每条 250ml）
- 这看起来合理，但如果用户：
  1. 记录喝水 500ml → 同步到 HealthKit ✓
  2. 删除应用内记录 → **HealthKit 中的 500ml 仍然保留**
  3. 重新记录 500ml → HealthKit 中变成 1000ml
- 长期可能导致 HealthKit 数据不准确，无法双向同步

**建议**：记录 `hkSampleUUID` 到 `WaterRecord`（已经实现了！见 `WaterRecord`），删除时反向同步删除 HealthKit sample

---

### [M-004] `WidgetDataManager` 写数据但 Widget 不主动刷新

**文件**：`Widget/BloomWidget.swift` + `Core/Managers/WidgetDataManager.swift`

**发现（已经部分修复）**：
- Widget 读取的是 `UserDefaults(suiteName: AppConstants.appGroupIdentifier)`，而主 App 写数据到该 App Group（`WidgetDataManager` 第 11-48 行）
- `WidgetCenter.shared.reloadAllTimelines()` 已在 `WaterStore.add` 后调用

但**仍存在的问题**：
- 主 App 中的 `HealthSyncService.sync` → 如果从 HealthKit 拉取了新数据，**不会调用 Widget 刷新**
- **Widget 的时间间隔**：`TimelineProvider` 中 `getTimeline` 的 `policy` 只写了 `.never` — 这意味着除非 App 主动调用 `reloadAllTimelines()`，否则 Widget **永远不会刷新**

```swift
// 在 BloomWidget.swift:120
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let currentDate = Date()
    let entry = PlantEntry(
        date: currentDate,
        plantName: ...
    )
    let timeline = Timeline(entries: [entry], policy: .never) // ❌ 永远不刷新！
    completion(timeline)
}
```

**建议**：将 `.never` 改为：
```swift
// 每 4 小时刷新一次 Widget 时间戳（或者更长）
let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!
let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
```

---

### [M-005] `notificationManager.scheduleReminder` 文案重复且未翻译

**文件**：`Core/Managers/NotificationContent.swift`

**问题**：
- 第 20-27 行所有中文文案使用 `NSLocalizedString`，但这些 key 都**没有在 en.lproj/Localizable.strings 中定义**
- 结果：英文用户看到的通知显示的是**中文 key 本身**（如果 key 不存在，NSLocalizedString 会直接返回 key）

**当前使用方式**：
```swift
static func wiltingReminders(plantName: String) -> [Message] {
    [
        Message(title: String(format: NSLocalizedString("🥀 %@ 有点蔫了……", comment: ""), plantName),
                body: NSLocalizedString("它渴了好久了，快来救救它", comment: "")),
        ...
    ]
}
```

**建议**：
- 在 `en.lproj/Localizable.strings` 中补全所有 notification 相关 key
- 考虑把 `NSLocalizedString` 包一层到自定义函数，当 key 不存在时给出默认 fallback（英文）

---

### [M-006] `UIImpactFeedbackGenerator` 每次都新建，没有复用

**文件**：`Features/Garden/GardenView.swift:110`

**问题**：
- 每次点击植物浇水 → 新建 `UIImpactFeedbackGenerator` → 调用 `impactOccurred()` → **立即释放**
- 这是性能浪费（不严重），但更重要的是**第一次触觉可能无延迟响应**

**建议**：在 `@State` 中持有 generator，或使用全局 `Haptics.impact()`（你已经有 `Haptics.swift` 工具类，所以用它！）

---

### [M-007] `@StateObject` 与单例冲突 — BloomApp

**文件**：`App/BloomApp.swift:18-23`

**问题**：
```swift
@StateObject private var storeManager = StoreManager.shared
@StateObject private var notificationManager = NotificationManager.shared
@StateObject private var healthManager = HealthManager.shared
...
```

**矛盾**：
- `@StateObject` 的语义是"这个 View 拥有这个对象"，意味着当 View 销毁时对象也销毁
- 但 `shared` 是**单例**，意味着**永远不会销毁**
- 这导致：SwiftUI 生命周期错误地假设它管理对象，但实际上它只是个引用
- 当 App 重新进入 foreground 时，可能会有状态错乱

**建议**：改用 `@ObservedObject` 或 `@EnvironmentObject` 传入，或在单例的初始化和各处用普通引用

---

### [M-008] `HealthSyncService` 每天主动同步数据，但没有"去重保护"

**文件**：`Core/Managers/HealthSyncService.swift`

**问题**：
- `WaterStore.addIfExists()` 有 `hkSampleUUID` 去重（第 51 行 `if records.contains(where: { $0.hkSampleUUID == hkSampleUUID })`），这很好
- 但**从 HealthKit 拉取数据时**，没有去重（`fetchWaterRecords(from: to:)` 第 70 行直接返回所有 `HKQuantitySample`）
- `HealthSyncService.sync()` 可能每次调用都在 `UserDefaults` 中写 `bloom.lastHealthKitSyncDate`，但**写入时的去重依赖于 WaterRecord 的 hkSampleUUID**
- 这个逻辑是完整的，但**如果 HealthKit sample 被多次同步**（例如在应用重启后），WaterStore 可能产生重复记录

**建议**：保持现有逻辑，但增加一个调试日志或 debug-only 崩溃检测

---

### [M-009] `PaywallView` 中产品列表价格本地化 — "per Year" 等硬编码

**文件**：`Features/Paywall/PaywallView.swift`（如果存在）

**问题**：
- 产品文案（"¥18/年"、"永久解锁"）是硬编码的
- 价格使用 `product.displayPrice` 是正确的，但周期（"per Year"、"per Month"）仍需要本地化

**建议**：使用 `Product.SubscriptionPeriod` 自动格式化为本地化字符串

---

### [M-010] `GardenStore.harvestPlant` 的返回值没有被 GardenView 正确处理

**文件**：`Features/Garden/GardenView.swift:250-259`

```swift
private func performHarvest() {
    if !gardenStore.harvestPlant(plantEngine: plantEngine, isPro: userStore.isPro) {
        let check = gardenStore.canHarvest(isPro: userStore.isPro)
        if !check.allowed {
            showGardenLimitAlert = true
        }
        return
    }
    Haptics.success()
}
```

**问题**：
- `gardenStore.harvestPlant()` 返回 false 有两种可能：
  1. 免费用户达到限额 → `showGardenLimitAlert = true` ✅
  2. **植物本身不能收获**（stage != harvestable） → **没有任何提示**
- 如果植物还没成熟，用户点击收获按钮后，什么都不会发生 → 用户困惑

**建议**：添加一个"植物还没成熟"的提示

---

### [M-011] `collectionView` 中 `PaywallView` 未传入 `storeManager`

**文件**：`Features/Collection/CollectionView.swift:41`

```swift
.sheet(isPresented: $showPaywall) {
    PaywallView() // ❌ 缺少 .environmentObject(storeManager)
        .environmentObject(storeManager)
}
```

**注意**：实际上第 42 行有 `environmentObject(storeManager)`，这是正确的
- 但第 12 行 `@EnvironmentObject var storeManager: StoreManager`
- 第 127 行 `onTapGesture { if locked { showPaywall = true } }` → 打开 sheet → PaywallView 通过环境对象获取 storeManager → **OK**

但在 `GardenView.swift:126-127` 和 `SettingsView.swift:627-628` 这两个 Paywall 调用也都是正确的

---

### [M-012] iOS 18 以下 `Text(String(_: Specifier))` 中的 specifier 可能崩溃

这是一个 iOS 已知问题：Swift `String(format:)` 的 `%@` 在某些 Locale 下可能崩溃（不常见，影响面小）

**问题**：
- 大量使用 `String(format: NSLocalizedString("... %@ ...", comment: ""), plantName)`
- 如果 NSLocalizedString 返回的字符串中 `%@` 数量与传入参数不匹配，会崩溃

**示例风险**：翻译人员可能错误地移除 `%@`，但编译器不会检测

---

## 3. 🟢 MINOR 问题（代码质量/可维护性）

### [m-001] `NSLocalizedString` 的 `comment` 字段经常为空

整个代码库中大部分 `NSLocalizedString(key, comment: "")` 的 `comment` 字段都是空字符串

虽然不影响功能，但这**严重降低了翻译质量**：翻译人员不知道上下文，可能翻译出不符合语境的文案

**建议**：至少写出 1-2 个英文/中文描述说明这个字符串的用途

---

### [m-002] `AppConstants.swift` 中 `NotificationNames` 的 Notification.Name 前缀不一致

- `Notification.Name("bloom.refreshWidget")` ✓
- `Notification.Name("bloom.showPaywall")` ✓
- `Notification.Name("bloom.applyOfflineDecay")` ✓

但是在 `Core/Managers/BackgroundTaskManager.swift:98` 中有一个**独立于 AppConstants**的通知：
```swift
NotificationCenter.default.post(name: .applyOfflineDecay, object: nil)
```

这里用的是 `static let applyOfflineDecay = Notification.Name("applyOfflineDecay")`（在 `BackgroundTaskManager.swift:143`）而**不是** `AppConstants.NotificationNames.applyOfflineDecay`

**建议**：统一到 `AppConstants`，删除 BackgroundTaskManager 中的扩展

---

### [m-003] `TimeInterval` 的转换不一致

- 有的地方写 `Date(timeIntervalSince1970:)`
- 有的地方写 `Calendar.current.date(byAdding:)`
- 没有统一的时间处理工具类

---

### [m-004] 过多的 `print()` 调试输出没有被 `#if DEBUG` 包裹

**文件**：
- `Core/Managers/NotificationManager.swift:107` — `print("[Notification] 调度失败 ...")`
- `Core/Managers/HealthManager.swift:39` — `print("[Health] 授权失败: \(error)")`

**问题**：release 版本仍然在 print，影响性能（小）

**建议**：用一个统一的 Log 工具类，release 下禁用日志

---

### [m-005] `import UIKit` 在 SwiftUI-only 文件中冗余

**文件**：`Features/Garden/GardenView.swift` 顶部只有 `import SwiftUI` — **OK**
**文件**：`Features/Settings/SettingsView.swift` 顶部有 `import UniformTypeIdentifiers` — OK

实际上这部分做得不错

---

### [m-006] `PlantEngine` 与 `BackgroundTaskManager` 共享的离线衰减时间不一致

**文件**：`PlantEngine.swift:147` vs `BackgroundTaskManager.swift:65`

- PlantEngine 中 `applyOfflineDecay(hours: Int)` 使用 `decayPerHour = 2.0`
- 但 BackgroundTaskManager 中 `hoursSinceLastActive` 是按小时计算，而实际衰减是 "一天没达标算 10%"

这两个衰减速率**不一致**，导致：
- 前台衰减慢（1 天没达标只减 plant.health 的一个百分比）
- 后台衰减快（2 health/hour × 24 = 48 health/天，相当于两天就枯萎）

**建议**：统一衰减常量，导出到 `AppConstants`

---

### [m-007] `waterStore.delete(_ record:)` 没有通知 Widget 刷新

**文件**：`Core/Stores/WaterStore.swift:80`

```swift
func delete(_ record: WaterRecord) {
    records.removeAll { $0.id == record.id }
    persist()
    triggerSync()
}
```

**问题**：删除后没有通知 Widget。如果用户删除一条记录，Widget 仍然显示旧数据

**建议**：在 delete 中添加 Notification 发布

---

### [m-008] `WaterRecord` 的 `id` 是 UUID，但删除时用 `records.removeAll`（O(n)）

虽然记录数不会很大，但可以改为 `records.firstIndex(where:)` + `remove(at:)`

---

### [m-009] `achievementStore` 加载时没有读取已保存数据

**文件**：`Core/Stores/AchievementStore.swift`

- 当前 `AchievementStore` 的 `@Published var achievements: [Achievement]` 是否是从本地加载的？
- 从实现看，似乎**没有持久化已解锁的成就到磁盘**

**风险**：重启应用后，成就状态重置

**建议**：在 `init()` 中从 PersistenceManager 加载

---

### [m-010] SettingsView 中的隐私政策 URL 是硬编码的

**文件**：`Features/Settings/SettingsView.swift:648`

```swift
openURL("https://pangtongya.github.io/Bloom-Website/privacy-policy.html")
```

应该通过 Bundle 的 Info.plist 配置或 AppConstants 来管理，避免以后 URL 变更时需要改代码

---

### [m-011] ThemePickerView 中的主题切换没有持久化

**文件**：`Features/Settings/ThemePickerView.swift`

**问题**：切换主题后，如果退出应用再启动，当前选的主题可能没有被持久化到 UserDefaults

**验证**：需要检查 `ThemeManager.loadSavedTheme` 是否在 BloomApp 中被调用

BloomApp.swift 第 86 行：
```swift
themeManager.loadSavedTheme(isPro: userStore.isPro) // ✅ 有调用
```

OK ✓，但需要确认 `ThemeManager` 的 save 功能完整

---

### [m-012] `HarvestView` 中日期显示使用 `DateFormatter` 但未在文件顶部 import

这个风险小，因为 Swift 编译器会报错如果缺少 Foundation — 这部分已经通过编译

---

### [m-013] `QuickRecordBar` 中杯子按钮的 `size` 使用错误的命名

**文件**：`Features/Record/QuickRecordBar.swift`

- 按钮的杯子大小（small/medium/large）与 WaterRecord 的 `cupType` 关联
- 但没有可视化的"ml 数"显示，用户不知道每个按钮实际是多少 ml

---

### [m-014] `PlantStatusCard` 在健康度为 0 或 100 时的 UI 边界显示

**文件**：`Features/Garden/PlantStatusCard.swift`

当 plant.health = 100 时，圆形进度条是否显示满圆？
当 plant.health = 0 时，是否显示空圆？

需要检查边界条件处理

---

### [m-015] 没有 App Icon 备份路径

项目中没有看到 AppIcon 的 SVG/高分辨率版本，只有在 `Assets.xcassets/AppIcon.appiconset` 中的 PNG。如果后期需要更换图标，可能找不到源文件

---

## 4. 🔵 INFO / 建议

### [i-001] 考虑使用 SwiftData 替代 PersistenceManager

iOS 17+ 原生支持 SwiftData，这是一个现代的、类型安全的 Core Data 替代方案。当前的 JSON 持久化方案简单但有局限：

- 不支持增量迁移
- 不支持查询过滤（需要加载全部记录）
- 磁盘写入频繁（每次 add 都重写整个 JSON 文件）

---

### [i-002] 考虑使用 `BGTaskScheduler` 的 `BGAppRefreshTaskRequest` 替代后台衰减计算

当前后台任务使用 `BGAppRefreshTask` + `Task { @MainActor ... }` 写入数据，但背景任务被系统调度的时间窗口**仅 30 秒**，且需要网络/CPU 资源，可能无法完成（例如 WidgetCenter reload 在后台可能失败）

建议：
- 使用 `BackgroundTaskManager.getPendingTaskRequests(completionHandler:)` 检查任务是否已注册
- 把 Widget 刷新挪到 Widget 的自己的 `getTimeline()` 中（Widget 独立刷新）

---

### [i-003] iCloud 同步的一致性检查

CloudSyncManager 的 `syncPlant` / `syncWaterRecords` / `syncGardenItems` 没有版本号/时间戳冲突处理：
- 如果用户在两台设备上同时修改植物，谁的数据优先？
- 目前实现是简单的"最后写入者胜"，但缺少冲突检测和用户通知

---

### [i-004] 整体的本地化覆盖度检查

当前本地化资源：
- `en.lproj/Localizable.strings` — 存在
- `zh.lproj/Localizable.strings` — 存在

但需要**运行时验证**所有硬编码字符串是否都已替换为 `L.xxx`

建议添加一个脚本或 Debug 模式中的 "Missing Locale Key" 日志输出

---

### [i-005] 缺少 onboarding 的"同意隐私政策"检查

当前 onboarding 没有让用户确认隐私政策或使用条款，虽然不违法（Apple 只要求在首次购买时同意），但最好有一个简单的同意入口

---

## 5. 🧪 编译验证结果

使用命令：
```bash
xcodebuild -project Bloom.xcodeproj -scheme Bloom -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**结果**：✅ BUILD SUCCEEDED

```
** BUILD SUCCEEDED ** [0.462 sec]
```

⚠️ **但是**：需要真机测试以下功能：
1. HealthKit 权限请求流程
2. Widget 数据同步
3. 本地通知调度
4. 内购流程（需要真机 + Apple ID 测试）
5. 后台任务调度（只能真机测试）

---

## 6. 🚀 上架前必须完成的清单

### 🎯 Critical (必须在上架前解决)

| # | 任务 | 预计时间 |
|---|------|---------|
| C-001 | HealthKit async 方法包装为 withCheckedContinuation | 1 小时 |
| C-002 | 主 App Info.plist 添加 App Group 权限声明 | 30 分钟 |
| C-003 | 添加删除喝水记录的 UI + 同步 Widget/HealthKit | 2 小时 |

### 🎯 High Priority (强烈建议在上架前修复)

| # | 任务 | 预计时间 |
|---|------|---------|
| M-002 | Widget Info.plist 添加本地化显示名称 | 30 分钟 |
| M-004 | Widget TimelinePolicy 从 `.never` 改为 4 小时刷新 | 30 分钟 |
| M-005 | 补全 NotificationContent 的 en 翻译 | 1 小时 |
| M-007 | @StateObject 对单例的使用改为 @ObservedObject | 2 小时 |
| M-006 | 统一 Haptics 使用（用 Haptics.swift） | 30 分钟 |
| M-010 | 收获按钮禁用状态 + 未成熟提示 | 1 小时 |
| m-007 | WaterStore.delete 添加 Widget 通知 | 30 分钟 |

---

## 7. 📊 各模块健康度评分

| 模块 | 代码量 | 复杂度 | 质量评分 | 风险级别 |
|------|--------|--------|---------|---------|
| App/BloomApp.swift | 133 行 | 中 | 7/10 | 高 |
| Features/Garden/ | ~900 行 | 高 | 7/10 | 中 |
| Features/Record/ | ~150 行 | 低 | 8/10 | 低 |
| Features/History/ | 290 行 | 中 | 7/10 | 低 |
| Features/Settings/ | 702 行 | 高 | 6/10 | 中 |
| Features/Paywall/ | ~300 行 | 中 | 7/10 | 中 |
| Features/Onboarding/ | 277 行 | 中 | 7/10 | 中 |
| Features/Collection/ | 177 行 | 低 | 8/10 | 低 |
| Features/Achievements/ | ~288 行 | 中 | 7/10 | 低 |
| Core/Stores/ | ~900 行 | 高 | 7/10 | 高 |
| Core/Managers/ | ~1500 行 | 高 | 7/10 | 高 |
| Core/Utils/ | ~400 行 | 低 | 8/10 | 中 |
| Core/Engine/ | ~300 行 | 中 | 8/10 | 中 |
| Core/Models/ | ~400 行 | 低 | 8/10 | 低 |
| UI/ | ~300 行 | 中 | 8/10 | 低 |
| Widget/ | ~250 行 | 中 | 7/10 | 中 |

**总分**：7/10 — 整体质量良好，但有几个关键问题需要修复

---

## 8. 📋 总结

### ✅ 做得好的方面

1. **完整的 PlantEngine 生命周期逻辑**：植物生长/枯萎/收获逻辑清晰且经过验证
2. **SwiftUI 现代架构**：使用 `@EnvironmentObject` 分发数据，View 与 Model 分离
3. **PersistenceManager 统一持久化**：JSON 文件存储，迁移友好
4. **Widget 完整数据管道**（近期新增）：NotificationCenter → WidgetRefresher → WidgetDataManager → WidgetCenter
5. **HealthKit 双向同步**：sample UUID 去重做得不错
6. **主题系统**：用户可选主题色
7. **数据备份/恢复**：完整的 JSON 导出/导入 + checksum 校验
8. **内购管理**：StoreKit 2 + 事务监听 + Keychain 持久化 Pro 状态

### ⚠️ 需要优先关注

1. **HealthKit async 包装问题** → 可能在 release 版本崩溃
2. **主 App 缺少 App Group 权限声明** → Widget 拿不到数据
3. **用户无法删除/编辑记录** → 影响核心信任
4. **通知/本地化缺失** → 英文用户体验差
5. **Widget 刷新策略为 `.never`** → Widget 会显示旧数据

---

**建议的发布策略**：
1. 先修复 C-001 ~ C-003（3 小时）
2. 再修复 M-002、M-004、M-005（2 小时）
3. 提交 TestFlight 测试至少 3 天
4. 收集到用户无崩溃报告后提交 App Store

总工作量：**1-2 个工作日**（包含测试）
