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
        // Initialize file logger first
        _ = FileLogger.shared
        debugLog("🚀 OckCursorApp: Starting up...")
        
        // Set API keys FIRST (before any service initialization)
        debugLog("🔑 Setting API keys...")
        GeminiService.shared.setAPIKey("***REMOVED***")
        ElevenLabsService.shared.setAPIKey("***REMOVED***")
        TokenCompanyService.shared.setAPIKey("ttc_***REMOVED***")
        
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
