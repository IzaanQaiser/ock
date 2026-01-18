//
//  MaterialsView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI
import UniformTypeIdentifiers

struct MaterialsView: View {
    let onComplete: ([UploadedMaterial]) -> Void
    let onBack: () -> Void
    
    @StateObject private var viewModel = MaterialsViewModel()
    @State private var isHoveringUpload = false
    @State private var showFilePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Back button
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                            Text("Back")
                                .font(.caption)
                        }
                        .foregroundColor(.appMutedForeground)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                    
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add your materials")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.appForeground)
                        
                        Text("Upload lecture notes, textbooks, or slides. This helps ock understand your course context.")
                            .font(.body)
                            .foregroundColor(.appMutedForeground)
                    }
                    .padding(.bottom, 32)
                    
                    // Upload area
                    Button(action: {
                        showFilePicker = true
                    }) {
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appSecondary)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 24))
                                        .foregroundColor(.appMutedForeground)
                                )
                            
                            VStack(spacing: 4) {
                                Text("Drop files here or click to upload")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.appForeground)
                                
                                Text("PDF, DOC, TXT, PPT supported")
                                    .font(.caption)
                                    .foregroundColor(.appMutedForeground)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [5])
                                )
                                .foregroundColor(
                                    viewModel.isDragging ? .white : .appBorder
                                )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isDragging ? Color.white.opacity(0.05) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                    .onHover { hovering in
                        isHoveringUpload = hovering
                    }
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.item], // Allow all files, we'll validate by extension
                        allowsMultipleSelection: true
                    ) { result in
                        handleFileSelection(result: result)
                    }
                    
                    // Uploaded files
                    if !viewModel.materials.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.materials) { material in
                                MaterialItemView(material: material) {
                                    viewModel.removeMaterial(material.id)
                                }
                            }
                        }
                        .padding(.top, 24)
                    }
                    
                    // Action button
                    Button(action: {
                        onComplete(viewModel.materials)
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.materials.isEmpty ? "Skip and start" : "Start session")
                                .font(.body.weight(.medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 32)
                    
                    // Hint text
                    Text("Materials are optional but help ock give more relevant explanations")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
                .frame(maxWidth: 576)
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   viewModel.isValidFileType(url) {
                    urls.append(url)
                }
            }
        }
        
        group.notify(queue: .main) {
            viewModel.addMaterials(from: urls)
        }
        
        return true
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // Filter to only valid file types
            let validUrls = urls.filter { viewModel.isValidFileType($0) }
            viewModel.addMaterials(from: validUrls)
        case .failure:
            break
        }
    }
}

struct MaterialItemView: View {
    let material: UploadedMaterial
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appMuted)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "doc.text")
                        .font(.system(size: 20))
                        .foregroundColor(.appMutedForeground)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
                    .lineLimit(1)
                
                Text(FileSizeFormatter.format(material.size))
                    .font(.caption2)
                    .foregroundColor(.appMutedForeground)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 16))
                    .foregroundColor(.appMutedForeground)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
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
    MaterialsView(onComplete: { _ in }, onBack: {})
        .frame(width: 1280, height: 800)
}
