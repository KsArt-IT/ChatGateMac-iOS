//
//  ChatGateMacApp.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

@main
struct ChatGateMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        if let screen = NSScreen.main {
                            window.setFrame(screen.visibleFrame, display: true)
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
