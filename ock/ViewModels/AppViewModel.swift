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
    @Published var materials: [UploadedMaterial] = []
    
    func startSession() {
        appState = .materials
    }
    
    func completeMaterials(_ uploadedMaterials: [UploadedMaterial]) {
        materials = uploadedMaterials
        appState = .session
    }
    
    func endSession() {
        appState = .landing
        materials = []
    }
    
    func goBack() {
        appState = .landing
    }
}
