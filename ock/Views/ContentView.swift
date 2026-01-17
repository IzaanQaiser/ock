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
                    .transition(.opacity)
                    
                case .projectsHub:
                    ProjectsHubView(
                        projects: appViewModel.projects,
                        onCreateProject: {
                            appViewModel.createNewProject()
                        },
                        onSelectProject: { project in
                            appViewModel.selectProject(project)
                        }
                    )
                    .transition(.opacity)
                    
                case .materials:
                    MaterialsView(
                        onComplete: { materials in
                            appViewModel.completeMaterials(materials)
                        },
                        onBack: {
                            appViewModel.goBack()
                        }
                    )
                    .transition(.opacity)
                    
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
                        .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: appViewModel.appState)
        }
        .frame(minWidth: 1024, minHeight: 768)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
