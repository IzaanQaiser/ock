//
//  FnKeyMonitor.swift
//  Ock-Cursor
//
//  Created on 2024
//

import AppKit
import ApplicationServices
import Combine

class FnKeyMonitor: ObservableObject {
    static let shared = FnKeyMonitor()
    
    @Published var isFnKeyPressed: Bool = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onFnPress: (() -> Void)?
    private var onFnRelease: (() -> Void)?
    private var wasFnPressed: Bool = false
    
    private init() {}
    
    /// Start monitoring Fn key events
    /// - Parameters:
    ///   - onPress: Callback when Fn key is pressed
    ///   - onRelease: Callback when Fn key is released
    func startMonitoring(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) {
        print("🚀 FnKeyMonitor: Starting monitoring...")
        stopMonitoring() // Ensure no duplicate monitors
        
        self.onFnPress = onPress
        self.onFnRelease = onRelease
        
        // Request accessibility permissions if needed
        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            print("⚠️ FnKeyMonitor: Accessibility permissions required for Fn key monitoring. Please grant permissions in System Settings.")
        } else {
            print("✅ FnKeyMonitor: Accessibility permissions granted")
        }
        
        // Monitor Fn key state globally (works even when app is not frontmost)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            print("🌐 FnKeyMonitor: Global event detected")
            self?.handleFlagsChanged(event: event)
        }
        
        // Also monitor local events (when app is active)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            print("🏠 FnKeyMonitor: Local event detected")
            self?.handleFlagsChanged(event: event)
            return event
        }
        
        print("✅ FnKeyMonitor: Monitoring started (global: \(globalMonitor != nil), local: \(localMonitor != nil))")
    }
    
    /// Stop monitoring Fn key events
    func stopMonitoring() {
        print("🛑 FnKeyMonitor: Stopping monitoring...")
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        
        onFnPress = nil
        onFnRelease = nil
        isFnKeyPressed = false
        wasFnPressed = false
        print("✅ FnKeyMonitor: Monitoring stopped")
    }
    
    private func handleFlagsChanged(event: NSEvent) {
        // Fn key has keyCode 63 on most Mac keyboards
        // We detect it via flagsChanged events and check for .function modifier
        let keyCode = event.keyCode
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasFunctionModifier = flags.contains(.function)
        
        print("🔍 FnKeyMonitor: flagsChanged event detected")
        print("   - keyCode: \(keyCode)")
        print("   - flags: \(flags)")
        print("   - hasFunctionModifier: \(hasFunctionModifier)")
        print("   - wasFnPressed: \(wasFnPressed)")
        
        // Check if this is the Fn key (keyCode 63) or if function modifier is present
        // Note: Some keyboards may have different keyCodes, so we check both
        let isFnKey = (keyCode == 63) || (hasFunctionModifier && keyCode == 63)
        
        // Also check if function modifier flag changed (for keyboards where Fn doesn't have keyCode 63)
        // Try detecting Fn key more broadly - check for keyCode 63 or function modifier changes
        let currentFnState = hasFunctionModifier || (keyCode == 63)
        
        print("   - isFnKey: \(isFnKey)")
        print("   - currentFnState: \(currentFnState)")
        
        // Detect state change
        if currentFnState && !wasFnPressed {
            // Fn key was just pressed
            print("✅ FnKeyMonitor: Fn key PRESSED")
            wasFnPressed = true
            isFnKeyPressed = true
            DispatchQueue.main.async { [weak self] in
                print("✅ FnKeyMonitor: Calling onFnPress callback")
                self?.onFnPress?()
            }
        } else if !currentFnState && wasFnPressed {
            // Fn key was just released
            print("✅ FnKeyMonitor: Fn key RELEASED")
            wasFnPressed = false
            isFnKeyPressed = false
            DispatchQueue.main.async { [weak self] in
                print("✅ FnKeyMonitor: Calling onFnRelease callback")
                self?.onFnRelease?()
            }
        } else {
            print("   - No state change detected")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
