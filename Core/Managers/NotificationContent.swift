// NotificationContent.swift
// 通知文案库 —— 从"该喝水了"(自律)到"它渴了"(愧疚/情感)
//
// 设计：文案随机化 + 按植物状态/时段变化，避免看腻。
// 这是 chickenfocus 心理学的直接落地：让用户对一株生命产生责任感。
//
// 所有文案已本地化（NSLocalizedString），支持中文和英文。

import Foundation

enum NotificationContent {
    struct Message {
        let title: String
        let body: String
    }

    // MARK: - 根据植物状态生成文案

    /// 通用提醒（健康度还行）
    static func healthyReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("🌱 %@ 想喝点水了", comment: "Healthy reminder title", fallback: "🌱 %@ is thirsty", plantName),
                    body: L("它正等着你呢，来一口吧", comment: "Healthy reminder body", fallback: "It's waiting for you, take a sip")),
            Message(title: L("💧 该浇水啦", comment: "Healthy reminder title", fallback: "💧 Time to water"),
                    body: LF("%@ 长得正欢，别让它干着", comment: "Healthy reminder body", fallback: "%@ is thriving, don't let it dry out", plantName)),
            Message(title: LF("🌿 %@ 在向你招手", comment: "Healthy reminder title", fallback: "🌿 %@ is waving at you", plantName),
                    body: L("喝杯水，它会更有精神", comment: "Healthy reminder body", fallback: "A sip of water will perk it up")),
            Message(title: L("🪴 你的小植物在期盼", comment: "Healthy reminder title", fallback: "🪴 Your little plant is waiting"),
                    body: L("一口水，换来它的笑容", comment: "Healthy reminder body", fallback: "One sip for its smile")),
        ]
    }

    /// 蔫了（健康度偏低）—— 愧疚感最强的文案
    static func wiltingReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("🥀 %@ 有点蔫了……", comment: "Wilting reminder title", fallback: "🥀 %@ looks a bit wilted...", plantName),
                    body: L("它渴了好久了，快来救救它", comment: "Wilting reminder body", fallback: "It's been thirsty for a while, come save it")),
            Message(title: L("🍂 它快撑不住了", comment: "Wilting reminder title", fallback: "🍂 It can barely hold on"),
                    body: LF("%@ 需要你，现在就喝一口吧", comment: "Wilting reminder body", fallback: "%@ needs you, take a sip now", plantName)),
            Message(title: LF("😟 %@ 无精打采", comment: "Wilting reminder title", fallback: "😟 %@ looks listless", plantName),
                    body: L("叶子都垂下来了，快给它浇水", comment: "Wilting reminder body", fallback: "Leaves are drooping, water it soon")),
            Message(title: L("💧 它在等你", comment: "Wilting reminder title", fallback: "💧 It's waiting for you"),
                    body: LF("%@ 已经等很久了，别让它失望", comment: "Wilting reminder body", fallback: "%@ has waited long, don't let it down", plantName)),
        ]
    }

    /// 枯萎边缘（健康度极低）
    static func criticalReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("💔 %@ 快要枯萎了", comment: "Critical reminder title", fallback: "💔 %@ is withering away", plantName),
                    body: L("再不喝水就来不及了！求求你", comment: "Critical reminder body", fallback: "Hurry before it's too late! Please")),
            Message(title: L("🆘 紧急求救", comment: "Critical reminder title", fallback: "🆘 Emergency plea"),
                    body: LF("%@ 命悬一线，立刻喝杯水吧", comment: "Critical reminder body", fallback: "%@ is hanging by a thread, drink water now", plantName)),
        ]
    }

    /// 达标鼓励（当天已达标，鼓励保持）
    static func encouragement(plantName: String) -> [Message] {
        [
            Message(title: LF("🎉 %@ 今天喝饱啦", comment: "Encouragement title", fallback: "🎉 %@ is fully hydrated today", plantName),
                    body: L("它精神焕发，明天也要继续哦", comment: "Encouragement body", fallback: "It's glowing, keep it up tomorrow")),
            Message(title: L("🌸 今天完成得真好", comment: "Encouragement title", fallback: "🌸 Great job today"),
                    body: LF("%@ 因为你又长大了一点", comment: "Encouragement body", fallback: "%@ grew a bit more, thanks to you", plantName)),
        ]
    }

    // MARK: - 智能选取

    /// 本地化辅助函数：如果 key 找不到对应的翻译，返回 fallback 英文
    private static func L(_ key: String, comment: String, fallback: String) -> String {
        let value = NSLocalizedString(key, comment: comment)
        // 如果返回值等于 key 本身，说明没有找到翻译
        return value == key ? fallback : value
    }

    /// 格式化字符串的本地化辅助函数
    private static func LF(_ key: String, comment: String, fallback: String, _ args: CVarArg...) -> String {
        let format = L(key, comment: comment, fallback: fallback)
        return String(format: format, arguments: args)
    }

    /// 根据健康度挑选一条最合适的文案
    static func pick(for health: Double, plantName: String) -> Message {
        let pool: [Message]
        switch health {
        case ..<25:  pool = criticalReminders(plantName: plantName)
        case ..<50:  pool = wiltingReminders(plantName: plantName)
        default:     pool = healthyReminders(plantName: plantName)
        }
        return pool.randomElement() ?? healthyReminders(plantName: plantName).first ?? Message(
            title: L("喝水时间", comment: "Water time", fallback: "Water time"),
            body: L("该喝水啦！💧", comment: "Time to drink water", fallback: "Time to drink water! 💧")
        )
    }
}
