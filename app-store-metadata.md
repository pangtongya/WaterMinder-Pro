# Bloom (水滴花园) - App Store Submission Metadata

## 📱 Basic Information

### App Name
- **Default (English):** Bloom
- **Chinese (Simplified):** 水滴花园
- **Maximum characters:** 30 (both fit perfectly)

### Subtitle
- **English:** Grow Plants by Drinking Water
- **Chinese:** 喝水养成，养成你的植物

### Bundle ID
`com.pangtong.bloom` (matches project configuration)

### Version
1.0.0 (Initial Release)

### Primary Category
Health & Fitness

### Secondary Category
Lifestyle

### Content Rating
4+ (Suitable for all ages)

---

## 📝 Description

### English Description

**Turn your daily water intake into a living, growing plant! 🌱💧**

Bloom makes hydration fun and rewarding. Every sip you drink helps your virtual plant grow from a tiny seed into a beautiful, thriving plant.

**How it works:**
• Log your daily water intake
• Watch your plant grow with each glass
• Unlock achievements as you build healthy habits
• Compete with friends and share your progress

**Key Features:**

🌿 **Plant Growth System**
Your plant evolves through 6 growth stages based on your hydration consistency. Keep drinking regularly to help it thrive!

📊 **Smart Statistics**
Track your drinking patterns with beautiful charts and insights. Discover your best drinking times and build better habits.

🏆 **Achievement System**
Earn rewards for milestones like 7-day streaks, daily goals, and consistency. Collect them all!

🎨 **Customizable Themes** (Pro)
Unlock beautiful themes and make Bloom yours. Choose from multiple Pro themes.

☁️ **iCloud Sync** (Pro)
Seamlessly sync your plant and data across all your Apple devices.

💧 **Health App Integration**
Optionally sync with Apple Health to automatically track your water intake.

**Perfect for:**
• Building healthy hydration habits
• Making drinking water more fun
• Tracking daily water intake
• Staying motivated with visual progress

**Privacy First:**
• All data stored locally on your device
• Health data never leaves your device without permission
• No third-party tracking or analytics
• Optional iCloud sync with end-to-end encryption

Start your hydration journey today. Download Bloom and watch your plant grow! 🌱

---

### Chinese Description (Simplified)

**让每次喝水都有意义！🌱💧**

水滴花园让喝水变得有趣。你喝下的每一口水，都会帮助你的虚拟植物从种子长成美丽的植物。

**使用方法：**
• 记录每日饮水量
• 看着植物随你的喝水习惯成长
• 解锁成就，养成健康习惯
• 与朋友分享你的进度

**核心功能：**

🌿 **植物养成系统**
植物会经历6个成长阶段。保持规律喝水，让它茁壮成长！

📊 **智能统计**
通过精美的图表了解你的喝水习惯，发现最佳喝水时间。

🏆 **成就系统**
完成7天打卡、每日目标等成就，全部收集！

🎨 **自定义主题**（Pro）
解锁精美主题，打造专属水滴花园。

☁️ **iCloud 同步**（Pro）
在所有苹果设备间无缝同步你的植物和数据。

💧 **健康 App 集成**
可选同步 Apple Health，自动记录饮水量。

**适合人群：**
• 想养成喝水好习惯的人
• 让喝水变得更有趣
• 追踪每日饮水量
• 通过视觉进度保持动力

**隐私保护：**
• 所有数据存储在本地
• 健康数据未经许不会共享
• 无第三方跟踪或分析
• 可选 iCloud 同步，端到端加密

今天就开始你的健康之旅。下载水滴花园，看着你的植物成长！🌱

---

## 🔑 Keywords

### English Keywords (100 characters max)
```
water,tracker,hydration,plant,growth,health,habit,reminder,drink,wellness
```

### Chinese Keywords (100 characters max)
```
喝水,饮水,健康,习惯,植物,养成,提醒,记录,追踪,生活
```

---

## 💰 Pricing & Monetization

### App Price
Free (with In-App Purchases)

### In-App Purchases

#### Bloom Pro - Yearly
- **Product ID:** `com.pangtong.bloom.pro.yearly` (matches `StoreManager.swift`)
- **Price:** $19.99 / ¥128
- **Type:** Auto-Renewable Subscription
- **Features:**
  - Advanced Analytics
  - Custom Themes (5 Pro themes)
  - Ad-Free Experience
  - iCloud Sync & Backup

