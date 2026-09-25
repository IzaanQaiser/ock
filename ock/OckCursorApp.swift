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
        // Set API keys FIRST (before any service initialization)
        print("🚀 OckCursorApp: Setting API keys...")
        GeminiService.shared.setAPIKey(GEMINI_API_KEY)
        ElevenLabsService.shared.setAPIKey(ELEVEN_LABS_API_KEY)
        
        // Verify Gemini key was set correctly
        let verifiedKey = GeminiService.shared.getCurrentAPIKey()
        print("🔑 OckCursorApp: Verified Gemini key: \(String(verifiedKey.prefix(20)))...")
        
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
