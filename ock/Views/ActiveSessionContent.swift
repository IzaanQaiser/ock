//
//  ActiveSessionContent.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ActiveSessionContent: View {
    @Binding var materials: [UploadedMaterial]
    @ObservedObject var sessionViewModel: SessionViewModel
    let onEndSession: () -> Void
    let onUpdateMaterials: ([UploadedMaterial]) -> Void
    
    var body: some View {
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
                        }
                    )
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
                }
            )
        }
    }
}

#Preview {
    ActiveSessionContent(
        materials: .constant([
            UploadedMaterial(name: "Lecture Notes.pdf", type: "pdf", size: 1024 * 500)
        ]),
        sessionViewModel: SessionViewModel(),
        onEndSession: {},
        onUpdateMaterials: { _ in }
    )
    .frame(width: 1280, height: 800)
}
