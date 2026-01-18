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
    let onToggleListening: () -> Void
    let onSendMessage: () -> Void
    let onReferenceClick: ((String) -> Void)?
    
    @FocusState private var isInputFocused: Bool
    @Binding var shouldFocusInput: Bool
    @Binding var currentPlayingMessageId: String?
    let onPlayTTS: (String, String) -> Void
    let onStopTTS: () -> Void
    @StateObject private var elevenLabsService = ElevenLabsService.shared
    
    init(
        messages: [ChatMessage],
        inputValue: Binding<String>,
        isListening: Bool,
        isTyping: Bool,
        onToggleListening: @escaping () -> Void,
        onSendMessage: @escaping () -> Void,
        onReferenceClick: ((String) -> Void)? = nil,
        shouldFocusInput: Binding<Bool> = .constant(false),
        currentPlayingMessageId: Binding<String?> = .constant(nil),
        onPlayTTS: @escaping (String, String) -> Void = { _, _ in },
        onStopTTS: @escaping () -> Void = {}
    ) {
        self.messages = messages
        self._inputValue = inputValue
        self.isListening = isListening
        self.isTyping = isTyping
        self.onToggleListening = onToggleListening
        self.onSendMessage = onSendMessage
        self.onReferenceClick = onReferenceClick
        self._shouldFocusInput = shouldFocusInput
        self._currentPlayingMessageId = currentPlayingMessageId
        self.onPlayTTS = onPlayTTS
        self.onStopTTS = onStopTTS
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
                        if messages.isEmpty && !isListening {
                            Spacer()
                            Text("Start a session to begin chatting with ock")
                                .font(.body)
                                .foregroundColor(.appMutedForeground)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                onReferenceClick: onReferenceClick,
                                isPlaying: elevenLabsService.isPlaying && elevenLabsService.currentPlayingMessageId == message.id,
                                onPlayPause: {
                                    if elevenLabsService.currentPlayingMessageId == message.id && elevenLabsService.isPlaying {
                                        elevenLabsService.pause()
                                    } else if elevenLabsService.currentPlayingMessageId == message.id {
                                        elevenLabsService.resume()
                                    } else {
                                        // Play this message
                                        Task {
                                            do {
                                                try await elevenLabsService.speak(text: message.content, messageId: message.id)
                                            } catch {
                                                print("⚠️ Failed to play TTS: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                },
                                onStop: {
                                    elevenLabsService.stop()
                                }
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
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: isTyping) {
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 8) {
                // Text input
                TextField(
                    isListening ? "Monitoring WhisperFlow... Use WhisperFlow app to talk" : "Type or speak your question...",
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
                .onChange(of: shouldFocusInput) { oldValue, newValue in
                    if newValue {
                        isInputFocused = true
                        // Reset the binding after focusing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shouldFocusInput = false
                        }
                    }
                }
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
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onStop: () -> Void
    
    @State private var hoveredReference: String? = nil
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.role == .user ? .black : .appForeground)
                        .frame(maxWidth: 400, alignment: .leading)
                    
                    // Audio controls for assistant messages
                    if message.role == .assistant {
                        HStack(spacing: 4) {
                            // Play/Pause button
                            Button(action: onPlayPause) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appMutedForeground)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .opacity(isHovering ? 1.0 : 0.6)
                            
                            // Stop button
                            Button(action: onStop) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appMutedForeground)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .opacity(isHovering ? 1.0 : 0.6)
                        }
                        .padding(.trailing, 4)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(message.role == .user ? Color.white : Color.appSecondary)
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                }
                
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
        onToggleListening: {},
        onSendMessage: {},
        onReferenceClick: nil,
        shouldFocusInput: .constant(false)
    )
    .frame(width: 640, height: 600)
    .environmentObject(ElevenLabsService.shared)
}
