// SoundManager.swift
// 音效管理器 —— 处理音效播放、音量控制、静音设置
//
// 功能：预加载常用音效、支持音量控制、静音开关持久化、系统音效 fallback。
// 不包含实际音频文件，仅保留代码结构，便于后续添加。

import Foundation
import AVFoundation
import AudioToolbox

// MARK: - 音效类型

enum SoundEffect: String, CaseIterable {
    /// 水滴声（喝水记录时）
    case waterDrop
    /// 植物生长声（阶段升级时）
    case plantGrow
    /// 成就解锁声
    case achievement
    /// 收获声
    case harvest
    /// 普通点击声
    case click
    /// 成功提示音
    case success
    /// 错误提示音
    case error
    /// 通知提示音
    case notification

    /// 对应的音频文件名（不含扩展名）
    var fileName: String {
        rawValue
    }

    /// 音频文件扩展名
    var fileExtension: String {
        "wav"
    }

    /// 系统音效 fallback（当没有音频文件时使用）
    var systemSoundID: SystemSoundID {
        switch self {
        case .waterDrop:
            return 1104 // 点击音效
        case .plantGrow:
            return 1105 // 低音量点击
        case .achievement:
            return 1306 // 消息发送成功
        case .harvest:
            return 1304 // 通知默认
        case .click:
            return 1104 // 点击音效
        case .success:
            return 1306 // 消息发送成功
        case .error:
            return 1106 // 错误提示
        case .notification:
            return 1304 // 通知默认
        }
    }
}

// MARK: - 音效管理器

@MainActor
final class SoundManager: NSObject {
    static let shared = SoundManager()

    // MARK: - 存储键

    private enum Keys {
        static let soundEnabled = "bloom.soundEnabled"
        static let soundVolume = "bloom.soundVolume"
    }

    // MARK: - 属性

    /// 预加载的音效播放器缓存
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    /// 音频会话
    private let audioSession = AVAudioSession.sharedInstance()

    /// 中断观察者
    private var interruptionObserver: NSObjectProtocol?

    /// 路由变更观察者
    private var routeChangeObserver: NSObjectProtocol?

    // MARK: - 公开属性

    /// 是否静音
    var isMuted: Bool {
        get {
            !UserDefaults.standard.bool(forKey: Keys.soundEnabled)
        }
        set {
            UserDefaults.standard.set(!newValue, forKey: Keys.soundEnabled)
        }
    }

    /// 音效开关状态
    var isSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.soundEnabled) == nil {
                return true // 默认开启
            }
            return UserDefaults.standard.bool(forKey: Keys.soundEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.soundEnabled)
        }
    }

    /// 当前音量（0.0 - 1.0，默认 0.5）
    var volume: Float {
        get {
            if UserDefaults.standard.object(forKey: Keys.soundVolume) == nil {
                return 0.5
            }
            return UserDefaults.standard.float(forKey: Keys.soundVolume)
        }
        set {
            let clamped = min(max(newValue, 0.0), 1.0)
            UserDefaults.standard.set(clamped, forKey: Keys.soundVolume)
            updatePlayersVolume(clamped)
        }
    }

    // MARK: - 初始化

    private override init() {
        super.init()
        setupAudioSession()
        preloadAllEffects()
        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - 音频会话配置

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            #if DEBUG
            print("[SoundManager] 音频会话配置失败: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - 中断处理

    private func setupInterruptionObserver() {
        let center = NotificationCenter.default

        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }

        routeChangeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleRouteChange(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            stopAll()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                do {
                    try audioSession.setActive(true)
                } catch {
                    #if DEBUG
                    print("[SoundManager] 中断后恢复音频会话失败: \(error.localizedDescription)")
                    #endif
                }
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return
        }

        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)

        switch reason {
        case .categoryChange:
            do {
                try audioSession.setActive(true)
            } catch {
                #if DEBUG
                print("[SoundManager] 路由变更后激活音频会话失败: \(error.localizedDescription)")
                #endif
            }
        default:
            break
        }
    }

    // MARK: - 预加载

    /// 预加载所有音效
    private func preloadAllEffects() {
        for effect in SoundEffect.allCases {
            preload(effect)
        }
    }

    /// 预加载单个音效
    private func preload(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(
            forResource: effect.fileName,
            withExtension: effect.fileExtension
        ) else {
            #if DEBUG
            print("[SoundManager] 未找到音效文件: \(effect.fileName).\(effect.fileExtension)，将使用系统音效 fallback")
            #endif
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[effect] = player
        } catch {
            #if DEBUG
            print("[SoundManager] 预加载音效失败 \(effect.rawValue): \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - 播放控制

    /// 播放指定音效
    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        guard volume > 0 else { return }

        if let player = players[effect] {
            playWithAVPlayer(player, effect: effect)
        } else {
            playSystemSound(effect)
        }
    }

    private func playWithAVPlayer(_ player: AVAudioPlayer, effect: SoundEffect) {
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        player.volume = volume
        player.play()
    }

    /// 使用系统音效作为 fallback
    private func playSystemSound(_ effect: SoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    /// 停止所有正在播放的音效
    func stopAll() {
        for player in players.values {
            player.stop()
            player.currentTime = 0
        }
    }

    /// 设置音量（0.0 - 1.0）
    func setVolume(_ volume: Float) {
        self.volume = volume
    }

    /// 更新所有播放器的音量
    private func updatePlayersVolume(_ volume: Float) {
        for player in players.values {
            player.volume = volume
        }
    }

    // MARK: - 设置项本地化

    /// 音效设置标题
    static var soundSettingsTitle: String {
        NSLocalizedString("音效", comment: "音效设置标题")
    }

    /// 音量设置标题
    static var volumeTitle: String {
        NSLocalizedString("音量", comment: "音量设置标题")
    }

    /// 音效开关描述
    static var soundEnabledDescription: String {
        NSLocalizedString("开启后，浇水、收获等操作会播放音效", comment: "音效开关描述")
    }
}
