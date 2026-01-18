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
    
    @State private var isSessionActive = false // Start with session stopped
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var materialsViewModel = MaterialsViewModel()
    
    var body: some View {
        Group {
            if isSessionActive {
                // Active session view (chat view) - stays here, mic button just toggles mic
                ActiveSessionView(
                    materials: $materials,
                    sessionViewModel: sessionViewModel,
                    onEndSession: {
                        // Only used if we need to go back to project overview (not triggered by mic button)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSessionActive = false
                            sessionViewModel.clearSession()
                        }
                    },
                    onBack: {
                        // Go back to projects hub
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSessionActive = false
                            sessionViewModel.clearSession()
                            onBack()
                        }
                    },
                    onUpdateMaterials: { updatedMaterials in
                        onUpdateMaterials(updatedMaterials)
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
            } else {
                // Project overview
                ProjectOverviewView(
                    project: project,
                    materials: $materials,
                    onUpdateMaterials: onUpdateMaterials,
                    onBack: onBack,
                    onStartSession: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSessionActive = true
                            // Start with mic on and overlay on by default
                            sessionViewModel.isListening = true
                            sessionViewModel.shouldShowOverlay = true
                            sessionViewModel.startWhisperFlowMonitoring()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSessionActive)
        .onAppear {
            materialsViewModel.materials = materials
        }
    }
}

struct ProjectOverviewView: View {
    let project: Project
    @Binding var materials: [UploadedMaterial]
    let onUpdateMaterials: ([UploadedMaterial]) -> Void
    let onBack: () -> Void
    let onStartSession: () -> Void
    
    @StateObject private var materialsViewModel = MaterialsViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Resources panel (left side)
            ResourcesPanel(
                materials: materials,
                onAddMaterial: { urls in
                    materialsViewModel.addMaterials(from: urls) {
                        // Update after materials are processed
                        materials = materialsViewModel.materials
                        onUpdateMaterials(materials)
                    }
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
                        onBack()
                    },
                    canGoBack: true
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
                            
                            // Start session button (mic on)
                            Button(action: onStartSession) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 20))
                                    Text("Start Voice Session")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .frame(height: 56)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            // Info text
                            Text("Start a voice session to begin chatting with ock about your materials")
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
