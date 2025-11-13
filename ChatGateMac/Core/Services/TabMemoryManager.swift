//
//  TabMemoryManager.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import Foundation
import Combine

class TabMemoryManager: ObservableObject {
    static let shared = TabMemoryManager()
    
    @Published private(set) var lastAccessTimes: [TabType: Date] = [:]
    
    private var cleanupTimer: Timer?
    private let inactivityThreshold: TimeInterval = 30 * 60 // 30 минут
    
    var onTabShouldUnload: ((TabType) -> Void)?
    
    init() {
        startCleanupTimer()
    }
    
    func markTabAccessed(_ tab: TabType) {
        lastAccessTimes[tab] = Date()
    }
    
    func startCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkInactiveTabs()
        }
    }
    
    func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    private func checkInactiveTabs() {
        let now = Date()
        
        for (tab, lastAccess) in lastAccessTimes {
            let timeSinceLastAccess = now.timeIntervalSince(lastAccess)
            
            if timeSinceLastAccess >= inactivityThreshold {
                onTabShouldUnload?(tab)
                lastAccessTimes.removeValue(forKey: tab)
            }
        }
    }
    
    deinit {
        stopCleanupTimer()
    }
}
