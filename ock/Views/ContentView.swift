//
//  ContentView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            Group {
                switch appViewModel.appState {
                case .landing:
                    LandingView(onStartSession: {
                        appViewModel.goToProjectsHub()
                    })
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
                    
                case .projectsHub:
                    ProjectsHubView(
                        projects: appViewModel.projects,
                        onCreateProject: {
                            appViewModel.createNewProject()
                        },
                        onSelectProject: { project in
                            appViewModel.selectProject(project)
                        },
                        onDeleteProject: { project in
                            appViewModel.deleteProject(project)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
                    
                case .materials:
                    MaterialsView(
                        onComplete: { materials, projectName in
                            appViewModel.completeMaterials(materials, projectName: projectName)
                        },
                        onBack: {
                            appViewModel.goBack()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
                    
                case .session(let projectId):
                    if let project = appViewModel.currentProject ?? appViewModel.projects.first(where: { $0.id == projectId }) {
                        ProjectView(
                            project: project,
                            materials: Binding(
                                get: { 
                                    appViewModel.currentProject?.materials ?? project.materials
                                },
                                set: { newMaterials in
                                    appViewModel.updateCurrentProjectMaterials(newMaterials)
                                }
                            ),
                            onUpdateMaterials: { updatedMaterials in
                                appViewModel.updateCurrentProjectMaterials(updatedMaterials)
                            },
                            onBack: {
                                appViewModel.goBack()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appViewModel.appState)
        }
        .frame(minWidth: 1024, minHeight: 768)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
