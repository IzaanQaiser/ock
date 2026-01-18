//
//  OvershootCoordinator.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import Combine

/// Coordinates the Option key → Screenshot → Backend → Overshoot flow
class OvershootCoordinator: ObservableObject {
    static let shared = OvershootCoordinator()
    
    @Published var isProcessing: Bool = false
    @Published var lastResult: String? = nil
    @Published var lastError: String? = nil
    @Published var isMonitoring: Bool = false
    
    private var hotkeyService = HotkeyService.shared
    private var screenshotService = ScreenshotService.shared
    private var backendService = BackendService.shared
    
    private init() {
        setupHotkeyHandler()
    }
    
    private func setupHotkeyHandler() {
        hotkeyService.onTrigger = { [weak self] in
            await self?.handleOptionKeyTrigger()
        }
    }
    
    /// Start monitoring for Option key presses
    func startMonitoring() {
        guard !isMonitoring else { return }
        hotkeyService.startMonitoring()
        isMonitoring = true
        lastError = nil
        print("🎯 OvershootCoordinator: Monitoring started")
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        hotkeyService.stopMonitoring()
        isMonitoring = false
        print("🎯 OvershootCoordinator: Monitoring stopped")
    }
    
    /// Handle Option key trigger
    private func handleOptionKeyTrigger() async {
        await MainActor.run {
            self.isProcessing = true
            self.lastResult = nil
            self.lastError = nil
        }
        
        print("📸 OvershootCoordinator: Capturing screenshot...")
        
        do {
            // Capture the screenshot
            let base64Image = try await screenshotService.captureScreenAsBase64()
            print("📸 Screenshot captured, size: \(base64Image.count / 1024) KB")
            
            // Send to backend for analysis
            print("🌐 Sending to backend for Overshoot analysis...")
            let result = try await backendService.analyzeScreenshot(
                imageBase64: base64Image,
                prompt: """
                Analyze this screenshot of a student's study material. 
                Identify any text, equations, diagrams, or educational content.
                If you see math or science problems, explain the concepts.
                If you see code, explain what it does.
                Be helpful and educational in your response.
                """
            )
            
            await MainActor.run {
                self.isProcessing = false
                if result.success {
                    self.lastResult = result.result ?? "Analysis complete"
                    print("✅ Analysis result: \(result.result ?? "N/A")")
                } else {
                    self.lastError = result.error ?? "Unknown error"
                    print("❌ Analysis error: \(result.error ?? "N/A")")
                }
            }
            
        } catch {
            let errorMessage = error.localizedDescription
            await MainActor.run {
                self.isProcessing = false
                // Check if it's a permission error
                if errorMessage.contains("declined") || errorMessage.contains("TCC") {
                    self.lastError = "Screen recording permission required.\n\n1. Go to System Settings > Privacy & Security > Screen Recording\n2. Enable 'ock'\n3. QUIT and REOPEN the app"
                } else {
                    self.lastError = errorMessage
                }
            }
            print("❌ OvershootCoordinator error: \(errorMessage)")
        }
    }
    
    /// Manually trigger a screenshot analysis (for testing)
    func triggerAnalysis() async {
        await handleOptionKeyTrigger()
    }
}
