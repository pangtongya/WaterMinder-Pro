# WaterMinder Pro - 问题清单

> 创建时间：2026-06-14
> 检查人员：AI Agent (pangtong)
> 检查范围：UI/UX、功能完整性、性能、代码质量、上架准备

---

## 一、UI/UX 问题

### 1.1 首页布局问题

#### 问题1：首页进度环过大，占用空间过多
- **现象**：进度环直径180pt，在小屏幕（iPhone SE）上显得过大
- **影响**：用户需要滚动才能看到"快速记录"按钮，体验不佳
- **建议**：减小进度环尺寸至150pt，或改为自适应尺寸

#### 问题2：快速记录按钮布局不够直观
- **现象**：4个杯型按钮横向排列，在小屏幕上可能拥挤
- **影响**：用户可能误触，体验不佳
- **建议**：考虑改为2x2网格布局，或添加分隔线

#### 问题3：今日记录列表缺少空状态引导
- **现象**：空状态时显示"今天还没记录喝水\n点击上方按钮开始吧"，但不够突出
- **影响**：新用户可能不知道如何开始
- **建议**：添加更明显的引导，如动画或高亮按钮

### 1.2 历史记录页面问题

#### 问题4：图表Y轴标签显示不完整
- **现象**：Y轴标签使用`Text("\(amount)")`，没有单位，可能混淆
- **影响**：用户可能不知道单位是ml
- **建议**：改为`Text("\(amount)ml")`

#### 问题5：日期选择器占用空间过大
- **现象**：`DatePicker`使用`.compact`样式，但仍占用较多垂直空间
- **影响**：用户需要滚动才能看到记录列表
- **建议**：考虑使用自定义日期选择器，或更紧凑的样式

### 1.3 设置页面问题

#### 问题6：饮水目标输入框没有格式限制
- **现象**：`TextField("2000", text: $dailyGoalInput)`允许输入非数字字符
- **影响**：用户可能输入无效值，导致bug
- **建议**：使用`TextField(value: $dailyGoal, formatter: NumberFormatter())`

#### 问题7：健康App连接状态显示不准确
- **现象**：`healthAuthorized`状态是本地状态，没有实际检查HealthKit授权状态
- **影响**：用户界面显示"未连接"，但实际上可能已经授权
- **建议**：实现`HealthManager.isAuthorized`属性，检查实际授权状态

### 1.4 引导流程问题

#### 问题8：引导页缺少跳过按钮
- **现象**：第1-3页没有"跳过"按钮，用户必须完成引导
- **影响**：用户可能想直接使用，不想完成引导
- **建议**：在第1-3页添加"跳过"按钮

#### 问题9：引导页完成页文案不够激励
- **现象**："一切就绪！开始您的健康喝水之旅吧\n每一天都是更好的自己"比较平淡
- **影响**：用户可能没有动力开始使用
- **建议**：使用更激励的文案，如"您已准备好开始健康之旅！点击开始，迈向更好的自己！"

---

## 二、功能完整性问题

### 2.1 缺失功能

#### 问题10：App Icon未设计
- **现象**：项目没有App Icon，使用默认图标
- **影响**：无法上架App Store，用户体验差
- **优先级**：P0（阻塞上架）

#### 问题11：应用截图未制作
- **现象**：项目没有应用截图，无法提交App Store
- **影响**：无法上架App Store
- **优先级**：P0（阻塞上架）

#### 问题12：隐私政策页面未准备
- **现象**：设置页面"隐私政策"按钮链接到`https://pangtong.github.io/waterminder/privacy`，但页面可能不存在
- **影响**：无法上架App Store（需要隐私政策URL）
- **优先级**：P0（阻塞上架）

#### 问题13：App Store元数据未准备
- **现象**：没有准备App Store元数据（标题、描述、关键词等）
- **影响**：无法上架App Store
- **优先级**：P0（阻塞上架）

### 2.2 功能bug

#### 问题14：HealthManager.isAuthorized返回硬编码的false
- **现象**：`HealthManager.isAuthorized`属性返回硬编码的`false`
- **影响**：设置页面始终显示"未连接"状态
- **优先级**：P1（影响用户体验）

#### 问题15：通知权限请求失败处理不完善
- **现象**：`NotificationManager.requestAuthorization()`失败时，只是打印错误，没有提示用户
- **影响**：用户可能不知道权限被拒绝
- **优先级**：P2（建议修复）

#### 问题16：数据导出功能可能没有正确处理中文
- **现象**：`exportData()`使用`JSONSerialization`，可能没有正确处理中文字符
- **影响**：导出的JSON文件可能乱码
- **优先级**：P2（建议修复）

---

## 三、性能问题

### 3.1 列表性能

#### 问题17：历史记录列表没有分页或懒加载
- **现象**：`recordsForSelectedDate`直接计算所有记录，没有分页
- **影响**：如果用户有上千条记录，可能卡顿
- **建议**：实现分页或无限滚动

### 3.2 数据加载性能

