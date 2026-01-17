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
    
    private var typingTask: DispatchWorkItem?
    
    init() {
        checkScreenSharePermission()
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
    }
    
    func sendMessage(materials: [UploadedMaterial]) {
        guard !inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            role: .user,
            content: inputValue
        )
        
        messages.append(userMessage)
        inputValue = ""
        isTyping = true
        
        // Cancel any existing typing task
        typingTask?.cancel()
        
        // Simulate AI response
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Dummy: randomly select a reference for demo purposes
            let refs = materials.isEmpty ? [] : [materials.randomElement()?.name ?? "Course Notes"]
            
            let responses = [
                "I see what you're looking at. Let me break this down step by step...",
                "Great question! Based on your lecture notes, this concept relates to...",
                "Looking at that equation, here's what each part means...",
                "I can see you're stuck on that part. Let me explain it differently...",
            ]
            
            // Use the new function to add message with references
            self.addAssistantMessage(
                content: responses.randomElement() ?? responses[0],
                references: refs.isEmpty ? nil : refs
            )
            
            self.isTyping = false
        }
        
        typingTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: task)
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
        typingTask?.cancel()
    }
}