#### Bloom Pro - Lifetime (Best Value)
- **Product ID:** `com.pangtong.bloom.pro.lifetime` (matches `StoreManager.swift`)
- **Price:** $49.99 / ¥298
- **Type:** Non-Consumable
- **Features:** All Pro features, forever (no recurring charge)

---

## 🖼️ Screenshots Requirements

### iPhone Screenshots (minimum 3, recommended 5)
**Recommended sizes:**
- iPhone 6.7" (1290 x 2796) - iPhone 14 Pro Max / 15 Pro Max
- iPhone 6.5" (1284 x 2778) - iPhone 12 Pro Max / 13 Pro Max
- iPhone 5.5" (1242 x 2208) - iPhone 8 Plus

**Screenshot sequence:**
1. **Home Screen** - Show the plant and water button
2. **Onboarding** - Show the plant introduction
3. **Statistics** - Show the analytics charts
4. **Achievements** - Show the achievement collection
5. **Settings/Themes** - Show theme customization

### iPad Screenshots (optional but recommended)
- iPad Pro 12.9" (2048 x 2732)
- iPad Pro 11" (1668 x 2388)

---

## 🎨 App Icon

✅ Already configured: 1024x1024 PNG
- Location: `Assets.xcassets/AppIcon.appiconset/`
- Format: iOS 18+ universal icon

---

## 🔒 Privacy Information (App Store Connect)

### Data Used to Track You
**None** - We do not track users

### Data Linked to You
- **Health & Fitness:** Water intake data (if user enables HealthKit)
- **Usage Data:** App interaction (only for local features, not shared)

### Data Not Linked to You
**None** - We don't collect anonymous data either

### Privacy Policy URL
`https://your-website.com/privacy-policy.html` (host the privacy-policy.html file)

---

## 📋 Export Compliance

### Encryption
- **Uses encryption:** Yes (iCloud sync uses Apple's built-in encryption)
- **Exempt:** Yes - Uses standard iOS encryption APIs (ATS, CloudKit)
- **HTCC Answer:** Yes, eligible for exemption under category 5, part 2

### Required Info:
- Does your app use encryption? **Yes**
- Is it eligible for exemption? **Yes**
- Provide exemption documentation: **Standard iOS APIs (CloudKit, HealthKit)**

---

## 📱 App Review Information

### Demo Account (if required)
Not needed - app works without account

### Notes for App Review
```
Bloom is a health & wellness app that gamifies hydration through plant growth.

Key points for review:
1. HealthKit: Used only for water intake tracking (optional)
2. CloudKit: Used for optional iCloud sync
3. In-App Purchases: Pro features (analytics, themes, sync)
4. No user account required
5. All data stored locally by default
6. Sandbox mode available for testing IAP

Test credentials: Not required
```

### Contact Information
- **First Name:** [Your Name]
- **Last Name:** [Your Name]
- **Phone:** [Your Phone]
- **Email:** [Your Email]

---

## 🌍 Localization

### Supported Languages
- English (U.S.)
- Chinese (Simplified)

### Localized Elements
- App Name
- Subtitle
- Description
- Keywords
- What's New (future updates)
- In-App Purchase names

---

## ✅ Pre-Submission Checklist

- [ ] App icon configured (1024x1024) ✅
- [ ] Privacy policy hosted online
- [ ] Privacy policy URL added to App Store Connect
- [ ] Screenshots captured for all required device sizes
- [ ] In-App Purchase products created in App Store Connect
- [ ] IAP product IDs match code (`StoreManager.swift`)
- [ ] Export compliance answered (encryption exemption)
- [ ] Content rating questionnaire completed
- [ ] Age rating: 4+
- [ ] Testing completed on physical device
- [ ] IAP tested in sandbox mode ✅
- [ ] HealthKit permissions tested
- [ ] CloudKit sync tested
- [ ] No crashes or major bugs
- [ ] App works offline (graceful degradation) ✅
- [ ] Privacy policy accessible from app settings

---

## 📞 Support Information

### Support URL
`https://your-website.com/support`

### Marketing URL (optional)
`https://your-website.com/bloom`

### Contact Email
`support@yourcompany.com`

---

## 🚀 Launch Strategy

### Week 1: Soft Launch
- Submit to App Store Review
- Target: China App Store first (smaller market, faster review)
- Monitor crash reports and user feedback

### Week 2: Global Launch
- Enable all regions
- Monitor App Store Connect analytics
- Respond to user reviews

### Week 3-4: Optimization
- Analyze conversion rates
- A/B test screenshots if needed
- Update keywords based on search performance

---

**Last Updated:** June 17, 2026
**Version:** 1.0.0
**Status:** Ready for App Store Submission
