# WaterMinder Pro 代码审查报告（二）：需要做出的改进

> 基于问题报告（文档一）中发现的 43 个问题，制定以下改进计划

---

## 一、严重问题修复（Critical Fixes）

### 1.1 统一隐私声明与实际行为
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 删除 `PrivacyInfo.xcprivacy` 中关于「联系人数据」和「使用数据」用于分析的声明
- [ ] 若确实需要 analytics，更新为准确的隐私标签描述（使用 Xcode Privacy Manifest）
- [ ] 统一声明："We don't collect any personal data" 或按实际行为准确描述
- [ ] 确保 `app-store-metadata.md` 与实际隐私行为一致

---

### 1.2 修复 iOS 通知权限配置
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 删除 `Info.plist` 中的 `NSUserNotificationUsageDescription`（macOS key，iOS 无效）
- [ ] 添加正确的 HealthKit 权限描述：
  ```xml
  <key>NSHealthShareUsageDescription</key>
  <string>WaterMinder 需要读取您的健康数据，以提供更准确的饮水建议。</string>
  <key>NSHealthUpdateUsageDescription</key>
  <string>WaterMinder 需要写入您的饮水量记录，帮助您追踪每日饮水目标。</string>
  ```
- [ ] 添加出口合规性声明：
  ```xml
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  ```

---

### 1.3 完善 Info.plist 必需字段
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 确认 `CFBundleDisplayName`（App 展示名称）
- [ ] 确认 `CFBundleShortVersionString` 和 `CFBundleVersion` 版本号格式正确
- [ ] 添加缺失的权限描述（见 1.2）
- [ ] 确认 `UIBackgroundModes`（如有后台刷新需求）

---

### 1.4 删除或修复语法错误文件
**优先级：P0（阻塞编译）**

**改进措施：**
- [ ] 删除 `Features/Garden/GardenView.swift.broken` 文件（若 GardenView.swift 已正常）
- [ ] 或修复该文件中的多余右花括号并合并到主文件

---

### 1.5 完善中文本地化
**优先级：P0（阻塞审核/影响用户体验）**

**改进措施：**
- [ ] 创建 `zh-Hans.lproj/Localizable.strings`（简体中文）
- [ ] 补充 `en.lproj/Localizable.strings` 中的空翻译占位
- [ ] 将所有硬编码中文替换为 `L.xxx` key 调用
- [ ] 检查 `L.swift` 是否支持所有需要的 key

---

### 1.6 同步隐私清单文件
**优先级：P0（阻塞审核）**

**改进措施：**
- [ ] 更新 `PrivacyInfo.xcprivacy` 移除错误声明
- [ ] 使用 Xcode 自动生成或手动精确描述实际数据使用

---

## 二、主要问题修复（Major Fixes）

### 2.1 统一项目配置
**优先级：P1（高）**

**改进措施：**
- [ ] 确认 `project.yml` 中 Widget target 的 sources 路径正确
- [ ] 确认 `group.com.waterminder.bloom` App Group 在 Apple Developer Portal 已创建并绑定
- [ ] 在 `Info.plist` 的 Widget extension target 中添加 App Group 配置
- [ ] 统一 entitlements 文件位置，清理 project.yml 中的冗余路径

---

### 2.2 修复 Widget 扩展
**优先级：P1（高）**

**改进措施：**
- [ ] 清理 `Widget/BloomWidget.swift` 的文件头（删除多余空行）
- [ ] 确认 Widget 可以正确引用主 App 的 Store 类型
- [ ] 配置 Widget Target 的 Embedded Binaries 包含主 App

---

### 2.3 统一 App Group ID 管理
**优先级：P1（高）**

**改进措施：**
- [ ] 创建 `Constants.swift` 统一管理所有 App Group ID：
  ```swift
  enum AppConstants {
      static let appGroupID = "group.com.waterminder.bloom"
      static let widgetKind = "BloomWidget"
  }
  ```
- [ ] 替换所有硬编码的 App Group ID 字符串

---

### 2.4 完善 StoreManager 订阅处理
**优先级：P1（高）**

**改进措施：**
- [ ] 将 `observeTransaction()` 的注册失败处理加入重试逻辑
- [ ] 将 `updateProStatus()` 中的同步验证移至后台队列
- [ ] 添加网络状态监听，离线时降级处理
- [ ] 添加沙盒环境测试分支

---

### 2.5 优化 HealthManager 授权流程
**优先级：P1（高）**

**改进措施：**
- [ ] 在 App 启动流程（如 `BloomApp.swift`）中统一请求 HealthKit 授权
- [ ] 增加 `isHealthDataAvailable()` 检查和用户提示
- [ ] 将授权状态持久化，避免每次启动重复请求

---

### 2.6 加强 CloudSyncManager 安全性
**优先级：P1（高）**

**改进措施：**
- [ ] 确保所有网络请求使用 HTTPS
- [ ] 实现证书固定（Certificate Pinning）
- [ ] 考虑对敏感数据使用 AES 加密后再传输

---

### 2.7 实现 DataBackupManager 实际功能
**优先级：P1（高）**

