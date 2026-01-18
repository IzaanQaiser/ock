//
//  OckCursorApp.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

@main
struct OckCursorApp: App {
    init() {
        // Request screen recording permission on app startup
        print("🚀 OckCursorApp: App initializing, requesting screen recording permission...")
        Task {
            await ScreenshotCapture.shared.checkAndRequestPermission()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
