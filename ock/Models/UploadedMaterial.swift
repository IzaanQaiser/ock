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
    let fileURL: URL?
    
    init(id: String = UUID().uuidString, name: String, type: String, size: Int64, fileURL: URL? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.fileURL = fileURL
    }
}
