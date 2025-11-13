//
//  TabMemoryManager.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import Foundation
import Combine
import AppKit

class TabMemoryManager: ObservableObject {
    static let shared = TabMemoryManager()
    
    @Published private(set) var lastAccessTimes: [TabType: Date] = [:]
    
    private var cleanupTimer: Timer?
    private let inactivityThreshold: TimeInterval = 30 * 60 // 30 минут
    private let checkInterval: TimeInterval = 60 // Проверка каждую минуту
    
    var onTabShouldUnload: ((TabType) -> Void)?
    
    private init() {
        startCleanupTimer()
        setupMemoryWarningObserver()
    }
    
    func markTabAccessed(_ tab: TabType) {
        lastAccessTimes[tab] = Date()
    }
    
    func removeTab(_ tab: TabType) {
        lastAccessTimes.removeValue(forKey: tab)
    }
    
    func startCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkInactiveTabs()
        }
    }
    
    func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    private func checkInactiveTabs() {
        let now = Date()
        var tabsToUnload: [TabType] = []
        
        for (tab, lastAccess) in lastAccessTimes {
            let timeSinceLastAccess = now.timeIntervalSince(lastAccess)
            
            if timeSinceLastAccess >= inactivityThreshold {
                tabsToUnload.append(tab)
            }
        }
        
        // Выгружаем вкладки
        for tab in tabsToUnload {
            print("⏰ Вкладка \(tab.title) неактивна \(Int(inactivityThreshold / 60)) минут")
            onTabShouldUnload?(tab)
            lastAccessTimes.removeValue(forKey: tab)
        }
    }
    
    // Реагируем на предупреждения о памяти
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Проверяем неактивные вкладки при активации приложения
            self?.checkInactiveTabs()
        }
    }
    
    deinit {
        stopCleanupTimer()
        NotificationCenter.default.removeObserver(self)
        print("🗑️ TabMemoryManager деинициализирован")
    }
}
