//
//  ScreenPreviewPanel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ScreenPreviewPanel: View {
    let isSharing: Bool
    let onToggleShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text("Screen Preview")
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
                
                Spacer()
                
                Button(action: onToggleShare) {
                    HStack(spacing: 8) {
                        Image(systemName: "display")
                            .font(.system(size: 16))
                        Text(isSharing ? "Stop sharing" : "Share screen")
                            .font(.body)
                    }
                    .foregroundColor(isSharing ? .appForeground : .black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSharing ? Color.appSecondary : Color.white)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            // Preview area
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "display")
                        .font(.system(size: 48))
                        .foregroundColor(.appMutedForeground)
                        .opacity(isSharing ? 1.0 : 0.5)
                    
                    if isSharing {
                        VStack(spacing: 4) {
                            Text("Screen sharing active")
                                .font(.body)
                                .foregroundColor(.appMutedForeground)
                            
                            Text("ock can see your screen")
                                .font(.caption2)
                                .foregroundColor(.appMutedForeground.opacity(0.6))
                        }
                    } else {
                        Text("Click \"Share screen\" to begin")
                            .font(.body)
                            .foregroundColor(.appMutedForeground)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.appBorder, lineWidth: 1)
                    )
            )
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    ScreenPreviewPanel(isSharing: false, onToggleShare: {})
        .frame(width: 640, height: 600)
}
