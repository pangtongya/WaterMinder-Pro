// AppState.swift
// 全局应用状态

import SwiftUI
import Foundation

@MainActor
class AppState: ObservableObject, @preconcurrency Codable {
    static let shared = AppState()
    
    @Published var hasCompletedOnboarding: Bool = false
    @Published var dailyGoal: Int = 2000 // 每日目标（毫升）
    @Published var reminderEnabled: Bool = false
    @Published var reminderInterval: Int = 60 // 提醒间隔（分钟）
    @Published var theme: AppTheme = .system
    
    private var saveWorkItem: DispatchWorkItem?
    
    private init() {
        load()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case dailyGoal
        case reminderEnabled
        case reminderInterval
        case theme
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(dailyGoal, forKey: .dailyGoal)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encode(reminderInterval, forKey: .reminderInterval)
        try container.encode(theme, forKey: .theme)
    }
    
    @preconcurrency
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        dailyGoal = try container.decode(Int.self, forKey: .dailyGoal)
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderInterval = try container.decode(Int.self, forKey: .reminderInterval)
        theme = try container.decode(AppTheme.self, forKey: .theme)
    }
    
    // MARK: - Persistence
    private static let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("app_state.json")
    }()
    
    func save() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func performSave() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: Self.storeURL)
        } catch {
            print("[AppState] Save error: \(error)")
        }
    }
    
    private func load() {
        do {
            let data = try Data(contentsOf: Self.storeURL)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            hasCompletedOnboarding = decoded.hasCompletedOnboarding
            dailyGoal = decoded.dailyGoal
            reminderEnabled = decoded.reminderEnabled
            reminderInterval = decoded.reminderInterval
            theme = decoded.theme
        } catch {
            // 首次启动，用默认值
            print("[AppState] Load error: \(error)")
        }
    }
}

// MARK: - AppTheme Enum
enum AppTheme: String, CaseIterable, Codable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
