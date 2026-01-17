//
//  MaterialsViewModel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class MaterialsViewModel: ObservableObject {
    @Published var materials: [UploadedMaterial] = []
    @Published var isDragging: Bool = false
    
    func addMaterial(from url: URL) {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .typeIdentifierKey])
        let size = Int64(resourceValues?.fileSize ?? 0)
        let type = resourceValues?.typeIdentifier ?? ""
        
        let material = UploadedMaterial(
            name: url.lastPathComponent,
            type: type,
            size: size
        )
        
        materials.append(material)
    }
    
    func addMaterials(from urls: [URL]) {
        for url in urls {
            addMaterial(from: url)
        }
    }
    
    func removeMaterial(_ id: String) {
        materials.removeAll { $0.id == id }
    }
    
    func clearMaterials() {
        materials = []
    }
    
    func isValidFileType(_ url: URL) -> Bool {
        // Simply check file extension - this is the most reliable method
        let pathExtension = url.pathExtension.lowercased()
        let allowedExtensions = ["pdf", "doc", "docx", "txt", "ppt", "pptx", "rtf"]
        return allowedExtensions.contains(pathExtension)
    }
}
