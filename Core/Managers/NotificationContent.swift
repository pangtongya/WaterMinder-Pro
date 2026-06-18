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
            Message(title: String(format: NSLocalizedString("🌱 %@ 想喝点水了", comment: ""), plantName),
                    body: NSLocalizedString("它正等着你呢，来一口吧", comment: "")),
            Message(title: NSLocalizedString("💧 该浇水啦", comment: ""),
                    body: String(format: NSLocalizedString("%@ 长得正欢，别让它干着", comment: ""), plantName)),
            Message(title: String(format: NSLocalizedString("🌿 %@ 在向你招手", comment: ""), plantName),
                    body: NSLocalizedString("喝杯水，它会更有精神", comment: "")),
            Message(title: NSLocalizedString("🪴 你的小植物在期盼", comment: ""),
                    body: NSLocalizedString("一口水，换来它的笑容", comment: "")),
        ]
    }

    /// 蔫了（健康度偏低）—— 愧疚感最强的文案
    static func wiltingReminders(plantName: String) -> [Message] {
        [
            Message(title: String(format: NSLocalizedString("🥀 %@ 有点蔫了……", comment: ""), plantName),
                    body: NSLocalizedString("它渴了好久了，快来救救它", comment: "")),
            Message(title: NSLocalizedString("🍂 它快撑不住了", comment: ""),
                    body: String(format: NSLocalizedString("%@ 需要你，现在就喝一口吧", comment: ""), plantName)),
            Message(title: String(format: NSLocalizedString("😟 %@ 无精打采", comment: ""), plantName),
                    body: NSLocalizedString("叶子都垂下来了，快给它浇水", comment: "")),
            Message(title: NSLocalizedString("💧 它在等你", comment: ""),
                    body: String(format: NSLocalizedString("%@ 已经等很久了，别让它失望", comment: ""), plantName)),
        ]
    }

    /// 枯萎边缘（健康度极低）
    static func criticalReminders(plantName: String) -> [Message] {
        [
            Message(title: String(format: NSLocalizedString("💔 %@ 快要枯萎了", comment: ""), plantName),
                    body: NSLocalizedString("再不喝水就来不及了！求求你", comment: "")),
            Message(title: NSLocalizedString("🆘 紧急求救", comment: ""),
                    body: String(format: NSLocalizedString("%@ 命悬一线，立刻喝杯水吧", comment: ""), plantName)),
        ]
    }

    /// 达标鼓励（当天已达标，鼓励保持）
    static func encouragement(plantName: String) -> [Message] {
        [
            Message(title: String(format: NSLocalizedString("🎉 %@ 今天喝饱啦", comment: ""), plantName),
                    body: NSLocalizedString("它精神焕发，明天也要继续哦", comment: "")),
            Message(title: NSLocalizedString("🌸 今天完成得真好", comment: ""),
                    body: String(format: NSLocalizedString("%@ 因为你又长大了一点", comment: ""), plantName)),
        ]
    }

    // MARK: - 智能选取

    /// 根据健康度挑选一条最合适的文案
    static func pick(for health: Double, plantName: String) -> Message {
        let pool: [Message]
        switch health {
        case ..<25:  pool = criticalReminders(plantName: plantName)
        case ..<50:  pool = wiltingReminders(plantName: plantName)
        default:     pool = healthyReminders(plantName: plantName)
        }
        return pool.randomElement() ?? healthyReminders(plantName: plantName).first ?? Message(
            title: NSLocalizedString("喝水时间", comment: "Water time"),
            body: NSLocalizedString("该喝水啦！💧", comment: "Time to drink water!")
        )
    }
}
