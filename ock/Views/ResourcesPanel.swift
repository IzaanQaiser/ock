//
//  ResourcesPanel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI
import UniformTypeIdentifiers

struct ResourcesPanel: View {
    let materials: [UploadedMaterial]
    let onAddMaterial: ([URL]) -> Void
    let onRemoveMaterial: (String) -> Void
    
    @State private var showFilePicker = false
    @StateObject private var materialsViewModel = MaterialsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Resources")
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
                
                Spacer()
                
                Button(action: {
                    showFilePicker = true
                }) {
                    Image(systemName: "plus")
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
            
            // Materials list
            if materials.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.appMutedForeground)
                        
                        Text("No materials")
                            .font(.body)
                            .foregroundColor(.appMutedForeground)
                        
                        Button(action: {
                            showFilePicker = true
                        }) {
                            Text("Add Material")
                                .font(.caption)
                                .foregroundColor(.appForeground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.appSecondary)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(materials) { material in
                            ResourceItemView(material: material) {
                                onRemoveMaterial(material.id)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 280)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.appBorder),
            alignment: .trailing
        )
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                let validUrls = urls.filter { materialsViewModel.isValidFileType($0) }
                if !validUrls.isEmpty {
                    onAddMaterial(validUrls)
                }
            }
        }
    }
}

struct ResourceItemView: View {
    let material: UploadedMaterial
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Document icon with compression indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appMutedForeground.opacity(0.6))
                
                // Small compression indicator
                if material.savingsPercent > 0 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appForeground)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(FileSizeFormatter.format(material.size))
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                    
                    if material.savingsPercent > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground.opacity(0.5))
                        
                        Text("-\(String(format: "%.0f", material.savingsPercent))% tokens")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.appMutedForeground)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.appMuted.opacity(isHovering ? 0.8 : 0))
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appSecondary.opacity(0.7))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ResourcesPanel(
        materials: [
            UploadedMaterial(name: "Lecture Notes.pdf", type: "pdf", size: 1024 * 500),
            UploadedMaterial(name: "Textbook Chapter 3.docx", type: "docx", size: 1024 * 1024 * 2)
        ],
        onAddMaterial: { _ in },
        onRemoveMaterial: { _ in }
    )
    .frame(width: 280, height: 600)
}
