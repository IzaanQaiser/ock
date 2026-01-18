//
//  Project.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

struct Project: Identifiable, Codable {
    let id: String
    var name: String
    var materials: [UploadedMaterial]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, name: String, materials: [UploadedMaterial] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.materials = materials
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
