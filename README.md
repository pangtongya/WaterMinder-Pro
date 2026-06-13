# WaterMinder Pro

智能喝水提醒应用，帮您保持健康的水分摄入。

## ✨ 核心功能

### 智能追踪
- **一键记录**：4种杯型（小杯200ml / 中杯350ml / 大杯500ml / 水瓶750ml），一键记录
- **进度可视化**：精美圆形进度环 + 百分比显示
- **连胜系统**：连续达标天数追踪，激励每天喝水

### 数据洞察
- **趋势图表**：本周/本月饮水量柱状图，含目标线
- **历史记录**：按日期查看、编辑、删除喝水记录
- **数据导出**：JSON 格式导出，完全掌握自己的数据

### 小组件
- **桌面小组件**：小/中尺寸，随时查看今日进度
- **锁屏小组件**：圆形/矩形，解锁即可看到饮水状态

### 智能提醒
- **定时提醒**：自定义间隔（30-120分钟）
- **健康同步**：自动同步到 Apple 健康App

### 个性化
- **主题切换**：浅色/深色/跟随系统
- **目标自定义**：灵活的每日饮水目标（1000-10000ml）

## 🏗 技术架构

```
Models → Stores → Managers → Views
         ↕ App Group ↕
      Widget Extension
```

- **SwiftUI**：现代声明式UI
- **Swift Charts**：iOS 16+ 数据可视化
- **WidgetKit**：桌面 + 锁屏小组件
- **HealthKit**：健康数据集成
- **零第三方依赖**：纯原生开发

## 📱 项目结构

```
WaterMinder-Pro/
├── WaterMinderApp.swift           # @main 入口
├── Models/
│   ├── AppState.swift             # 全局状态（自动保存）
│   └── WaterRecordModel.swift     # 数据模型
├── Stores/
│   └── WaterRecordStore.swift     # 数据管理 + 连胜计算
├── Managers/
│   ├── NotificationManager.swift  # 本地通知
│   ├── HealthManager.swift        # HealthKit
│   └── WidgetDataManager.swift    # Widget 数据同步
├── Views/
│   ├── ContentView.swift          # 根导航
│   ├── HomeView.swift             # 首页（进度+记录+庆祝）
│   ├── HistoryView.swift          # 图表+历史
│   ├── SettingsView.swift         # 设置
│   └── OnboardingView.swift       # 引导
├── WaterMinderWidget/
│   └── WaterMinderWidget.swift    # 小组件
├── Tests/
│   └── WaterMinderTests.swift     # 单元测试
└── Utilities/
    └── ColorExtensions.swift      # 品牌色系统
```

## 🚀 快速开始

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 生成 Xcode 项目
cd WaterMinder-Pro
xcodegen generate

# 3. 打开项目
open WaterMinder.xcodeproj

# 4. 运行测试
xcodebuild test -scheme WaterMinder -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 📊 测试覆盖

- 17个测试用例，全部通过
- 模型测试、存储测试、统计测试、边界测试、性能测试

## 📝 版本历史

详见 [CHANGELOG.md](CHANGELOG.md)

## 📄 许可证

MIT License
