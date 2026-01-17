//
//  SessionViewModel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine

class SessionViewModel: ObservableObject {
    @Published var isListening: Bool = false
    @Published var isSharing: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var inputValue: String = ""
    @Published var isTyping: Bool = false
    @Published var activeReferences: [String] = []
    
    private var typingTask: DispatchWorkItem?
    
    func toggleScreenShare() {
        isSharing.toggle()
        
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
    
    func sendMessage(materials: [UploadedMaterial]) {
        guard !inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            role: .user,
            content: inputValue
        )
        
        messages.append(userMessage)
        let messageToSend = inputValue
        inputValue = ""
        isTyping = true
        
        // Cancel any existing typing task
        typingTask?.cancel()
        
        // Simulate AI response
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            let refs = materials.isEmpty ? [] : [materials.randomElement()?.name ?? "Course Notes"]
            self.activeReferences = refs
            
            let responses = [
                "I see what you're looking at. Let me break this down step by step...",
                "Great question! Based on your lecture notes, this concept relates to...",
                "Looking at that equation, here's what each part means...",
                "I can see you're stuck on that part. Let me explain it differently...",
            ]
            
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: responses.randomElement() ?? responses[0],
                references: refs
            )
            
            self.messages.append(assistantMessage)
            self.isTyping = false
        }
        
        typingTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: task)
    }
    
    func clearSession() {
        isListening = false
        isSharing = false
        messages = []
        inputValue = ""
        isTyping = false
        activeReferences = []
        typingTask?.cancel()
    }
}
