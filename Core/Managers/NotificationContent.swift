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

    // MARK: - 口渴提醒（按健康度分级）

    /// 健康状态（>70）—— 轻松可爱，像宠物撒娇
    static func thirstyRemindersHealthy(plantName: String) -> [Message] {
        [
            Message(title: LF("🌱 %@ 有点渴啦~", comment: "Thirsty healthy title 1", fallback: "🌱 %@ is a bit thirsty~", plantName),
                    body: L("快来陪我喝一口嘛，就一口~", comment: "Thirsty healthy body 1", fallback: "Come drink with me, just one sip~")),
            Message(title: LF("💧 喝水时间到！", comment: "Thirsty healthy title 2", fallback: "💧 Water time!", plantName),
                    body: LF("%@ 眨眨眼睛看着你呢，快喝水呀", comment: "Thirsty healthy body 2", fallback: "%@ is blinking at you, drink up", plantName)),
            Message(title: LF("🌿 嗨~想我了吗？", comment: "Thirsty healthy title 3", fallback: "🌿 Hi~ missed me?", plantName),
                    body: L("我精神满满，但还想更有精神！来杯水吧", comment: "Thirsty healthy body 3", fallback: "I'm full of energy, but want more! Have a glass of water")),
            Message(title: LF("🪴 %@ 在摇叶子打招呼~", comment: "Thirsty healthy title 4", fallback: "🪴 %@ is waving its leaves~", plantName),
                    body: L("喝水喝水，我们一起变更好", comment: "Thirsty healthy body 4", fallback: "Drink water, let's get better together")),
            Message(title: L("✨ 小水滴滴召唤你", comment: "Thirsty healthy title 5", fallback: "✨ Little water drop is calling you"),
                    body: LF("%@ 说：主人主人，陪我喝口水好不好", comment: "Thirsty healthy body 5", fallback: "%@ says: master, drink some water with me please", plantName)),
        ]
    }

    /// 一般状态（40-70）—— 略带撒娇，开始有点蔫
    static func thirstyRemindersNormal(plantName: String) -> [Message] {
        [
            Message(title: LF("😋 %@ 有点渴了…", comment: "Thirsty normal title 1", fallback: "😋 %@ is getting thirsty...", plantName),
                    body: L("叶子开始有点软了，快来给我浇水嘛", comment: "Thirsty normal body 1", fallback: "Leaves are getting soft, come water me please")),
            Message(title: L("💧 咕嘟咕嘟…我想喝水", comment: "Thirsty normal title 2", fallback: "💧 Glug glug... I want water"),
                    body: LF("%@ 舔舔嘴唇，等你好久了啦", comment: "Thirsty normal body 2", fallback: "%@ is licking its lips, waiting for you", plantName)),
            Message(title: LF("🌿 %@ 有点无精打采", comment: "Thirsty normal title 3", fallback: "🌿 %@ looks a bit listless", plantName),
                    body: L("给我一口水，我就能立马精神起来！", comment: "Thirsty normal body 3", fallback: "Give me water and I'll perk right up!")),
            Message(title: L("🥺 主人~你忘了我吗", comment: "Thirsty normal title 4", fallback: "🥺 Master~ did you forget me?"),
                    body: LF("%@ 想喝水想喝水，快救救孩子吧", comment: "Thirsty normal body 4", fallback: "%@ wants water, save me please", plantName)),
            Message(title: LF("🍃 %@ 的叶子垂下来了", comment: "Thirsty normal title 5", fallback: "🍃 %@'s leaves are drooping", plantName),
                    body: L("就喝一口好不好？就一口我就开心了", comment: "Thirsty normal body 5", fallback: "Just one sip? I'll be happy with just one")),
        ]
    }

    /// 口渴状态（<40）—— 委屈巴巴，强烈愧疚感
    static func thirstyRemindersThirsty(plantName: String) -> [Message] {
        [
            Message(title: LF("🥀 %@ 好渴好渴…", comment: "Thirsty thirsty title 1", fallback: "🥀 %@ is so thirsty...", plantName),
                    body: L("我已经等了好久了，你是不是不爱我了呜呜", comment: "Thirsty thirsty body 1", fallback: "I've been waiting so long, don't you love me anymore?")),
            Message(title: L("😢 我快要蔫掉了…", comment: "Thirsty thirsty title 2", fallback: "😢 I'm about to wilt..."),
                    body: LF("%@ 嗓子都干了，求求你给我口水喝吧", comment: "Thirsty thirsty body 2", fallback: "%@'s throat is dry, please give me some water", plantName)),
            Message(title: LF("💔 %@ 有点难过", comment: "Thirsty thirsty title 3", fallback: "💔 %@ is a bit sad", plantName),
                    body: L("你是不是很忙呀…再忙也要记得喝水，还有我在等你", comment: "Thirsty thirsty body 3", fallback: "Are you busy... remember to drink water, I'm waiting for you")),
            Message(title: L("🌵 我快变成仙人掌了", comment: "Thirsty thirsty title 4", fallback: "🌵 I'm turning into a cactus"),
                    body: LF("%@ 真的真的很渴，快来救我！", comment: "Thirsty thirsty body 4", fallback: "%@ is really really thirsty, come save me!", plantName)),
            Message(title: LF("😿 %@ 委屈巴巴", comment: "Thirsty thirsty title 5", fallback: "😿 %@ looks wronged", plantName),
                    body: L("再不来喝水，我…我就哭给你看！呜呜", comment: "Thirsty thirsty body 5", fallback: "If you don't drink water soon... I'll cry! *sobs*")),
        ]
    }

    // MARK: - 早晨提醒

    /// 早晨提醒 —— 元气满满，新的一天开始了，结合植物元素
    static func morningReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("🌅 早安！%@ 醒啦~", comment: "Morning reminder title 1", fallback: "🌅 Good morning! %@ is awake~", plantName),
                    body: L("新的一天开始啦，第一杯水我们一起喝", comment: "Morning reminder body 1", fallback: "A new day begins, let's have the first glass of water together")),
            Message(title: L("☀️ 阳光正好，喝水趁早", comment: "Morning reminder title 2", fallback: "☀️ The sun is shining, drink water early"),
                    body: LF("%@ 已经伸完懒腰了，等你来喝水哦", comment: "Morning reminder body 2", fallback: "%@ already stretched, waiting for you to drink water", plantName)),
            Message(title: LF("🌱 %@ 说：早上好呀！", comment: "Morning reminder title 3", fallback: "🌱 %@ says: good morning!", plantName),
                    body: L("清晨第一杯水，唤醒一天好心情", comment: "Morning reminder body 3", fallback: "First glass of water in the morning, awakens a good mood all day")),
            Message(title: L("🌸 花开了，你醒了吗", comment: "Morning reminder title 4", fallback: "🌸 Flowers are blooming, are you awake?"),
                    body: L("来杯温水，开启元气满满的一天吧", comment: "Morning reminder body 4", fallback: "Have a glass of warm water, start an energetic day")),
            Message(title: LF("🌿 %@ 迎着晨光在生长", comment: "Morning reminder title 5", fallback: "🌿 %@ is growing in the morning light", plantName),
                    body: L("你也快喝杯水，和我一起茁壮成长", comment: "Morning reminder body 5", fallback: "You drink water too, grow strong with me")),
            Message(title: L("🐦 小鸟都起床了，你呢", comment: "Morning reminder title 6", fallback: "🐦 The birds are up, what about you?"),
                    body: L("早安~ 喝杯水，今天也要加油哦", comment: "Morning reminder body 6", fallback: "Good morning~ drink water, keep it up today")),
            Message(title: LF("🌻 %@ 面向太阳微笑", comment: "Morning reminder title 7", fallback: "🌻 %@ is smiling at the sun", plantName),
                    body: L("你也笑一个嘛，先喝口水再说", comment: "Morning reminder body 7", fallback: "You smile too, but first drink some water")),
            Message(title: L("🍀 早安，幸运的你", comment: "Morning reminder title 8", fallback: "🍀 Good morning, lucky you"),
                    body: L("今天的第一杯水，会带来好运气哦", comment: "Morning reminder body 8", fallback: "The first glass of water today brings good luck")),
            Message(title: LF("🌷 %@ 含苞待放", comment: "Morning reminder title 9", fallback: "🌷 %@ is ready to bloom", plantName),
                    body: L("喝杯水，我们一起绽放今天的精彩", comment: "Morning reminder body 9", fallback: "Drink water, let's bloom together today")),
            Message(title: L("🌞 太阳公公晒屁股啦", comment: "Morning reminder title 10", fallback: "🌞 The sun is shining on your butt"),
                    body: L("快起床喝水，新的一天在等你呢", comment: "Morning reminder body 10", fallback: "Wake up and drink water, a new day is waiting for you")),
        ]
    }

    // MARK: - 晚上提醒

    /// 晚上提醒 —— 温馨晚安，别忘记今天最后一杯水
    static func eveningReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("🌙 %@ 准备睡觉啦", comment: "Evening reminder title 1", fallback: "🌙 %@ is getting ready for bed", plantName),
                    body: L("睡前最后一杯水，我们一起喝完好吗", comment: "Evening reminder body 1", fallback: "Last glass of water before bed, let's finish it together")),
            Message(title: L("✨ 夜深了，记得喝水", comment: "Evening reminder title 2", fallback: "✨ It's late, remember to drink water"),
                    body: LF("%@ 打了个哈欠，等你喝完水就睡觉", comment: "Evening reminder body 2", fallback: "%@ yawned, waiting for you to finish water then sleep", plantName)),
            Message(title: LF("🌟 %@ 说：晚安呀~", comment: "Evening reminder title 3", fallback: "🌟 %@ says: good night~", plantName),
                    body: L("今天辛苦啦，喝杯温水暖暖再睡", comment: "Evening reminder body 3", fallback: "Good work today, drink warm water before bed")),
            Message(title: L("🌛 月亮出来了", comment: "Evening reminder title 4", fallback: "🌛 The moon is out"),
                    body: L("别忘了今天最后一杯水哦，晚安", comment: "Evening reminder body 4", fallback: "Don't forget the last glass of water today, good night")),
            Message(title: LF("🥱 %@ 困困的", comment: "Evening reminder title 5", fallback: "🥱 %@ is sleepy", plantName),
                    body: L("喝完这杯水，我们一起做个好梦", comment: "Evening reminder body 5", fallback: "Finish this glass of water, let's have sweet dreams together")),
            Message(title: L("🌌 星空真美", comment: "Evening reminder title 6", fallback: "🌌 The starry sky is beautiful"),
                    body: L("你今天表现很棒，喝杯水奖励自己吧", comment: "Evening reminder body 6", fallback: "You did great today, drink water to reward yourself")),
            Message(title: LF("🌿 %@ 合上了叶子", comment: "Evening reminder title 7", fallback: "🌿 %@ closed its leaves", plantName),
                    body: L("睡前一杯水，明天醒来精神满满", comment: "Evening reminder body 7", fallback: "A glass of water before bed, wake up refreshed tomorrow")),
            Message(title: L("💤 晚安，辛苦的一天结束了", comment: "Evening reminder title 8", fallback: "💤 Good night, the hard day is over"),
                    body: LF("%@ 陪着你，喝完水好好休息吧", comment: "Evening reminder body 8", fallback: "%@ is with you, drink water and rest well", plantName)),
            Message(title: LF("🌙 %@ 在月光下等你", comment: "Evening reminder title 9", fallback: "🌙 %@ is waiting for you in the moonlight", plantName),
                    body: L("最后一杯水，为今天画上完美句号", comment: "Evening reminder body 9", fallback: "Last glass of water, perfect ending to today")),
            Message(title: L("⭐ 星星眨眨眼，该睡觉啦", comment: "Evening reminder title 10", fallback: "⭐ Stars are blinking, time for bed"),
                    body: L("记得喝水哦，明天见，做个好梦", comment: "Evening reminder body 10", fallback: "Remember to drink water, see you tomorrow, sweet dreams")),
        ]
    }

    // MARK: - 鼓励类通知（连续喝水3天以上）

    /// 鼓励类通知 —— 夸奖、鼓励、坚持就是胜利
    static func encouragementReminders(plantName: String) -> [Message] {
        [
            Message(title: LF("🎉 太厉害了！%@ 为你骄傲", comment: "Encouragement title 1", fallback: "🎉 Amazing! %@ is proud of you", plantName),
                    body: L("连续喝水3天啦，你真的超棒的！继续保持", comment: "Encouragement body 1", fallback: "3 days straight of drinking water, you're amazing! Keep it up")),
            Message(title: L("💪 坚持就是胜利", comment: "Encouragement title 2", fallback: "💪 Persistence is victory"),
                    body: LF("%@ 说：主人你好厉害，我越来越喜欢你了", comment: "Encouragement body 2", fallback: "%@ says: master you're so cool, I like you more and more", plantName)),
            Message(title: LF("🌟 %@ 长得越来越好了", comment: "Encouragement title 3", fallback: "🌟 %@ is getting better and better", plantName),
                    body: L("这都是你的功劳呀，继续加油！", comment: "Encouragement body 3", fallback: "It's all thanks to you, keep going!")),
            Message(title: L("🏆 你就是喝水小冠军", comment: "Encouragement title 4", fallback: "🏆 You're the water drinking champion"),
                    body: L("连续打卡这么多天，太值得表扬了！", comment: "Encouragement body 4", fallback: "So many consecutive days, you deserve praise!")),
            Message(title: LF("✨ %@ 在为你鼓掌", comment: "Encouragement title 5", fallback: "✨ %@ is clapping for you", plantName),
                    body: L("你的坚持让我茁壮成长，谢谢你呀", comment: "Encouragement body 5", fallback: "Your persistence makes me grow strong, thank you")),
            Message(title: L("🌈 好习惯养成中", comment: "Encouragement title 6", fallback: "🌈 Building a good habit"),
                    body: L("你已经坚持这么久了，真的超棒！", comment: "Encouragement body 6", fallback: "You've坚持 so long, you're really great!")),
            Message(title: LF("🌻 %@ 开得更艳了", comment: "Encouragement title 7", fallback: "🌻 %@ is blooming more beautifully", plantName),
                    body: L("因为有你的照顾，我每天都很开心", comment: "Encouragement body 7", fallback: "Because of your care, I'm happy every day")),
            Message(title: L("💖 有你真好", comment: "Encouragement title 8", fallback: "💖 It's great to have you"),
                    body: L("你认真喝水的样子，真的很酷！继续呀", comment: "Encouragement body 8", fallback: "The way you drink water seriously is really cool! Keep going")),
            Message(title: LF("🎊 恭喜你坚持下来了", comment: "Encouragement title 9", fallback: "🎊 Congratulations on keeping it up", plantName),
                    body: L("%@ 见证了你的努力，我们一起变得更好", comment: "Encouragement body 9", fallback: "%@ has witnessed your efforts, let's get better together")),
            Message(title: L("🚀 你在闪闪发光", comment: "Encouragement title 10", fallback: "🚀 You're shining"),
                    body: L("好习惯的力量是无穷的，继续保持这份热爱", comment: "Encouragement body 10", fallback: "The power of good habits is endless, keep this passion")),
        ]
    }

    // MARK: - 加油类通知（进度提醒）

    /// 进度 50% —— 进度反馈、快要完成了
    static func progressRemindersHalf(plantName: String) -> [Message] {
        [
            Message(title: LF("🎉 过半啦！%@ 很开心", comment: "Progress half title 1", fallback: "🎉 Halfway there! %@ is happy", plantName),
                    body: L("今天已经完成一半了，继续加油呀", comment: "Progress half body 1", fallback: "Halfway done today, keep going")),
            Message(title: L("⚡ 50% 达成！", comment: "Progress half title 2", fallback: "⚡ 50% achieved!"),
                    body: LF("%@ 说：你好厉害，一半都完成了", comment: "Progress half body 2", fallback: "%@ says: you're amazing, halfway done", plantName)),
            Message(title: LF("🌿 %@ 精神多了", comment: "Progress half title 3", fallback: "🌿 %@ is much more energetic", plantName),
                    body: L("再喝一半就达标啦，你可以的！", comment: "Progress half body 3", fallback: "Half more to reach the goal, you can do it!")),
            Message(title: L("🎯 目标进度：50%", comment: "Progress half title 4", fallback: "🎯 Progress: 50%"),
                    body: L("不错不错，继续保持这个节奏", comment: "Progress half body 4", fallback: "Not bad, keep up this pace")),
            Message(title: LF("✨ %@ 在为你加油", comment: "Progress half title 5", fallback: "✨ %@ is cheering for you", plantName),
                    body: L("已经走了一半的路，剩下的也一定没问题", comment: "Progress half body 5", fallback: "Halfway there, the rest will be easy too")),
        ]
    }

    /// 进度 75% —— 快要完成了
    static func progressRemindersThreeQuarters(plantName: String) -> [Message] {
        [
            Message(title: LF("🌟 75% 啦！%@ 超开心", comment: "Progress 75 title 1", fallback: "🌟 75% done! %@ is super happy", plantName),
                    body: L("就差一点点了，胜利就在眼前！", comment: "Progress 75 body 1", fallback: "Almost there, victory is in sight!")),
            Message(title: L("🏃 马上就要达标啦", comment: "Progress 75 title 2", fallback: "🏃 Almost at the goal"),
                    body: LF("%@ 说：再加把劲，我已经开始期待了", comment: "Progress 75 body 2", fallback: "%@ says: push a little more, I'm already looking forward to it", plantName)),
            Message(title: LF("🎉 %@ 快要喝饱啦", comment: "Progress 75 title 3", fallback: "🎉 %@ is almost full", plantName),
                    body: L("你也快完成了，今天表现真棒！", comment: "Progress 75 body 3", fallback: "You're almost done too, great job today!")),
            Message(title: L("💪 坚持住，就差最后一点", comment: "Progress 75 title 4", fallback: "💪 Hang in there, just a little more"),
                    body: L("75% 已经完成，剩下的 25% 轻松拿下", comment: "Progress 75 body 4", fallback: "75% done, the remaining 25% will be easy")),
            Message(title: LF("🌻 %@ 准备开花了", comment: "Progress 75 title 5", fallback: "🌻 %@ is about to bloom", plantName),
                    body: L("喝完这最后一点，我们一起庆祝吧", comment: "Progress 75 body 5", fallback: "Finish this last bit, let's celebrate together")),
        ]
    }

    // MARK: - 达标鼓励（当天已达标，鼓励保持）

    static func encouragement(plantName: String) -> [Message] {
        [
            Message(title: LF("🎉 %@ 今天喝饱啦", comment: "Encouragement title", fallback: "🎉 %@ is fully hydrated today", plantName),
                    body: L("它精神焕发，明天也要继续哦", comment: "Encouragement body", fallback: "It's glowing, keep it up tomorrow")),
            Message(title: L("🌸 今天完成得真好", comment: "Encouragement title 2", fallback: "🌸 Great job today"),
                    body: LF("%@ 因为你又长大了一点", comment: "Encouragement body 2", fallback: "%@ grew a bit more, thanks to you", plantName)),
        ]
    }

    // MARK: - 智能选取

    /// 本地化辅助函数：如果 key 找不到对应的翻译，返回 fallback 英文
    private static func L(_ key: String, comment: String, fallback: String) -> String {
        let value = NSLocalizedString(key, comment: comment)
        return value == key ? fallback : value
    }

    /// 格式化字符串的本地化辅助函数
    private static func LF(_ key: String, comment: String, fallback: String, _ args: CVarArg...) -> String {
        let format = L(key, comment: comment, fallback: fallback)
        return String(format: format, arguments: args)
    }

    /// 根据健康度随机挑选一条口渴提醒文案
    /// - Parameters:
    ///   - health: 健康度（0-100）
    ///   - plantName: 植物名字
    /// - Returns: 随机选中的提醒文案
    static func randomThirstyReminder(for health: Double, plantName: String) -> Message {
        let pool: [Message]
        switch health {
        case 70...:
            pool = thirstyRemindersHealthy(plantName: plantName)
        case 40..<70:
            pool = thirstyRemindersNormal(plantName: plantName)
        default:
            pool = thirstyRemindersThirsty(plantName: plantName)
        }
        return pool.randomElement() ?? Message(
            title: L("喝水时间", comment: "Water time", fallback: "Water time"),
            body: L("该喝水啦！💧", comment: "Time to drink water", fallback: "Time to drink water! 💧")
        )
    }

    /// 根据健康度挑选一条最合适的文案
    static func pick(for health: Double, plantName: String) -> Message {
        randomThirstyReminder(for: health, plantName: plantName)
    }
}
