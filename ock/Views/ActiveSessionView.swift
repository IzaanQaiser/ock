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
    let onEndSession: () -> Void // This is now only used for going back to project view, not for stopping mic
    let onBack: () -> Void // Back to projects
    let onUpdateMaterials: ([UploadedMaterial]) -> Void // For updating materials during active session
    
    var body: some View {
        HStack(spacing: 0) {
            // Resources panel (left side) - enabled during active session
            ResourcesPanel(
                materials: materials,
                onAddMaterial: { urls in
                    // Add materials during active session
                    let materialsViewModel = MaterialsViewModel()
                    materialsViewModel.materials = materials
                    
                    // Process materials asynchronously and update when done
                    materialsViewModel.addMaterials(from: urls) {
                        // Completion handler - update materials after processing is complete
                        onUpdateMaterials(materialsViewModel.materials)
                    }
                },
                onRemoveMaterial: { materialId in
                    // Remove materials during active session
                    var updatedMaterials = materials
                    updatedMaterials.removeAll { $0.id == materialId }
                    onUpdateMaterials(updatedMaterials)
                }
            )
            
            Divider()
            
            VStack(spacing: 0) {
                // Header
                SessionHeaderView(
                    isListening: sessionViewModel.isListening,
                    onToggleListening: {
                        // Just toggle mic - don't change view
                        sessionViewModel.toggleListening()
                    },
                    onEndSession: {
                        // This is not used anymore - mic toggle handles start/stop
                        // Keep this for potential future use or remove if not needed
                    },
                    onBack: onBack
                )
                
                // Main content - dynamic layout with animation
                Group {
                    if let previewedFileName = sessionViewModel.previewedFileName,
                       materials.first(where: { $0.name == previewedFileName }) != nil {
                        // Split view: 60% PDF preview, 40% Chat
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // PDF preview panel (60%)
                                ReferencesPanel(
                                    materials: materials,
                                    activeReferences: sessionViewModel.activeReferences,
                                    previewedFileName: sessionViewModel.previewedFileName,
                                    onClose: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            sessionViewModel.closePreview()
                                        }
                                    },
                                    onClosePreview: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            sessionViewModel.closePreview()
                                        }
                                    }
                                )
                                .frame(width: geometry.size.width * 0.6)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                            
                                Divider()
                            
                                // Chat panel (40%)
                                ChatPanel(
                                    messages: sessionViewModel.messages,
                                    inputValue: $sessionViewModel.inputValue,
                                    isListening: sessionViewModel.isListening,
                                    isTyping: sessionViewModel.isTyping,
                                    onToggleListening: {
                                        sessionViewModel.toggleListening()
                                    },
                                    onSendMessage: {
                                        sessionViewModel.sendMessage(materials: materials)
                                    },
                                    onReferenceClick: { fileName in
                                        withAnimation(.easeInOut(duration: 0.3)) {
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
                                .onChange(of: sessionViewModel.inputValue) { oldValue, newValue in
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
                                .onChange(of: sessionViewModel.shouldAutoSend) { oldValue, shouldSend in
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
                            onToggleListening: {
                                sessionViewModel.toggleListening()
                            },
                            onSendMessage: {
                                sessionViewModel.sendMessage(materials: materials)
                            },
                            onReferenceClick: { fileName in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    sessionViewModel.openPreview(fileName: fileName)
                                }
                            },
                            shouldFocusInput: $sessionViewModel.shouldFocusInput
                        )
                        .onChange(of: sessionViewModel.inputValue) { oldValue, newValue in
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
                        .onChange(of: sessionViewModel.shouldAutoSend) { oldValue, shouldSend in
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
            .animation(.easeInOut(duration: 0.3), value: sessionViewModel.previewedFileName)
        }
        .background(Color.appBackground)
        .onChange(of: sessionViewModel.shouldShowOverlay) { oldValue, shouldShow in
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
        .onChange(of: sessionViewModel.shouldAutoSend) { oldValue, shouldSend in
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
        onEndSession: {},
        onBack: {},
        onUpdateMaterials: { _ in }
    )
    .frame(width: 1280, height: 800)
}
