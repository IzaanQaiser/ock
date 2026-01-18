//
//  SessionViewModel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine
import AppKit

class SessionViewModel: ObservableObject {
    @Published var isListening: Bool = false
    @Published var isSharing: Bool = false
    @Published var hasScreenSharePermission: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var inputValue: String = ""
    @Published var isTyping: Bool = false
    @Published var activeReferences: [String] = []
    @Published var previewedFileName: String? = nil
    @Published var isMonitoringWhisperFlow: Bool = false
    @Published var shouldFocusInput: Bool = false
    @Published var shouldAutoSend: Bool = false
    @Published var shouldShowOverlay: Bool = false
    @Published var currentPlayingMessageId: String? = nil // Track which message is playing TTS
    
    private var typingTask: DispatchWorkItem?
    private var autoSendTask: DispatchWorkItem?
    private var fnReleaseDelayTask: DispatchWorkItem?
    private var typingTimer: Timer?
    private var isCurrentlyTyping = false
    private var lastInputValue = ""
    private let whisperFlowCapture = WhisperFlowCapture.shared
    private let fnKeyMonitor = FnKeyMonitor.shared
    private let elevenLabsService = ElevenLabsService.shared
    private let geminiService = GeminiService.shared
    private let screenshotCapture = ScreenshotCapture.shared
    private let materialsContextService = MaterialsContextService.shared
    private var inputValueObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkScreenSharePermission()
        setupWhisperFlowCapture()
        setupInputValueMonitoring()
        setupFnKeyMonitoring()
        setupTTSMonitoring()
    }
    
    private func setupTTSMonitoring() {
        // Sync the service's playback state to the view model
        elevenLabsService.$currentPlayingMessageId
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentPlayingMessageId)
        
        // Also sync isPlaying state if needed
        elevenLabsService.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                // Can use this for UI indicators if needed
                print("🔊 TTS isPlaying: \(isPlaying)")
            }
            .store(in: &cancellables)
    }
    
    private func setupFnKeyMonitoring() {
        // Set up Fn key monitoring for WhisperFlow
        fnKeyMonitor.startMonitoring(
            onPress: { [weak self] in
                // Fn key pressed - focus text field and minimize app
                self?.handleFnKeyPress()
            },
            onRelease: { [weak self] in
                // Fn key released - send message
                self?.handleFnKeyRelease()
            }
        )
    }
    
    private func handleFnKeyPress() {
        print("📱 SessionViewModel: handleFnKeyPress called")
        print("   - isSharing: \(isSharing)")
        print("   - isMonitoringWhisperFlow: \(isMonitoringWhisperFlow)")
        
        // Only activate if we're in a session and sharing
        guard isSharing else {
            print("   ⚠️ Not sharing, ignoring Fn press")
            return
        }
        
        print("   ✅ Processing Fn press...")
        
        // Start monitoring WhisperFlow
        if !isMonitoringWhisperFlow {
            print("   🎤 Starting WhisperFlow monitoring...")
            startWhisperFlowMonitoring()
        }
        
        // Focus the text input field
        print("   👆 Focusing text input...")
        shouldFocusInput = true
        
        // Don't minimize the app - keep it visible
        
        // Update listening state
        isListening = true
        print("   ✅ Fn press handled successfully")
    }
    
    private func handleFnKeyRelease() {
        print("📱 SessionViewModel: handleFnKeyRelease called")
        print("   - isMonitoringWhisperFlow: \(isMonitoringWhisperFlow)")
        print("   - inputValue: '\(inputValue)'")
        
        // Only process if we were monitoring
        guard isMonitoringWhisperFlow else {
            print("   ⚠️ Not monitoring WhisperFlow, ignoring Fn release")
            return
        }
        
        print("   ✅ Processing Fn release...")
        
        // Cancel any existing delay task
        fnReleaseDelayTask?.cancel()
        
        // WhisperFlow takes a few seconds to finish transcribing
        // Wait 2.5 seconds after Fn release before sending to allow transcription to complete
        print("   ⏳ Scheduling send after 2.5 second delay...")
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else {
                print("   ⚠️ Self is nil in delay task")
                return
            }
            
            print("   ⏰ Delay task executing...")
            print("     - isMonitoringWhisperFlow: \(self.isMonitoringWhisperFlow)")
            print("     - inputValue: '\(self.inputValue)'")
            
            // Only send if we're still monitoring (user hasn't cancelled)
            guard self.isMonitoringWhisperFlow else {
                print("     ⚠️ No longer monitoring, cancelling send")
                return
            }
            
            // Send the message if there's text
            if !self.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("     ✅ Triggering auto-send...")
                // Trigger send via published property
                self.shouldAutoSend = true
            } else {
                print("     ⚠️ No text found, stopping monitoring")
                // No text after delay, just stop monitoring
                self.stopWhisperFlowMonitoring()
                self.isListening = false
            }
        }
        
        fnReleaseDelayTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
        print("   ✅ Fn release handled, delay scheduled")
    }
    
    private func setupWhisperFlowCapture() {
        // When text is captured from WhisperFlow, populate input
        whisperFlowCapture.$capturedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                // Only capture if we're monitoring
                if self.isMonitoringWhisperFlow {
                    // Only populate if input is empty or very short (user hasn't typed much)
                    if self.inputValue.isEmpty || self.inputValue.count < 3 {
                        self.inputValue = text
                    } else {
                        // Append if user has typed something (maybe they're editing)
                        // Or replace if it's clearly a new transcription
                        self.inputValue = text
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupInputValueMonitoring() {
        // Monitor inputValue changes to detect WhisperFlow typing
        // Since WhisperFlow intercepts Fn key, we detect when it starts/stops typing instead
        lastInputValue = inputValue
        
        inputValueObserver = $inputValue
            .sink { [weak self] newValue in
                guard let self = self else { return }
                
                // Detect when text starts appearing (Fn pressed, WhisperFlow started)
                if !self.isCurrentlyTyping && !newValue.isEmpty && newValue != self.lastInputValue {
                    print("📝 SessionViewModel: Text started appearing (WhisperFlow started typing)")
                    print("   - New text: '\(newValue)'")
                    
                    // This indicates Fn was pressed and WhisperFlow started
                    // Always start monitoring when text appears, regardless of sharing state
                    if !self.isMonitoringWhisperFlow {
                        print("   ✅ Starting WhisperFlow monitoring...")
                        self.startWhisperFlowMonitoring()
                        self.isListening = true
                        
                        // Show overlay window
                        // The overlay will have the focused text field that WhisperFlow can type into
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("   📱 Showing WhisperFlow overlay window...")
                            // Show overlay - it will be managed by the view layer
                            // We'll trigger it via a published property
                            self.shouldShowOverlay = true
                            // Don't minimize the app - keep it visible
                        }
                    }
                    
                    self.isCurrentlyTyping = true
                }
                
                // Always reset typing timer whenever text changes (even if not currently typing)
                // This ensures we catch when typing stops
                self.typingTimer?.invalidate()
                
                // Use a short delay (0.5 seconds) to detect when typing stops immediately
                self.typingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Text stopped changing for 0.5 seconds - WhisperFlow finished typing
                    if self.isCurrentlyTyping {
                        print("📝 SessionViewModel: Text stopped changing (WhisperFlow finished typing)")
                        print("   - Final text: '\(self.inputValue)'")
                        print("   - isMonitoringWhisperFlow: \(self.isMonitoringWhisperFlow)")
                        
                        // Send message immediately if there's text
                        if !self.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("   ✅ Auto-sending message immediately...")
                            // Trigger send via published property - the view will handle it
                            self.shouldAutoSend = true
                            // Keep mic on and overlay open for next message (don't close it)
                            // User can ask multiple questions
                        } else {
                            print("   ⚠️ No text to send")
                            // Keep mic on even if no text - user might try again
                            // Don't stop monitoring or turn off mic
                        }
                        
                        self.isCurrentlyTyping = false
                    }
                }
                
                self.lastInputValue = newValue
            }
    }
    
    /// Schedule auto-send after text stabilizes
    func scheduleAutoSend(materials: [UploadedMaterial]) {
        // Cancel any existing auto-send task
        autoSendTask?.cancel()
        
        // Schedule auto-send after 1.5 seconds of no changes
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Only auto-send if still monitoring and text hasn't changed
            if self.isMonitoringWhisperFlow && !self.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.sendMessage(materials: materials)
                // Stop monitoring after sending
                self.stopWhisperFlowMonitoring()
                self.isListening = false
            }
        }
        autoSendTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: task)
    }
    
    /// Cancel pending auto-send
    func cancelAutoSend() {
        autoSendTask?.cancel()
        autoSendTask = nil
    }
    
    
    func checkScreenSharePermission() {
        // On macOS, we check screen recording permission by trying to create a screen capture
        // The system will show permission dialog automatically if needed
        // For UI purposes, we'll assume permission is needed until user grants it
        // In a real implementation, you'd check this via ScreenCaptureKit or similar
        // For now, we'll start with false and update when sharing is toggled
        hasScreenSharePermission = false
    }
    
    func requestScreenSharePermission() {
        // Opening System Settings to screen recording permission
        // The actual permission request happens when screen capture is attempted
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func toggleScreenShare() {
        // When user clicks share, the system will prompt for permission if needed
        // We'll toggle the state - actual screen capture implementation would go here
        isSharing.toggle()
        
        // Update permission state (in real app, check actual permission status)
        if isSharing {
            hasScreenSharePermission = true
            // Show overlay when screen sharing starts so WhisperFlow is ready
            print("📺 toggleScreenShare: Screen sharing started, showing overlay...")
            shouldShowOverlay = true
        } else {
            // Hide overlay when screen sharing stops
            shouldShowOverlay = false
        }
        
        if isSharing && messages.isEmpty {
            // Initial greeting after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let greeting = ChatMessage(
                    role: .assistant,
                    content: "Hey! I can see your screen now. What are you working on? Point me to anything you're confused about."
                )
                self.messages.append(greeting)
            }
        }
    }
    
            func toggleListening() {
                isListening.toggle()

                if isListening {
                    // Start monitoring WhisperFlow clipboard
                    startWhisperFlowMonitoring()

                    // Show overlay window immediately so WhisperFlow has a text field to type into
                    print("🎤 toggleListening: Showing overlay for WhisperFlow...")
                    shouldShowOverlay = true
                    // Don't minimize the app - keep it visible
                } else {
                    // Stop monitoring and close overlay
                    stopWhisperFlowMonitoring()
                    shouldShowOverlay = false
                }
            }
    
    
    /// Start monitoring WhisperFlow for transcriptions
    func startWhisperFlowMonitoring() {
        isMonitoringWhisperFlow = true
        whisperFlowCapture.startMonitoring { [weak self] text in
            DispatchQueue.main.async {
                self?.inputValue = text
            }
        }
    }
    
    /// Stop monitoring WhisperFlow
    func stopWhisperFlowMonitoring() {
        isMonitoringWhisperFlow = false
        whisperFlowCapture.stopMonitoring()
    }
    
    /// Adds a reference to a message and opens the preview if needed
    /// - Parameter fileNames: Array of file names to reference
    func addReferences(_ fileNames: [String]) {
        guard !fileNames.isEmpty else { return }
        
        activeReferences = fileNames
        
        // Auto-open preview for the first reference
        if let firstRef = fileNames.first {
            previewedFileName = firstRef
        }
    }
    
    /// Adds an assistant message with optional references
    /// - Parameters:
    ///   - content: The message content
    ///   - references: Optional array of file names to reference
    func addAssistantMessage(content: String, references: [String]? = nil) {
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: content,
            references: references
        )
        
        messages.append(assistantMessage)
        
        // If references are provided, add them
        if let refs = references, !refs.isEmpty {
            addReferences(refs)
        }
        
        // Automatically play TTS for assistant messages
        Task { [weak self] in
            guard let self = self else { return }
            do {
                print("🔊 SessionViewModel: Starting TTS for assistant message")
                print("   - Message ID: \(assistantMessage.id)")
                print("   - Content length: \(content.count) characters")
                print("   - Content preview: \(content.prefix(100))...")
                
                try await self.elevenLabsService.speak(text: content, messageId: assistantMessage.id)
                
                print("✅ SessionViewModel: TTS playback started successfully")
            } catch {
                print("⚠️ SessionViewModel: Failed to play TTS")
                print("   - Error: \(error.localizedDescription)")
                if let elevenLabsError = error as? ElevenLabsError {
                    print("   - Error type: \(elevenLabsError)")
                }
            }
        }
    }
    
    func sendMessage(materials: [UploadedMaterial]) {
        debugLog("📤 sendMessage called with \(materials.count) materials")
        guard !inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Cancel any pending auto-send
        cancelAutoSend()
        
        let userMessage = ChatMessage(
            role: .user,
            content: inputValue
        )
        
                let userQuestion = inputValue // Save the question before clearing
                messages.append(userMessage)
                inputValue = "" // Clear input for next message
                isTyping = true

                // Keep mic on and overlay open for next message
                // Don't turn off listening - user can ask multiple questions
                if shouldShowOverlay {
                    print("📤 sendMessage: Keeping overlay open and mic on for next message")
                    // Refocus overlay after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Ensure overlay is still shown and focused
                        if self.shouldShowOverlay {
                            WhisperFlowOverlayWindowManager.shared.refocusOverlay()
                        }
                    }
                }
                // Keep isListening = true so user can ask more questions
        
        // Cancel any existing typing task
        typingTask?.cancel()
        
        // Capture screenshot and call Gemini
        Task { [weak self] in
            guard let self = self else { return }
            
            print("📸 sendMessage: Capturing screenshot...")
            
            // Capture screenshot (async)
            let screenshotBase64 = await self.screenshotCapture.captureScreenAsBase64(compressionQuality: 0.7)
            
            if screenshotBase64 != nil {
                print("✅ sendMessage: Screenshot captured successfully")
            } else {
                print("⚠️ sendMessage: Failed to capture screenshot, continuing without it")
            }
            
            // Call Gemini with text and screenshot
            await self.callGemini(text: userQuestion, imageBase64: screenshotBase64, materials: materials)
        }
    }
    
    private func callGemini(text: String, imageBase64: String?, materials: [UploadedMaterial]) async {
        do {
            print("🔮 SessionViewModel: Calling Gemini API...")
            let startTime = Date()
            
            // Compress user's transcription/question
            var compressedQuestion = text
            if text.count > 50 { // Only compress if long enough
                do {
                    debugLog("🎤 SessionViewModel: Compressing user transcription...")
                    debugLog("   - Original: \(text.count) chars")
                    compressedQuestion = try await TokenCompanyService.shared.compressTranscription(text)
                    debugLog("   - Compressed: \(compressedQuestion.count) chars")
                } catch {
                    debugLog("⚠️ SessionViewModel: Transcription compression failed, using original")
                    compressedQuestion = text
                }
            }
            
            // Get relevant course context from materials
            debugLog("📚 SessionViewModel: Checking materials for context...")
            debugLog("   - Number of materials: \(materials.count)")
            for (i, mat) in materials.enumerated() {
                debugLog("   - Material \(i+1): \(mat.name)")
                debugLog("     - Has extracted text: \(mat.extractedText != nil)")
                debugLog("     - Text length: \(mat.extractedText?.count ?? 0) chars")
                debugLog("     - Chunks: \(mat.textChunks?.count ?? 0)")
            }
            
            let courseContext = materialsContextService.getRelevantContext(for: compressedQuestion, from: materials)
            debugLog("📚 SessionViewModel: Context retrieval result: \(courseContext.count) chars")
            
            if !courseContext.isEmpty {
                debugLog("📚 ---- RAW CONTEXT START ----")
                debugLog(String(courseContext.prefix(1000))) // First 1000 chars to avoid flooding
                if courseContext.count > 1000 {
                    debugLog("... [\(courseContext.count - 1000) more chars]")
                }
                debugLog("📚 ---- RAW CONTEXT END ----")
            } else {
                debugLog("⚠️ SessionViewModel: No relevant context found from materials!")
            }
            
            let response = try await geminiService.generateContent(
                text: compressedQuestion,
                imageBase64: imageBase64,
                courseContext: courseContext.isEmpty ? nil : courseContext
            )
            
            let apiTime = Date().timeIntervalSince(startTime)
            print("⏱️ SessionViewModel: Gemini API call took \(String(format: "%.2f", apiTime)) seconds")
            
            await MainActor.run {
                print("✅ SessionViewModel: Received response from Gemini")
                
                // Check if any materials were referenced (simple keyword matching for now)
                let refs = materials.filter { material in
                    response.localizedCaseInsensitiveContains(material.name) ||
                    material.name.localizedCaseInsensitiveContains(response)
                }.map { $0.name }
                
                // Add assistant message with response
                let assistantMessage = ChatMessage(
                    role: .assistant,
                    content: response,
                    references: refs.isEmpty ? nil : refs
                )
                
                messages.append(assistantMessage)
                
                // If references are provided, add them
                if !refs.isEmpty {
                    addReferences(refs)
                }
                
                // Start TTS immediately (don't wait)
                Task { [weak self] in
                    guard let self = self else { return }
                    let ttsStartTime = Date()
                    do {
                        print("🔊 SessionViewModel: Starting TTS immediately after response")
                        try await self.elevenLabsService.speak(text: response, messageId: assistantMessage.id)
                        let ttsTime = Date().timeIntervalSince(ttsStartTime)
                        print("⏱️ SessionViewModel: TTS took \(String(format: "%.2f", ttsTime)) seconds")
                        await MainActor.run {
                            self.currentPlayingMessageId = assistantMessage.id
                        }
                    } catch {
                        print("⚠️ SessionViewModel: Failed to play TTS: \(error.localizedDescription)")
                    }
                }
                
                self.isTyping = false
            }
        } catch {
            await MainActor.run {
                print("❌ SessionViewModel: Gemini API call failed: \(error.localizedDescription)")
                
                // Add assistant message with error
                self.addAssistantMessage(
                    content: "Sorry, I encountered an error: \(error.localizedDescription)",
                    references: nil
                )
                
                self.isTyping = false
            }
        }
    }
    
    func openPreview(fileName: String) {
        previewedFileName = fileName
    }
    
    func closePreview() {
        previewedFileName = nil
    }
    
    func clearSession() {
        isListening = false
        isSharing = false
        messages = []
        inputValue = ""
        isTyping = false
        activeReferences = []
        previewedFileName = nil
        isMonitoringWhisperFlow = false
        shouldAutoSend = false
        currentPlayingMessageId = nil
        stopWhisperFlowMonitoring()
        elevenLabsService.stop() // Stop any playing TTS
        typingTask?.cancel()
        autoSendTask?.cancel()
        fnReleaseDelayTask?.cancel()
        typingTimer?.invalidate()
    }
    
    deinit {
        inputValueObserver?.cancel()
        autoSendTask?.cancel()
        fnReleaseDelayTask?.cancel()
        typingTimer?.invalidate()
        cancellables.removeAll()
        fnKeyMonitor.stopMonitoring()
        elevenLabsService.stop() // Stop TTS on deinit
    }
}
