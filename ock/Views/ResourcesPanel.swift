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
    let isCompact: Bool
    let isDisabled: Bool
    
    @State private var showFilePicker = false
    @StateObject private var materialsViewModel = MaterialsViewModel()
    
    init(
        materials: [UploadedMaterial],
        onAddMaterial: @escaping ([URL]) -> Void,
        onRemoveMaterial: @escaping (String) -> Void,
        isCompact: Bool = false,
        isDisabled: Bool = false
    ) {
        self.materials = materials
        self.onAddMaterial = onAddMaterial
        self.onRemoveMaterial = onRemoveMaterial
        self.isCompact = isCompact
        self.isDisabled = isDisabled
    }
    
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
        .frame(width: isCompact ? 220 : 280)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.appBorder),
            alignment: .trailing
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled)
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
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.appMutedForeground)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(isHovering ? Color.appMuted : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appSecondary)
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
        onRemoveMaterial: { _ in },
        isCompact: false,
        isDisabled: false
    )
    .frame(width: 280, height: 600)
}
