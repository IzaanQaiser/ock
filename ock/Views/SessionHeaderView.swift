//
//  SessionHeaderView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct SessionHeaderView: View {
    let isSharing: Bool
    let hasPermission: Bool
    let onToggleShare: () -> Void
    let onEndSession: () -> Void
    
    @State private var pulseOpacity: Double = 0.5
    
    var body: some View {
        HStack {
            // Left side
            HStack(spacing: 12) {
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
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(isSharing ? Color.appSuccess : Color.appMutedForeground)
                        .frame(width: 8, height: 8)
                        .opacity(isSharing ? pulseOpacity : 1.0)
                    
                    Text(isSharing ? "Session active" : "Not sharing")
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                }
            }
            
            Spacer()
            
            // Right side - Screen share and End session buttons
            HStack(spacing: 12) {
                // Screen share button
                Button(action: onToggleShare) {
                    HStack(spacing: 8) {
                        Image(systemName: "display")
                            .font(.system(size: 16))
                        Text(hasPermission ? (isSharing ? "Stop sharing" : "Share") : "Manage")
                            .font(.caption)
                    }
                    .foregroundColor(.appMutedForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                    )
                }
                .buttonStyle(.plain)
                
                // End session button
                Button(action: onEndSession) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.fill")
                            .font(.system(size: 16))
                        Text("End session")
                            .font(.caption)
                    }
                    .foregroundColor(.appMutedForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
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
            if isSharing {
                startPulsing()
            }
        }
        .onChange(of: isSharing) { newValue in
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
        isSharing: true,
        hasPermission: true,
        onToggleShare: {},
        onEndSession: {}
    )
    .frame(width: 1280, height: 56)
}
