// ContentView.swift
// 根导航 - TabView 主框架

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "首页"
        case history = "记录"
        case settings = "设置"
        
        var title: String { rawValue }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .history: return "calendar"
            case .settings: return "gearshape"
            }
        }
        
        var filledIcon: String {
            switch self {
            case .home: return "house.fill"
            case .history: return "calendar"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tag(Tab.home)
                .tabItem {
                    Image(systemName: selectedTab == .home ? Tab.home.filledIcon : Tab.home.icon)
                    Text(Tab.home.title)
                }
                
                NavigationStack {
                    HistoryView()
                }
                .tag(Tab.history)
                .tabItem {
                    Image(systemName: selectedTab == .history ? Tab.history.filledIcon : Tab.history.icon)
                    Text(Tab.history.title)
                }
                
                NavigationStack {
                    SettingsView()
                }
                .tag(Tab.settings)
                .tabItem {
                    Image(systemName: selectedTab == .settings ? Tab.settings.filledIcon : Tab.settings.icon)
                    Text(Tab.settings.title)
                }
            }
            .tint(.waterminderPrimary)
        }
        .onAppear {
            setupNotifications()
            syncWidgetData()
        }
        .onChange(of: recordStore.items.count) { _ in
            syncWidgetData()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        if appState.reminderEnabled {
            notificationManager.scheduleWaterReminder(interval: appState.reminderInterval)
        }
    }
    
    private func syncWidgetData() {
        WidgetDataManager.shared.updateWidgetData(
            progress: recordStore.todayProgress,
            totalAmount: recordStore.todayTotalAmount,
            goal: appState.dailyGoal,
            streakDays: recordStore.currentStreak
        )
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState.shared)
            .environmentObject(WaterRecordStore())
            .environmentObject(NotificationManager.shared)
            .environmentObject(HealthManager.shared)
    }
}
