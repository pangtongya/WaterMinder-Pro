# WaterMinder Pro

智能喝水提醒应用，帮您保持健康的水分摄入。

## 功能特点

### 核心功能
- **智能喝水提醒**：自定义提醒间隔，定时提醒喝水
- **快速记录**：一键记录不同杯型的喝水量
- **进度追踪**：可视化进度环，实时查看今日完成度
- **历史记录**：查看历史喝水数据，支持编辑和删除

### 高级功能
- **健康App集成**：自动同步喝水记录到健康App
- **个性化设置**：自定义每日饮水目标、提醒间隔、应用主题
- **数据统计**：查看今日、本周饮水数据和平均饮水量

## 技术架构

### 四层分离架构
```
Models（数据模型）→ Stores（数据管理）→ Managers（系统服务）→ Views（UI 层）
```

### 核心技术栈
- **SwiftUI**：现代声明式UI框架
- **Swift 6 Strict Concurrency**：严格并发安全
- **零第三方依赖**：纯原生开发，轻量高效
- **XcodeGen**：项目配置即代码
- **HealthKit**：健康数据集成
- **UserNotifications**：本地通知提醒

### 数据持久化
- **业务数据**：JSON文件存储（可序列化、可备份）
- **用户设置**：JSON文件存储（防抖写入）
- **跨进程共享**：UserDefaults（预留Widget扩展）

## 项目结构

```
WaterMinder-Pro/
├── WaterMinderApp.swift          # @main 入口
├── Info.plist                   # 应用配置
├── project.yml                 # XcodeGen 配置
├── Models/
│   ├── AppState.swift          # 全局状态
│   └── WaterRecordModel.swift  # 喝水记录模型
├── Stores/
│   └── WaterRecordStore.swift  # 喝水记录数据管理
├── Managers/
│   ├── NotificationManager.swift # 通知管理
│   └── HealthManager.swift      # 健康数据管理
├── Views/
│   ├── ContentView.swift      # 根导航
│   ├── HomeView.swift         # 首页
│   ├── HistoryView.swift      # 记录页面
│   ├── SettingsView.swift    # 设置页面
│   └── OnboardingView.swift  # 引导页面
├── Utilities/
│   └── ColorExtensions.swift  # 品牌色扩展
├── Tests/
│   └── WaterMinderTests.swift # 单元测试
├── Resources/
│   └── Audio/                 # 音频文件（预留）
├── Assets.xcassets/
│   └── AppIcon.appiconset/    # 应用图标
├── README.md
├── CHANGELOG.md
└── WORK_SUMMARY.md
```

## 开发环境

- **Xcode**：15.0+
- **iOS**：16.0+
- **Swift**：5.0+
- **XcodeGen**：通过 Mint 或 Homebrew 安装

## 快速开始

### 1. 克隆项目
```bash
git clone [repository-url]
cd WaterMinder-Pro
```

### 2. 生成 Xcode 项目
```bash
xcodegen generate
```

### 3. 打开项目
```bash
open WaterMinder.xcodeproj
```

### 4. 运行测试
```bash
xcodebuild test -scheme WaterMinder -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 测试覆盖

- **Model Tests**：WaterRecordModel 创建、格式化、边界条件
- **Store Tests**：WaterRecordStore CRUD、查询、统计
- **Enum Tests**：CupType rawValue、图标映射
- **Performance Tests**：100条记录下的计算性能

## 上架检查清单

- [ ] Swift 6 Strict Concurrency：0 警告
- [ ] 构建：0 错误
- [ ] 测试：全部通过
- [ ] App Icon：1024x1024 PNG
- [ ] 截图：3 套尺寸（iPhone 6.5", iPhone 5.5", iPad 12.9"）
- [ ] 隐私政策：HTML 文件 + 部署 URL
- [ ] App Store 标题（30 字符）
- [ ] App Store 副标题（30 字符）
- [ ] App Store 描述（4000 字符以内）
- [ ] 关键词（100 字符以内，逗号分隔）
- [ ] 支持 URL
- [ ] 版本号更新
- [ ] CHANGELOG.md 更新
- [ ] README.md 更新

## 版本历史

详见 [CHANGELOG.md](CHANGELOG.md)

## 许可证

MIT License

## 联系方式

- **开发者**：pangtong
- **支持**：通过 App Store 产品页的支持链接联系
