//
//  ProjectsHubView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ProjectsHubView: View {
    let projects: [Project]
    let onCreateProject: () -> Void
    let onSelectProject: (Project) -> Void
    
    var body: some View {
        ZStack {
            // Subtle background glow
            Circle()
                .fill(Color.white.opacity(0.02))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(x: 0, y: 0)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Projects")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.appForeground)
                        
                        Text("Create a new project or continue working on an existing one.")
                            .font(.body)
                            .foregroundColor(.appMutedForeground)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 512)
                    }
                    .padding(.bottom, 48)
                
                    if projects.isEmpty {
                        // Empty state - show create button prominently
                        VStack(spacing: 24) {
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 64))
                                    .foregroundColor(.appMutedForeground)
                                
                                Text("No projects yet")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.appForeground)
                                
                                Text("Create your first project to get started")
                                    .font(.caption)
                                    .foregroundColor(.appMutedForeground)
                            }
                            
                            Button(action: onCreateProject) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16))
                                    Text("Create Project")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 32)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Projects grid - wider container for grid layout
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 16)
                        ], spacing: 16) {
                            // Create project card
                            CreateProjectCard(onCreate: onCreateProject)
                            
                            // Existing project cards
                            ForEach(projects) { project in
                                ProjectCard(project: project) {
                                    onSelectProject(project)
                                }
                            }
                        }
                        .frame(maxWidth: 1200)
                    }
                }
                .frame(maxWidth: 672)
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
    }
}

struct CreateProjectCard: View {
    let onCreate: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onCreate) {
            VStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundColor(.appMutedForeground)
                
                Text("Create Project")
                    .font(.body.weight(.medium))
                    .foregroundColor(.appForeground)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isHovering ? Color.white.opacity(0.3) : Color.appBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct ProjectCard: View {
    let project: Project
    let onSelect: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appMutedForeground)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.body.weight(.medium))
                        .foregroundColor(.appForeground)
                        .lineLimit(2)
                    
                    Text("\(project.materials.count) material\(project.materials.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.appMutedForeground)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isHovering ? Color.white.opacity(0.3) : Color.appBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ProjectsHubView(
        projects: [
            Project(name: "CS 101 - Data Structures", materials: []),
            Project(name: "Math 201 - Calculus", materials: [])
        ],
        onCreateProject: {},
        onSelectProject: { _ in }
    )
    .frame(width: 1280, height: 800)
}
