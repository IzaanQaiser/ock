//
//  WhisperFlowCapture.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import AppKit
import Combine

class WhisperFlowCapture: ObservableObject {
    static let shared = WhisperFlowCapture()
    
    @Published var capturedText: String = ""
    @Published var isMonitoring: Bool = false
    
    private var clipboardTimer: Timer?
    private var lastClipboardContent: String = ""
    private var onTextCaptured: ((String) -> Void)?
    private var lastCaptureTime: Date?
    private var monitoringStartTime: Date?
    private let minCaptureInterval: TimeInterval = 0.5 // Minimum time between captures
    private let ignoreExistingClipboardDelay: TimeInterval = 1.0 // Ignore clipboard content that exists when monitoring starts
    
    private init() {
        // No notification available for clipboard changes on macOS, so we use polling
    }
    
    /// Start monitoring for WhisperFlow transcriptions
    /// - Parameter onCaptured: Callback when text is captured
    func startMonitoring(onCaptured: @escaping (String) -> Void) {
        self.onTextCaptured = onCaptured
        isMonitoring = true
        lastClipboardContent = getClipboardText()
        lastCaptureTime = nil
        monitoringStartTime = Date() // Record when monitoring started
        
        // Poll clipboard periodically to catch WhisperFlow transcriptions
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        isMonitoring = false
        clipboardTimer?.invalidate()
        clipboardTimer = nil
        onTextCaptured = nil
        lastCaptureTime = nil
        monitoringStartTime = nil
        lastClipboardContent = "" // Reset to prevent stale content
    }
    
    private func checkClipboard() {
        guard isMonitoring else { return }
        
        // Ignore clipboard content that existed when monitoring started
        // This prevents pasting existing clipboard content when opening a project
        if let startTime = monitoringStartTime,
           Date().timeIntervalSince(startTime) < ignoreExistingClipboardDelay {
            // Update lastClipboardContent to current to ignore it
            lastClipboardContent = getClipboardText()
            return
        }
        
        // Prevent too frequent captures
        if let lastTime = lastCaptureTime,
           Date().timeIntervalSince(lastTime) < minCaptureInterval {
            return
        }
        
        let currentClipboard = getClipboardText()
        
        // Check if clipboard has new text that looks like a transcription
        if currentClipboard != lastClipboardContent,
           !currentClipboard.isEmpty,
           currentClipboard.count > 3, // Minimum reasonable transcription length
           isValidTranscription(currentClipboard) {
            
            // This might be a WhisperFlow transcription
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.capturedText = currentClipboard
                self.onTextCaptured?(currentClipboard)
                self.lastClipboardContent = currentClipboard
                self.lastCaptureTime = Date()
            }
        }
    }
    
    /// Validate if clipboard content looks like a transcription
    private func isValidTranscription(_ text: String) -> Bool {
        // Filter out common non-transcription clipboard content
        if text.contains("http://") || text.contains("https://") {
            return false
        }
        if text.hasPrefix("file://") {
            return false
        }
        if text.contains("@") && text.contains(".com") {
            return false // Likely an email
        }
        if text.count > 1000 {
            return false // Probably too long for a single transcription
        }
        // Check if it looks like natural speech (has spaces, reasonable word length)
        let words = text.components(separatedBy: .whitespaces)
        if words.count < 2 {
            return false // Too short
        }
        // Average word length should be reasonable (3-15 characters)
        let avgWordLength = words.reduce(0) { $0 + $1.count } / words.count
        if avgWordLength < 2 || avgWordLength > 20 {
            return false
        }
        return true
    }
    
    private func getClipboardText() -> String {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string) else {
            return ""
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    deinit {
        clipboardTimer?.invalidate()
    }
}