**改进措施：**
- [ ] 实现 `performBackup()` 将数据导出为 JSON 文件
- [ ] 实现 `restoreFromBackup()` 从备份文件恢复
- [ ] 实现 `scheduleAutomaticBackup()` 使用户可配置自动备份
- [ ] 在 Settings UI 中添加备份/恢复入口

---

### 2.8 实现植物健康度后台衰减
**优先级：P1（高）**

**改进措施：**
- [ ] 在 `PlantEngine` 中注册 `BGTaskScheduler` 后台任务
- [ ] 实现 `registerBackgroundTasks()` 和 `handleBackgroundTask()`
- [ ] 在 App 进入前台时计算并应用离线期间的健康衰减
- [ ] 确保 `calculateHealthDecay()` 逻辑正确处理边界情况

---

### 2.9 升级通知 API
**优先级：P1（高）**

**改进措施：**
- [ ] 确认 `UNUserNotificationCenter` delegate 在 AppDelegate 中正确设置
- [ ] 实现 iOS 15+ 的 notification grouping
- [ ] 增加重复通知去重的可靠机制（使用 notification identifier 哈希）
- [ ] 测试临界通知（Critical Notification）是否需要

---

### 2.10 恢复或删除被注释的枚举值
**优先级：P1（高）**

**改进措施：**
- [ ] 取消注释 `PlantSpecies.mysterious` 并提供完整的 PlantSpeciesData
- [ ] 或从 `allCases` 中明确排除未实现的品种
- [ ] 确保 `PlantView.swift` 的 switch 语句处理所有活跃品种

---

### 2.11 完成 TODO 功能
**优先级：P1（高）**

**改进措施：**
- [ ] `GardenView.swift` 109行：实现「显示付费墙」功能
- [ ] `PlantEngine.swift`：实现 CloudKit sync 或移除 TODO 注释
- [ ] `CloudSyncManager.swift`：实现 CloudKit sync 或移除 TODO 注释
- [ ] `SharingManager.swift`：实现 Social framework 集成或移除 TODO 注释
- [ ] `DataBackupManager.swift`：实现所有 TODO 功能

---

### 2.12 完善 StoreManager 沙盒测试
**优先级：P1（高）**

**改进措施：**
- [ ] 添加 `#if DEBUG` 分支处理沙盒环境
- [ ] 在 `StoreManager` 初始化时检测 `Storefront.current` 判断环境
- [ ] 提供测试内购的调试菜单

---

## 三、一般问题修复（Minor Fixes）

### 3.1 统一注释与代码
**优先级：P2（中）**

**改进措施：**
- [ ] 更新 `GardenView.swift` 的注释，准确描述实际实现
- [ ] 删除或完善所有 "TODO:" 格式注释

---

### 3.2 清理未使用的导入
**优先级：P2（中）**

**改进措施：**
- [ ] `GardenView.swift`：移除 `import Charts`（移到 AdvancedStatsView）
- [ ] `SharingManager.swift`：删除被注释的 `import Social`

---

### 3.3 加强内购状态存储安全
**优先级：P2（中）**

**改进措施：**
- [ ] 将 `isPro` 存储迁移至 Keychain
- [ ] 添加服务器端收据验证作为额外保障
- [ ] 在 `BloomApp.swift` 启动时验证内购状态

---

### 3.4 修复 PlantLifecycle 边界计算
**优先级：P2（中）**

**改进措施：**
- [ ] 重构 `calculateHealthDecay()` 确保 `deathDate` 在 `health <= 0` 之前计算
- [ ] 增加单元测试覆盖边界情况

---

### 3.5 使用 Measurement API 统一单位显示
**优先级：P2（中）**

**改进措施：**
- [ ] 创建 `MeasurementFormatter` 扩展处理 ml/L 转换
- [ ] 统一使用 `Measurement<UnitVolume>` 替代字符串拼接

---

### 3.6 暴露成就系统配置
**优先级：P2（中）**

**改进措施：**
- [ ] 在 `AchievementStore` 中添加静态配置属性
- [ ] 或在 `UserProfile.swift` 中定义成就配置常量

---

### 3.7 启用 Preview 代码
**优先级：P2（中）**

**改进措施：**
- [ ] 启用 `AdvancedStatsView.swift` 中的 Preview 代码
- [ ] 或删除未使用的 Preview 代码块

---

### 3.8 完善 project.yml Widget 依赖
**优先级：P2（中）**

**改进措施：**
- [ ] 确保 Widget target 正确链接 `WidgetKit` 和 `SwiftUI.framework`
- [ ] 在 project.yml 中显式声明 Widget 依赖

---

### 3.9 完成本地化文件
**优先级：P2（中）**

**改进措施：**
- [ ] 补充 `en.lproj/Localizable.strings` 中所有空翻译
- [ ] 创建 `zh-Hans.lproj/Localizable.strings`
- [ ] 添加 `L.onboarding`、`L.privacy`、`L.terms` 等 key

---

### 3.10 验证图标资源完整性
**优先级：P2（中）**

