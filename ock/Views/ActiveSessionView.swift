//
//  ActiveSessionView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ActiveSessionView: View {
    @Binding var materials: [UploadedMaterial]
    @ObservedObject var sessionViewModel: SessionViewModel
    let onEndSession: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Resources panel (left side)
            ResourcesPanel(
                materials: materials,
                onAddMaterial: { urls in
                    // Materials can be added but won't affect active session immediately
                    // They'll be available after session ends
                },
                onRemoveMaterial: { _ in
                    // Can't remove materials during active session
                }
            )
            .disabled(true)
            .opacity(0.6)
            
            Divider()
            
            VStack(spacing: 0) {
                // Header
                SessionHeaderView(
                    isSharing: sessionViewModel.isSharing,
                    hasPermission: sessionViewModel.hasScreenSharePermission,
                    onToggleShare: {
                        sessionViewModel.toggleScreenShare()
                    },
                    onEndSession: onEndSession
                )
                
                // Main content - dynamic layout
                if let previewedFileName = sessionViewModel.previewedFileName,
                   let material = materials.first(where: { $0.name == previewedFileName }) {
                    // Split view: 60% PDF preview, 40% Chat
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // PDF preview panel (60%)
                            ReferencesPanel(
                                materials: materials,
                                activeReferences: sessionViewModel.activeReferences,
                                previewedFileName: sessionViewModel.previewedFileName,
                                onClose: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        sessionViewModel.closePreview()
                                    }
                                },
                                onClosePreview: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        sessionViewModel.closePreview()
                                    }
                                }
                            )
                            .frame(width: geometry.size.width * 0.6)
                            
                            Divider()
                            
                            // Chat panel (40%)
                            ChatPanel(
                                messages: sessionViewModel.messages,
                                inputValue: $sessionViewModel.inputValue,
                                isListening: sessionViewModel.isListening,
                                isTyping: sessionViewModel.isTyping,
                                isSharing: sessionViewModel.isSharing,
                                onToggleListening: {
                                    sessionViewModel.toggleListening()
                                },
                                onSendMessage: {
                                    sessionViewModel.sendMessage(materials: materials)
                                },
                                onReferenceClick: { fileName in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if sessionViewModel.previewedFileName == fileName {
                                            // If clicking the same file, close it
                                            sessionViewModel.closePreview()
                                        } else {
                                            // Open the preview
                                            sessionViewModel.openPreview(fileName: fileName)
                                        }
                                    }
                                },
                                shouldFocusInput: $sessionViewModel.shouldFocusInput
                            )
                            .onChange(of: sessionViewModel.inputValue) { newValue in
                                // Auto-send when text stabilizes during WhisperFlow monitoring
                                // But only if not triggered by Fn key release
                                if sessionViewModel.isMonitoringWhisperFlow && 
                                   !sessionViewModel.shouldAutoSend &&
                                   !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    // Cancel previous auto-send task
                                    sessionViewModel.cancelAutoSend()
                                    // Schedule new auto-send
                                    sessionViewModel.scheduleAutoSend(materials: materials)
                                }
                            }
                            .onChange(of: sessionViewModel.shouldAutoSend) { shouldSend in
                                // Fn key was released - send message immediately
                                if shouldSend && !sessionViewModel.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    print("📤 ActiveSessionView: shouldAutoSend triggered, sending message...")
                                    sessionViewModel.sendMessage(materials: materials)
                                    sessionViewModel.shouldAutoSend = false
                                    // Keep monitoring and overlay open for next message
                                    // Don't stop monitoring or close overlay
                                } else if shouldSend {
                                    print("📤 ActiveSessionView: shouldAutoSend triggered but no text, resetting...")
                                    sessionViewModel.shouldAutoSend = false
                                }
                            }
                            .frame(width: geometry.size.width * 0.4)
                        }
                    }
                } else {
                    // Full-width chat
                    ChatPanel(
                        messages: sessionViewModel.messages,
                        inputValue: $sessionViewModel.inputValue,
                        isListening: sessionViewModel.isListening,
                        isTyping: sessionViewModel.isTyping,
                        isSharing: sessionViewModel.isSharing,
                        onToggleListening: {
                            sessionViewModel.toggleListening()
                        },
                        onSendMessage: {
                            sessionViewModel.sendMessage(materials: materials)
                        },
                        onReferenceClick: { fileName in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sessionViewModel.openPreview(fileName: fileName)
                            }
                        },
                        shouldFocusInput: $sessionViewModel.shouldFocusInput
                    )
                    .onChange(of: sessionViewModel.inputValue) { newValue in
                        // Auto-send when text stabilizes during WhisperFlow monitoring
                        // But only if not triggered by Fn key release
                        if sessionViewModel.isMonitoringWhisperFlow && 
                           !sessionViewModel.shouldAutoSend &&
                           !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // Cancel previous auto-send task
                            sessionViewModel.cancelAutoSend()
                            // Schedule new auto-send
                            sessionViewModel.scheduleAutoSend(materials: materials)
                        }
                    }
                    .onChange(of: sessionViewModel.shouldAutoSend) { shouldSend in
                        // Auto-send triggered (from typing detection or Fn release)
                        if shouldSend && !sessionViewModel.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("📤 ActiveSessionView: shouldAutoSend triggered, sending message...")
                            sessionViewModel.sendMessage(materials: materials)
                            sessionViewModel.shouldAutoSend = false
                            // Keep monitoring and overlay open for next message
                            // Don't stop monitoring or close overlay
                        } else if shouldSend {
                            print("📤 ActiveSessionView: shouldAutoSend triggered but no text, resetting...")
                            sessionViewModel.shouldAutoSend = false
                        }
                    }
                }
            }
        }
        .background(Color.appBackground)
        .onChange(of: sessionViewModel.shouldShowOverlay) { shouldShow in
            print("📱 ActiveSessionView: shouldShowOverlay changed to \(shouldShow)")
            print("   - Current thread: \(Thread.isMainThread ? "Main" : "Background")")
            
            DispatchQueue.main.async {
                if shouldShow {
                    print("   ✅ Showing overlay window...")
                    // Show overlay window with text field binding
                    WhisperFlowOverlayWindowManager.shared.showOverlay(
                        inputValue: $sessionViewModel.inputValue,
                        onSendMessage: {
                            print("   📤 Overlay send message triggered")
                            sessionViewModel.sendMessage(materials: materials)
                        }
                    )
                } else {
                    print("   🛑 Closing overlay window...")
                    // Close overlay
                    WhisperFlowOverlayWindowManager.shared.closeOverlay()
                }
            }
        }
        .onAppear {
            // Check if overlay should be shown on appear
            if sessionViewModel.shouldShowOverlay {
                print("📱 ActiveSessionView: onAppear - showing overlay")
                WhisperFlowOverlayWindowManager.shared.showOverlay(
                    inputValue: $sessionViewModel.inputValue,
                    onSendMessage: {
                        sessionViewModel.sendMessage(materials: materials)
                    }
                )
            }
        }
        .onChange(of: sessionViewModel.shouldAutoSend) { shouldSend in
            // Don't close overlay when sending - keep it open for next message
            // The overlay will be cleared and refocused by sendMessage
        }
    }
}

#Preview {
    ActiveSessionView(
        materials: .constant([
            UploadedMaterial(name: "Lecture Notes.pdf", type: "pdf", size: 1024 * 500)
        ]),
        sessionViewModel: SessionViewModel(),
        onEndSession: {}
    )
    .frame(width: 1280, height: 800)
}
