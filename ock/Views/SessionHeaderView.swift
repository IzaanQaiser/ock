//
//  SessionHeaderView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct SessionHeaderView: View {
    let isListening: Bool
    let onToggleListening: () -> Void
    let onEndSession: () -> Void
    let onBack: () -> Void
    
    @State private var pulseOpacity: Double = 0.5
    
    var body: some View {
        HStack {
            // Left side
            HStack(spacing: 12) {
                // Back button
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Projects")
                            .font(.caption)
                    }
                    .foregroundColor(.appMutedForeground)
                }
                .buttonStyle(.plain)
                
                // Divider
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(width: 1, height: 20)
                
                // Logo
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("ock")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    )
                
                // Divider
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(width: 1, height: 20)
                
                // Status indicator (tied to mic state)
                HStack(spacing: 8) {
                    Circle()
                        .fill(isListening ? Color.appSuccess : Color.appMutedForeground)
                        .frame(width: 8, height: 8)
                        .opacity(isListening ? pulseOpacity : 1.0)
                    
                    Text(isListening ? "Session active" : "Session inactive")
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                }
            }
            
            Spacer()
            
            // Right side - Mic (start/end session) button
            HStack(spacing: 12) {
                // Microphone button (start/end session) - just toggles mic, doesn't change view
                Button(action: onToggleListening) {
                    HStack(spacing: 8) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 16))
                        Text(isListening ? "Stop Session" : "Start Session")
                            .font(.caption)
                    }
                    .foregroundColor(isListening ? .white : .appMutedForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isListening ? Color.red : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.appBorder),
            alignment: .bottom
        )
        .onAppear {
            if isListening {
                startPulsing()
            }
        }
        .onChange(of: isListening) { oldValue, newValue in
            if newValue {
                startPulsing()
            } else {
                pulseOpacity = 0.5
            }
        }
    }
    
    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseOpacity = 1.0
        }
    }
}

#Preview {
    SessionHeaderView(
        isListening: true,
        onToggleListening: {},
        onEndSession: {},
        onBack: {}
    )
    .frame(width: 1280, height: 56)
}