**改进措施：**
- [ ] 检查 Assets.xcassets 中所有 App Icon 尺寸是否有对应图片
- [ ] 补充缺失的 AppIconAlternate 和 AppIconVampire 资源
- [ ] 使用 `xcassets` 验证工具检查

---

## 四、架构改进（Architecture Improvements）

### 4.1 重构 Store 注入逻辑
**优先级：P1（高）**

**改进措施：**
- [ ] 在 `BloomApp.swift` 中确保 `UserStore` 在 `PlantEngine` 之前初始化
- [ ] 使用 `@MainActor` 确保线程安全
- [ ] 考虑使用 `Observation` framework（iOS 17+）替代 Combine

---

### 4.2 解耦分享功能
**优先级：P2（中）**

**改进措施：**
- [ ] 将分享功能抽象为 `ShareService` protocol
- [ ] 提供 `ContactsShareService` 和 `NoContactsShareService` 两种实现
- [ ] 在用户拒绝通讯录权限时降级到无联系人分享

---

### 4.3 加强 Widget 数据共享健壮性
**优先级：P1（高）**

**改进措施：**
- [ ] 在 `WidgetDataManager` 中添加数据版本控制
- [ ] 实现 App Group 数据变更的版本对比，避免 Widget 读取不完整数据
- [ ] 添加 Widget 刷新失败的重试逻辑

---

### 4.4 移动业务逻辑到 ViewModel 层
**优先级：P2（中）**

**改进措施：**
- [ ] 将 `GardenView.swift` 中的 `waterPlant()` 逻辑移至 `PlantEngine`
- [ ] 将 `GardenView.swift` 中的 `harvestPlant()` 逻辑移至 `GardenStore`
- [ ] View 只负责 UI 渲染，业务逻辑可测试

---

## 五、安全改进（Security Improvements）

### 5.1 服务器端内购验证
**优先级：P1（高）**

**改进措施：**
- [ ] 实现服务端 `verifyReceipt` API
- [ ] 在 `StoreManager` 中调用自建服务器验证收据
- [ ] 定期重新验证以检测 revoked 交易

---

### 5.2 迁移敏感数据到 Keychain
**优先级：P1（高）**

**改进措施：**
- [ ] 将 `isPro` 状态存储迁移至 Keychain
- [ ] 将 UserDefaults 中其他敏感数据迁移
- [ ] 使用 `kSecAttrAccessible` 限制数据访问时机

---

### 5.3 保护分享内容隐私
**优先级：P2（中）**

**改进措施：**
- [ ] 在分享前显示预览，让用户确认要分享的内容
- [ ] 提供「不含详细数据」分享选项
- [ ] 移除分享图片中的敏感个人信息（如健康数据）

---

## 六、性能改进（Performance Improvements）

### 6.1 优化植物动画
**优先级：P2（中）**

**改进措施：**
- [ ] 设置 `animation(_:value:)` 的修剪选项
- [ ] 使用 `@State` 替代 `@EnvironmentObject` 驱动独立动画
- [ ] 测试低端设备的动画帧率

---

### 6.2 重构通知存储
**优先级：P2（中）**

**改进措施：**
- [ ] 将 `pendingNotifications` 迁移至 Core Data 或 SQLite
- [ ] 或限制存储的通知数量（只保留未来 30 天）

---

### 6.3 实现数据归档
**优先级：P2（中）**

**改进措施：**
- [ ] 在 `WaterStore` 中实现数据归档逻辑
- [ ] 定期（如每月）将历史数据归档到单独文件
- [ ] 保持 `records` 数组只包含最近 90 天数据

---

## 七、App Store 上架准备（App Store Preparation）

### 7.1 完善 Required Disclosures
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 在 App Store Connect 中准确填写 HealthKit 使用披露
- [ ] 若有 analytics，勾选「追踪」并提供隐私政策
- [ ] 提供订阅功能截图和测试账户

---

### 7.2 准备合规的截图和预览
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 准备所有要求尺寸的 App Store 截图（6.7"、6.5"、5.5"、iPad）
- [ ] 录制 App Preview 视频（不超过 30 秒）
- [ ] 确保所有截图展示最新 UI

---

### 7.3 解决应用命名合规性
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 确认 App 名称和副标题符合 Apple 指南
- [ ] 若涉及 gamification，考虑是否需要游戏分级
- [ ] 移除可能触发审核的敏感词汇

---

### 7.4 配置隐私政策和支持页面
**优先级：P0（阻塞上架）**

**改进措施：**
- [ ] 创建隐私政策网页并托管在 HTTPS 域名
- [ ] 创建支持/帮助中心页面
- [ ] 在 `app-store-metadata.md` 中添加这些 URL

---

## 改进任务汇总

| 优先级 | P0（阻塞问题） | P1（高） | P2（中） |
|--------|---------------|---------|---------|
| 数量   | 7             | 17      | 15      |
| 关键项  | 隐私/通知/本地化/编译 | 架构/安全/后台任务 | 清理/优化/文档 |

---

*改进计划已制定。建议按以下顺序实施：先修复 P0 问题（解除上架阻塞），再处理 P1 问题（提升质量和安全性），最后完成 P2 问题（打磨和优化）。*
