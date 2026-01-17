//
//  ChatPanel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ChatPanel: View {
    let messages: [ChatMessage]
    @Binding var inputValue: String
    let isListening: Bool
    let isTyping: Bool
    let isSharing: Bool
    let onToggleListening: () -> Void
    let onSendMessage: () -> Void
    let onReferenceClick: ((String) -> Void)?
    
    @FocusState private var isInputFocused: Bool
    
    init(
        messages: [ChatMessage],
        inputValue: Binding<String>,
        isListening: Bool,
        isTyping: Bool,
        isSharing: Bool,
        onToggleListening: @escaping () -> Void,
        onSendMessage: @escaping () -> Void,
        onReferenceClick: ((String) -> Void)? = nil
    ) {
        self.messages = messages
        self._inputValue = inputValue
        self.isListening = isListening
        self.isTyping = isTyping
        self.isSharing = isSharing
        self.onToggleListening = onToggleListening
        self.onSendMessage = onSendMessage
        self.onReferenceClick = onReferenceClick
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                Text("Conversation")
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.appBorder),
                alignment: .bottom
            )
            
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if messages.isEmpty && !isSharing {
                            Spacer()
                            Text("Start sharing your screen to begin your session with ock")
                                .font(.body)
                                .foregroundColor(.appMutedForeground)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                onReferenceClick: onReferenceClick
                            )
                                .id(message.id)
                        }
                        
                        if isTyping {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.appSecondary)
                                    )
                                Spacer()
                            }
                        }
                        
                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: isTyping) { _ in
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 8) {
                // Mic button
                Button(action: onToggleListening) {
                    Image(systemName: isListening ? "mic.slash" : "mic")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isListening ? Color.red : Color.appSecondary)
                        )
                }
                .buttonStyle(.plain)
                
                // Text input
                TextField(
                    isListening ? "Listening..." : "Type or speak your question...",
                    text: $inputValue
                )
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(.appForeground)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appSecondary)
                )
                .focused($isInputFocused)
                .onSubmit {
                    if !inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSendMessage()
                    }
                }
                
                // Send button
                Button(action: onSendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.appBorder),
                alignment: .top
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let onReferenceClick: ((String) -> Void)?
    
    @State private var hoveredReference: String? = nil
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 0) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .black : .appForeground)
                    .padding(12)
                    .frame(maxWidth: 400, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? Color.white : Color.appSecondary)
                    )
                
                if let references = message.references, !references.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(references, id: \.self) { reference in
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appMutedForeground)
                                Text("Referenced: ")
                                    .font(.caption2)
                                    .foregroundColor(.appMutedForeground)
                                Button(action: {
                                    onReferenceClick?(reference)
                                }) {
                                    Text(reference)
                                        .font(.caption2)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(hoveredReference == reference ? .appForeground : .appMutedForeground)
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        hoveredReference = hovering ? reference : nil
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.leading, 12)
                }
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatPanel(
        messages: [
            ChatMessage(role: .assistant, content: "Hey! I can see your screen now."),
            ChatMessage(role: .user, content: "Can you help me understand this concept?")
        ],
        inputValue: .constant(""),
        isListening: false,
        isTyping: false,
        isSharing: true,
        onToggleListening: {},
        onSendMessage: {},
        onReferenceClick: nil
    )
    .frame(width: 640, height: 600)
}
