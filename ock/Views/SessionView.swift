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
                onEndSession: onEndSession
            )
            
            // Main content
            HStack(spacing: 0) {
                // Screen preview panel
                ScreenPreviewPanel(
                    isSharing: viewModel.isSharing,
                    onToggleShare: {
                        viewModel.toggleScreenShare()
                    }
                )
                
                Divider()
                
                // Chat and references panel
                VStack(spacing: 0) {
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
                    
                    if !materials.isEmpty {
                        Divider()
                        
                        ReferencesPanel(
                            materials: materials,
                            activeReferences: viewModel.activeReferences
                        )
                    }
                }
            }
        }
        .background(Color.appBackground)
    }
}

#Preview {
    SessionView(materials: [], onEndSession: {})
        .frame(width: 1280, height: 800)
}
