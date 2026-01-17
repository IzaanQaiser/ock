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
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text("References")
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.appMutedForeground)
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.appBorder),
                alignment: .top
            )
            
            // References list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(materials) { material in
                        ReferenceItemView(
                            material: material,
                            isActive: activeReferences.contains(material.name)
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(height: 192)
        .background(Color.appBackground)
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
            
            Text(material.name)
                .font(.body)
                .foregroundColor(.appForeground)
                .lineLimit(1)
            
            Spacer()
            
            if isActive {
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.appSuccess)
            }
        }
        .padding(8)
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
        activeReferences: ["Lecture Notes.pdf"]
    )
    .frame(width: 640, height: 192)
}
