//
//  UploadedMaterial.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

struct UploadedMaterial: Identifiable, Equatable, Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, size, fileURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        size = try container.decode(Int64.self, forKey: .size)
        fileURL = try container.decodeIfPresent(URL.self, forKey: .fileURL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
    }
}
