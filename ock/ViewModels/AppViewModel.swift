//
//  AppViewModel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var appState: AppState = .landing
    @Published var projects: [Project] = []
    @Published var currentProject: Project?
    
    private let projectsKey = "saved_projects"
    
    init() {
        loadProjects()
    }
    
    // MARK: - Navigation
    
    func goToProjectsHub() {
        appState = .projectsHub
    }
    
    func createNewProject() {
        appState = .materials
    }
    
    func completeMaterials(_ uploadedMaterials: [UploadedMaterial], projectName: String) {
        // Create new project with materials and custom name
        var newProject = Project(name: projectName, materials: uploadedMaterials)
        newProject.updatedAt = Date()
        
        projects.append(newProject)
        currentProject = newProject
        saveProjects()
        
        appState = .session(projectId: newProject.id)
    }
    
    func selectProject(_ project: Project) {
        currentProject = project
        appState = .session(projectId: project.id)
    }
    
    func updateCurrentProjectMaterials(_ materials: [UploadedMaterial]) {
        guard var project = currentProject else { return }
        project.materials = materials
        project.updatedAt = Date()
        currentProject = project
        
        // Update in projects array
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func endSession() {
        appState = .projectsHub
        currentProject = nil
    }
    
    func goBack() {
        appState = .projectsHub
    }
    
    // MARK: - Project Persistence
    
    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: projectsKey),
              let decoded = try? JSONDecoder().decode([Project].self, from: data) else {
            projects = []
            return
        }
        projects = decoded
    }
    
    private func saveProjects() {
        guard let encoded = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(encoded, forKey: projectsKey)
    }
}
