//
//  SessionView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct SessionView: View {
    let materials: [UploadedMaterial]
    let onEndSession: () -> Void
    
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionHeaderView(
                isSharing: viewModel.isSharing,
                hasPermission: viewModel.hasScreenSharePermission,
                onToggleShare: {
                    viewModel.toggleScreenShare()
                },
                onEndSession: onEndSession
            )
            
            // Main content - dynamic layout
            if let previewedFileName = viewModel.previewedFileName,
               let material = materials.first(where: { $0.name == previewedFileName }) {
                // Split view: 60% PDF preview, 40% Chat
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // PDF preview panel (60%)
                        ReferencesPanel(
                            materials: materials,
                            activeReferences: viewModel.activeReferences,
                            previewedFileName: viewModel.previewedFileName,
                            onClose: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.closePreview()
                                }
                            },
                            onClosePreview: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.closePreview()
                                }
                            }
                        )
                        .frame(width: geometry.size.width * 0.6)
                        
                        Divider()
                        
                        // Chat panel (40%)
                        ChatPanel(
                            messages: viewModel.messages,
                            inputValue: $viewModel.inputValue,
                            isListening: viewModel.isListening,
                            isTyping: viewModel.isTyping,
                            isSharing: viewModel.isSharing,
                            onToggleListening: {
                                viewModel.toggleListening()
                            },
                            onSendMessage: {
                                viewModel.sendMessage(materials: materials)
                            },
                            onReferenceClick: { fileName in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if viewModel.previewedFileName == fileName {
                                        // If clicking the same file, close it
                                        viewModel.closePreview()
                                    } else {
                                        // Open the preview
                                        viewModel.openPreview(fileName: fileName)
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
                    messages: viewModel.messages,
                    inputValue: $viewModel.inputValue,
                    isListening: viewModel.isListening,
                    isTyping: viewModel.isTyping,
                    isSharing: viewModel.isSharing,
                    onToggleListening: {
                        viewModel.toggleListening()
                    },
                    onSendMessage: {
                        viewModel.sendMessage(materials: materials)
                    },
                    onReferenceClick: { fileName in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.openPreview(fileName: fileName)
                        }
                    }
                )
            }
        }
        .background(Color.appBackground)
    }
}

#Preview {
    SessionView(materials: [], onEndSession: {})
        .frame(width: 1280, height: 800)
}
