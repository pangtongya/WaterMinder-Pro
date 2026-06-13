// WaterMinderApp.swift
// @main 入口

import SwiftUI

@main
struct WaterMinderApp: App {
    @StateObject private var appState: AppState
    @StateObject private var recordStore: WaterRecordStore
    @StateObject private var notificationManager: NotificationManager
    @StateObject private var healthManager: HealthManager
    
    init() {
        _appState = StateObject(wrappedValue: AppState.shared)
        _recordStore = StateObject(wrappedValue: WaterRecordStore())
        _notificationManager = StateObject(wrappedValue: NotificationManager.shared)
        _healthManager = StateObject(wrappedValue: HealthManager.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(recordStore)
                    .environmentObject(notificationManager)
                    .environmentObject(healthManager)
                    .preferredColorScheme(colorScheme)
                    .ignoresSafeArea()
            } else {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(recordStore)
                    .environmentObject(notificationManager)
                    .environmentObject(healthManager)
                    .preferredColorScheme(colorScheme)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appState.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
