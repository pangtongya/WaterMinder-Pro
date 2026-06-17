// NetworkMonitor.swift
// Network connectivity monitor for offline mode

import Foundation
import Network

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
                self?.isConnected = path.status == .satisfied
                self?.isCellular = path.usesInterfaceType(.cellular)
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