#### 问题18：WaterRecordStore.load()在主线程执行
- **现象**：`WaterRecordStore.init()`调用`load()`，在主线程读取文件
- **影响**：如果数据量大，可能阻塞UI
- **建议**：使用`Task`或`DispatchQueue`在后台线程加载

---

## 四、代码质量问题

### 4.1 代码重复

#### 问题19：ColorExtensions.swift和WaterMinderWidget.swift都定义了waterminderPrimary
- **现象**：`Color.waterminderPrimary`在`ColorExtensions.swift`和`WaterMinderWidget.swift`中都定义了
- **影响**：代码重复，可能导致不一致
- **建议**：将颜色定义移到共享位置

### 4.2 潜在bug

#### 问题20：WaterRecordStore.items没有直接写入保护
- **现象**：`WaterRecordStore.items`是`@Published var items: [WaterRecordModel]`，外部可以直接修改
- **影响**：可能导致数据不一致
- **建议**：考虑使用私有变量+公开计算方法

#### 问题21：AppState.save()的防抖时间可能不够
- **现象**：`DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)`防抖0.3秒
- **影响**：如果用户快速修改多个设置，可能丢失数据
- **建议**：增加防抖时间至0.5秒或1秒

---

## 五、上架准备问题

### 5.1 必需项

#### 问题22：App Icon未设计
- **优先级**：P0
- **状态**：未开始

#### 问题23：应用截图未制作
- **优先级**：P0
- **状态**：未开始

#### 问题24：隐私政策页面未准备
- **优先级**：P0
- **状态**：未开始

#### 问题25：App Store元数据未准备
- **优先级**：P0
- **状态**：未开始

### 5.2 建议项

#### 问题26：Swift 6 Strict Concurrency警告未修复
- **现象**：构建时可能有Swift 6严格并发警告
- **影响**：不符合"0警告"标准
- **优先级**：P2

#### 问题27：无障碍功能未测试
- **现象**：没有测试VoiceOver等无障碍功能
- **影响**：可能影响部分用户使用
- **优先级**：P2

---

## 六、配置问题

### 6.1 Info.plist配置问题

#### 问题28：Info.plist没有配置启动屏幕自定义
- **现象**：`UILaunchScreen`配置为空，使用默认启动屏幕
- **影响**：用户体验不佳，启动时有白色闪屏
- **建议**：添加自定义启动屏幕或Launch Screen文件
- **优先级**：P2

### 6.2 project.yml配置问题

#### 问题29：project.yml配置了SWIFT_STRICT_CONCURRENCY=complete
- **现象**：`SWIFT_STRICT_CONCURRENCY: "complete"`会导致Swift 6严格并发检查
- **影响**：构建时可能有大量警告或错误
- **建议**：改为`SWIFT_STRICT_CONCURRENCY: "minimal"`或移除该配置
- **优先级**：P1

### 6.3 Widget扩展配置问题

#### 问题30：WaterMinderWidget target可能没有App Group Entitlements
- **现象**：从project.yml来看，WaterMinderWidget target没有配置CODE_SIGN_ENTITLEMENTS
- **影响**：Widget扩展可能无法访问App Group共享数据
- **建议**：为WaterMinderWidget target创建Entitlements文件，配置App Group
- **优先级**：P1

---

## 七、问题优先级总结

### P0（阻塞上架）
- 问题10：App Icon未设计
- 问题11：应用截图未制作
- 问题12：隐私政策页面未准备
- 问题13：App Store元数据未准备
- 问题22：App Icon未设计
- 问题23：应用截图未制作
- 问题24：隐私政策页面未准备
- 问题25：App Store元数据未准备

### P1（影响用户体验）
- 问题14：HealthManager.isAuthorized返回硬编码的false
- 问题7：健康App连接状态显示不准确
- 问题29：project.yml配置了SWIFT_STRICT_CONCURRENCY=complete
- 问题30：WaterMinderWidget target可能没有App Group Entitlements

### P2（建议修复）
- 问题15：通知权限请求失败处理不完善
- 问题16：数据导出功能可能没有正确处理中文
- 问题17：历史记录列表没有分页或懒加载
- 问题18：WaterRecordStore.load()在主线程执行
- 问题19：ColorExtensions.swift和WaterMinderWidget.swift都定义了waterminderPrimary
- 问题20：WaterRecordStore.items没有直接写入保护
- 问题21：AppState.save()的防抖时间可能不够
- 问题26：Swift 6 Strict Concurrency警告未修复
- 问题27：无障碍功能未测试
- 问题28：Info.plist没有配置启动屏幕自定义

---

## 八、下一步计划

### 短期（今天）
1. 修复P1问题（问题14、问题7、问题29、问题30）
2. 开始准备P0问题（问题10-13、问题22-25）

### 中期（明天）
1. 完成P0问题（App Icon、截图、隐私政策、元数据）
2. 修复P2问题（性能、代码质量）

### 长期（本周）
1. 上架App Store
2. 市场推广

---

**文档状态**：✅ 完整版完成
**最后更新**：2026-06-14 08:45
