# Changelog

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [1.1.0] - 2026-06-14

### Added
- **连胜系统**：自动计算连续达标天数 + 历史最长连胜
- **Swift Charts 数据可视化**：本周/本月饮水趋势柱状图，含目标线
- **成就庆祝动画**：达到目标时弹出庆祝界面 + 触觉反馈
- **Widget 小组件**：桌面小/中尺寸 + 锁屏圆形/矩形，实时显示饮水进度
- **数据导出**：JSON 格式导出 + 系统分享面板
- **数据重置**：真正清空所有数据 + 二次确认
- **自动保存**：AppState 所有属性修改时自动持久化
- **品牌色系统**：水蓝色渐变系（#3B82F6 → #06B6D4）

### Changed
- **全新首页设计**：进度环 + 连胜展示 + 庆祝动画
- **历史记录升级**：图表 + 连胜统计卡片 + 紧凑日期选择器
- **设置页完善**：真正可用的导出/重置/健康集成
- **引导流程优化**：5步引导页，渐变图标，更好的文案
- **杯型图标修正**：大杯图标从酒杯改为饮料杯
- **DateFormatter 优化**：使用静态实例避免重复创建
- **AppState 架构改进**：didSet 自动保存，消除手动调用
- **导航架构标准化**：每个 Tab 独立 NavigationStack

### Fixed
- 首页布局错乱（NavigationStack 架构重构）
- 进度环颜色逻辑（从红→橙→蓝→绿，更正向）
- 硬编码 HealthManager.isAuthorized
- SettingsView 缺失 recordStore 环境对象
- WaterMinderApp 死代码（colorScheme）
- OnboardingView 双重 ignoresSafeArea

### Technical
- 新增 Widget 扩展目标（WaterMinderWidget）
- App Group 数据共享（group.com.pangtong.waterminder）
- WidgetDataManager 管理 Widget 数据同步
- 项目版本号升至 Build 2

---

## [1.0.0] - 2026-06-14

### Added
- 项目初始化
- 核心数据模型（WaterRecordModel, AppState）
- 数据存储层（WaterRecordStore）
- 管理器层（NotificationManager, HealthManager）
- 视图层（HomeView, HistoryView, SettingsView, OnboardingView）
- 单元测试（WaterMinderTests）
- 项目文档（README.md, CHANGELOG.md, WORK_SUMMARY.md）
