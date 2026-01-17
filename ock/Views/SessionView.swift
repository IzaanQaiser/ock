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
            if viewModel.showReferencesPanel && !materials.isEmpty {
                // Split view: References on left, Chat on right
                HStack(spacing: 0) {
                    // References panel
                    ReferencesPanel(
                        materials: materials,
                        activeReferences: viewModel.activeReferences,
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showReferencesPanel = false
                            }
                        }
                    )
                    
                    Divider()
                    
                    // Chat panel (full height)
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
                        }
                    )
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
