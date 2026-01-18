//
//  WhisperFlowOverlay.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI
import AppKit
import Combine

struct WhisperFlowOverlay: View {
    @Binding var inputValue: String
    let onSendMessage: () -> Void
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        // Minimal 1x1 pixel view with hidden text field
        TextField("", text: $inputValue)
            .textFieldStyle(.plain)
            .font(.system(size: 1))
            .foregroundColor(.clear)
            .frame(width: 1, height: 1)
            .focused($isInputFocused)
            .onAppear {
                // Auto-focus when overlay appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
    }
}

// Observable object to sync text between overlay and main app
class WhisperFlowOverlayState: ObservableObject {
    @Published var inputValue: String = ""
    var onSendMessage: (() -> Void)?
    var onValueChanged: ((String) -> Void)?
    
    func updateValue(_ newValue: String) {
        inputValue = newValue
        onValueChanged?(newValue)
    }
}

// Custom window class that can become key
class WhisperFlowOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// Window manager for the overlay
class WhisperFlowOverlayWindowManager {
    static let shared = WhisperFlowOverlayWindowManager()
    
    private var overlayWindow: NSWindow?
    private var hostingView: NSHostingView<WhisperFlowOverlay>?
    private var overlayState = WhisperFlowOverlayState()
    private var syncTimer: Timer?
    
    private init() {}
    
    func showOverlay(inputValue: Binding<String>, onSendMessage: @escaping () -> Void) {
        print("🪟 WhisperFlowOverlayWindowManager: showOverlay called")
        // Close existing overlay if any
        closeOverlay()
        
        // Set up state with bidirectional sync
        overlayState.onSendMessage = onSendMessage
        overlayState.inputValue = inputValue.wrappedValue
        
        print("   - Initial inputValue: '\(inputValue.wrappedValue)'")
        
        // Sync changes from overlay back to binding
        overlayState.onValueChanged = { newValue in
            print("   - Overlay value changed to: '\(newValue)'")
            inputValue.wrappedValue = newValue
        }
        
        // Create overlay with state binding
        let contentView = WhisperFlowOverlay(
            inputValue: Binding(
                get: { self.overlayState.inputValue },
                set: { self.overlayState.updateValue($0) }
            ),
            onSendMessage: {
                self.overlayState.onSendMessage?()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        self.hostingView = hostingView
        
        let window = WhisperFlowOverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.backgroundColor = .clear // Transparent background
        window.isOpaque = false
        window.level = .screenSaver // Higher level to ensure it's always visible
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true // Don't intercept mouse events
        window.hasShadow = false // No shadow for invisible window
        window.isMovableByWindowBackground = false
        window.hidesOnDeactivate = false // Don't hide when app loses focus
        window.alphaValue = 0.0 // Completely transparent
        window.isReleasedWhenClosed = false // Don't release when closed
        
        // Position window at top-left corner of screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.minX
            let y = screenRect.maxY - 1 // Top of screen, 1 pixel down
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.overlayWindow = window
        
        // Make sure window is visible
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Force window to front
        window.orderFrontRegardless()
        
        print("   ✅ Overlay window created and shown")
        print("   - Window frame: \(window.frame)")
        print("   - Window level: \(window.level.rawValue)")
        print("   - Window is visible: \(window.isVisible)")
        print("   - Window is on screen: \(window.isOnActiveSpace)")
        print("   - Window alpha: \(window.alphaValue)")
        
        // Focus the text field immediately and repeatedly to ensure it gets focus
        DispatchQueue.main.async {
            print("   👆 Attempting to focus text field immediately...")
            window.makeKey()
            window.orderFrontRegardless()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("   👆 Second attempt to focus...")
            window.makeKey()
            window.makeFirstResponder(hostingView)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("   👆 Third attempt to focus...")
            window.makeKey()
            window.orderFrontRegardless()
            
            // Try to find and focus the text field directly
            if let textField = self.findTextField(in: hostingView) {
                print("   ✅ Found text field, focusing...")
                window.makeFirstResponder(textField)
            }
            
            // Double-check visibility
            if !window.isVisible {
                print("   ⚠️ Window not visible, forcing front...")
                window.orderFrontRegardless()
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        // Sync binding changes to overlay state (from main app to overlay)
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.overlayWindow?.isVisible == true else {
                timer.invalidate()
                return
            }
            // Sync from binding to overlay
            if self.overlayState.inputValue != inputValue.wrappedValue {
                self.overlayState.inputValue = inputValue.wrappedValue
            }
        }
    }
    
    func closeOverlay() {
        syncTimer?.invalidate()
        syncTimer = nil
        overlayState.onValueChanged = nil
        overlayState.onSendMessage = nil
        overlayWindow?.close()
        overlayWindow = nil
        hostingView = nil
    }
    
    func isOverlayVisible() -> Bool {
        return overlayWindow != nil && overlayWindow?.isVisible == true
    }
    
    /// Refocus the overlay text field for the next message
    func refocusOverlay() {
        guard let window = overlayWindow, let hostingView = hostingView else {
            print("   ⚠️ Cannot refocus: overlay not visible")
            return
        }
        
        print("   🔄 Refocusing overlay for next message...")
        
        // Clear the text in overlay state
        overlayState.inputValue = ""
        
        // Focus the window and text field
        DispatchQueue.main.async {
            window.makeKey()
            window.orderFrontRegardless()
            
            // Try to find and focus the text field
            if let textField = self.findTextField(in: hostingView) {
                window.makeFirstResponder(textField)
                print("   ✅ Text field refocused")
            } else {
                // Fallback: focus the hosting view
                window.makeFirstResponder(hostingView)
            }
        }
    }
    
    // Helper to find text field in the view hierarchy
    private func findTextField(in view: NSView) -> NSTextField? {
        if let textField = view as? NSTextField {
            return textField
        }
        for subview in view.subviews {
            if let textField = findTextField(in: subview) {
                return textField
            }
        }
        return nil
    }
}
