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
        // Load development credentials from the process environment. Never
        // hardcode keys in source or print any portion of them to the logs.
        let environment = ProcessInfo.processInfo.environment
        if let geminiKey = environment["GEMINI_API_KEY"], !geminiKey.isEmpty {
            GeminiService.shared.setAPIKey(geminiKey)
        }
        if let elevenLabsKey = environment["ELEVEN_LABS_API_KEY"], !elevenLabsKey.isEmpty {
            ElevenLabsService.shared.setAPIKey(elevenLabsKey)
        }
        
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
