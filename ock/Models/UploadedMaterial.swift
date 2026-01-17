//
//  UploadedMaterial.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

struct UploadedMaterial: Identifiable, Equatable {
    let id: String
    let name: String
    let type: String
    let size: Int64
    
    init(id: String = UUID().uuidString, name: String, type: String, size: Int64) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
    }
}
