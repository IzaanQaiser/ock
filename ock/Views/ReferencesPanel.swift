//
//  ReferencesPanel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ReferencesPanel: View {
    let materials: [UploadedMaterial]
    let activeReferences: [String]
    let previewedFileName: String?
    let onClose: () -> Void
    let onClosePreview: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Only show preview if there's a previewed file
            if let previewedFileName = previewedFileName,
               let material = materials.first(where: { $0.name == previewedFileName }) {
                // Document preview - just show file name header
                VStack(spacing: 0) {
                    // Preview header with close button
                    HStack {
                        Text(material.name)
                            .font(.body.weight(.medium))
                            .foregroundColor(.appForeground)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button(action: onClosePreview) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.appMutedForeground)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(Color.appSecondary)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.appBorder),
                        alignment: .bottom
                    )
                    
                    // Document preview content
                    if let fileURL = material.fileURL {
                        DocumentPreviewView(fileURL: fileURL, fileName: material.name)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Fallback if file URL is not available
                        ScrollView {
                            VStack(spacing: 16) {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(.appMutedForeground)
                                    
                                    VStack(spacing: 4) {
                                        Text(material.name)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.appForeground)
                                        
                                        Text(FileSizeFormatter.format(material.size))
                                            .font(.caption2)
                                            .foregroundColor(.appMutedForeground)
                                    }
                                }
                                .padding(.top, 48)
                                
                                Text("File preview not available")
                                    .font(.caption)
                                    .foregroundColor(.appMutedForeground)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.appBorder),
            alignment: .trailing
        )
    }
}

struct ReferenceItemView: View {
    let material: UploadedMaterial
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundColor(.appMutedForeground)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.body)
                    .foregroundColor(.appForeground)
                    .lineLimit(2)
                
                Text(FileSizeFormatter.format(material.size))
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
            }
            
            Spacer()
            
            if isActive {
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.appSuccess)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.white.opacity(0.1) : Color.appSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isActive ? Color.white.opacity(0.2) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    ReferencesPanel(
        materials: [
            UploadedMaterial(name: "Lecture Notes.pdf", type: "pdf", size: 1024 * 500),
            UploadedMaterial(name: "Textbook Chapter 3.docx", type: "docx", size: 1024 * 1024 * 2)
        ],
        activeReferences: ["Lecture Notes.pdf"],
        previewedFileName: nil,
        onClose: {},
        onClosePreview: {}
    )
    .frame(width: 320, height: 600)
}
