// NetworkMonitor.swift
// Network connectivity monitor for offline mode

import Foundation
import Network

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var isCellular = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? true
                let isNowConnected = path.status == .satisfied
                self?.isConnected = isNowConnected
                self?.isCellular = path.usesInterfaceType(.cellular)
                
                if wasConnected != isNowConnected {
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: self,
                        userInfo: ["isConnected": isNowConnected]
                    )
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
