//
//  ProjectView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ProjectView: View {
    let project: Project
    @Binding var materials: [UploadedMaterial]
    let onUpdateMaterials: ([UploadedMaterial]) -> Void
    let onBack: () -> Void
    
    @State private var isSessionActive = false
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var materialsViewModel = MaterialsViewModel()
    
    var body: some View {
        Group {
            if isSessionActive {
                // Active session view
                ActiveSessionView(
                    materials: $materials,
                    sessionViewModel: sessionViewModel,
                    onEndSession: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSessionActive = false
                        }
                    }
                )
            } else {
                // Project overview
                HStack(spacing: 0) {
                    // Resources panel (left side)
                    ResourcesPanel(
                        materials: materials,
                        onAddMaterial: { urls in
                            materialsViewModel.addMaterials(from: urls)
                            materials = materialsViewModel.materials
                            onUpdateMaterials(materials)
                        },
                        onRemoveMaterial: { materialId in
                            materials.removeAll { $0.id == materialId }
                            onUpdateMaterials(materials)
                        }
                    )
                    
                    Divider()
                    
                    VStack(spacing: 0) {
                        // Project header with back button (disabled during session)
                        ProjectHeaderView(
                            projectName: project.name,
                            onBack: {
                                // Can't go back during active session
                                if !isSessionActive {
                                    onBack()
                                }
                            },
                            canGoBack: !isSessionActive
                        )
                        
                        // Project content
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 100)
                                
                                VStack(spacing: 32) {
                                    // Project info
                                    VStack(spacing: 12) {
                                        Text(project.name)
                                            .font(.system(size: 36, weight: .medium))
                                            .foregroundColor(.appForeground)
                                        
                                        Text("\(materials.count) material\(materials.count == 1 ? "" : "s")")
                                            .font(.body)
                                            .foregroundColor(.appMutedForeground)
                                    }
                                    
                                    // Start session button
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isSessionActive = true
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 20))
                                            Text("Start Session")
                                                .font(.body.weight(.medium))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 32)
                                        .frame(height: 56)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Info text
                                    Text("Start a session to begin chatting with ock about your materials")
                                        .font(.caption)
                                        .foregroundColor(.appMutedForeground)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 400)
                                }
                                .frame(maxWidth: 600)
                                .padding(.horizontal, 16)
                                
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                    }
                }
                .background(Color.appBackground)
            }
        }
        .onAppear {
            materialsViewModel.materials = materials
        }
    }
}

struct ProjectHeaderView: View {
    let projectName: String
    let onBack: () -> Void
    let canGoBack: Bool
    
    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                    Text("Projects")
                        .font(.caption)
                }
                .foregroundColor(canGoBack ? .appMutedForeground : .appMutedForeground.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)
            
            Spacer()
            
            // Project name
            Text(projectName)
                .font(.body.weight(.medium))
                .foregroundColor(.appForeground)
            
            Spacer()
            
            // Spacer to balance the back button
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                Text("Projects")
                    .font(.caption)
            }
            .opacity(0)
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
    }
}

#Preview {
    ProjectView(
        project: Project(name: "CS 101 - Data Structures", materials: []),
        materials: .constant([]),
        onUpdateMaterials: { _ in },
        onBack: {}
    )
    .frame(width: 1280, height: 800)
}
