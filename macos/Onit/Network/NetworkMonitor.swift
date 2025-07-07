//
//  NetworkMonitor.swift
//  Onit
//
//  Created by Loyd Kim on 7/7/25.
//

import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    // MARK: - Singleton Instance
    
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    private let networkMonitor: NWPathMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "com.onitapp.networkMonitorQueue")
    
    /// Wi-Fi, Cellular, Wired Ethernet, Loopback, Other
    @Published private(set) var networkInterface: NWInterface.InterfaceType? = nil
    @Published private(set) var isOnline = true
    
    private init() {
        self.networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                /// Wi-Fi, Cellular, Wired Ethernet, Loopback, Other
                self.updateNetworkInterface(path)
                self.updateIsOnline(path)
            }
        }
        
        /// Initializing real-time network monitoring.
        /// Queue allows monitoring to occur off the main thread, preventing hits on UI performance.
        self.networkMonitor.start(queue: networkMonitorQueue)
        
        /// This is required to accurately synchronize set network properties ON START.
        /// Every moment after is then updated in real time by `monitor.pathUpdateHandler` above.
        initializeNetworkProperties()
    }
    
    /// This technically never fires, but it never hurts to set this up, *just in case*.
    deinit {
        self.networkMonitor.cancel()
    }
    
    // MARK: - Private Functions
    
    private func initializeNetworkProperties() {
        let currentPath: NWPath = self.networkMonitor.currentPath
        
        updateNetworkInterface(currentPath)
        updateIsOnline(currentPath)
    }
    
    private func updateNetworkInterface(_ path: NWPath) {
        self.networkInterface = path
            .availableInterfaces
            .first { path.usesInterfaceType($0.type) }?
            .type
    }
    
    private func updateIsOnline(_ path: NWPath) {
        let isValidInternetPath = path.usesInterfaceType(.wifi) ||
                                  path.usesInterfaceType(.wiredEthernet) ||
                                  path.usesInterfaceType(.cellular)
        
        self.isOnline = path.status == .satisfied && isValidInternetPath
    }
}
