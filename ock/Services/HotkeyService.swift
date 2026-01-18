//
//  HotkeyService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import AppKit
import Combine

/// Service to monitor global hotkeys (Option key hold)
class HotkeyService: ObservableObject {
    static let shared = HotkeyService()
    
    @Published var isOptionKeyHeld: Bool = false
    @Published var lastTriggerTime: Date? = nil
    
    private var flagsMonitor: Any?
    private var isProcessing = false
    
    /// Callback when Option key is pressed and screenshot should be triggered
    var onTrigger: (() async -> Void)?
    
    private init() {}
    
    /// Start monitoring for Option key
    func startMonitoring() {
        guard flagsMonitor == nil else { return }
        
        print("🎹 Starting hotkey monitoring...")
        
        // Monitor modifier key changes globally
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Also monitor locally (when app is focused)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        print("🎹 Hotkey monitoring started. Hold Option key to trigger screenshot.")
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
            print("🎹 Hotkey monitoring stopped")
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)
        
        // Only trigger on press, not release
        if optionPressed && !isOptionKeyHeld && !isProcessing {
            DispatchQueue.main.async {
                self.isOptionKeyHeld = true
                self.triggerScreenshot()
            }
        } else if !optionPressed && isOptionKeyHeld {
            DispatchQueue.main.async {
                self.isOptionKeyHeld = false
            }
        }
    }
    
    private func triggerScreenshot() {
        guard !isProcessing else { return }
        isProcessing = true
        lastTriggerTime = Date()
        
        print("📸 Option key detected! Triggering screenshot...")
        
        Task {
            await onTrigger?()
            
            // Add a longer cooldown to prevent rapid-fire triggers
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second cooldown
            
            await MainActor.run {
                self.isProcessing = false
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
