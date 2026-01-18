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
    var extractedText: String?  // Text extracted from PDF/documents for RAG
    var textChunks: [String]?   // Pre-chunked text for fast retrieval
    var originalTokenCount: Int?  // Token count before compression
    var compressedTokenCount: Int?  // Token count after compression
    
    var tokensSaved: Int {
        guard let original = originalTokenCount, let compressed = compressedTokenCount else { return 0 }
        return original - compressed
    }
    
    var savingsPercent: Double {
        guard let original = originalTokenCount, let compressed = compressedTokenCount, original > 0 else { return 0 }
        return Double(original - compressed) / Double(original) * 100
    }
    
    init(id: String = UUID().uuidString, name: String, type: String, size: Int64, fileURL: URL? = nil, extractedText: String? = nil, originalTokenCount: Int? = nil, compressedTokenCount: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.size = size
        self.fileURL = fileURL
        self.extractedText = extractedText
        self.textChunks = extractedText.map { Self.chunkText($0) }
        self.originalTokenCount = originalTokenCount
        self.compressedTokenCount = compressedTokenCount
    }
    
    /// Chunk text into smaller pieces for retrieval (roughly 500 chars each)
    private static func chunkText(_ text: String, chunkSize: Int = 500, overlap: Int = 50) -> [String] {
        guard !text.isEmpty else { return [] }
        
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endDistance = min(chunkSize, text.distance(from: startIndex, to: text.endIndex))
            let endIndex = text.index(startIndex, offsetBy: endDistance)
            
            let chunk = String(text[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                chunks.append(chunk)
            }
            
            // Move forward with overlap
            let advanceDistance = max(1, chunkSize - overlap)
            if let newStart = text.index(startIndex, offsetBy: advanceDistance, limitedBy: text.endIndex) {
                startIndex = newStart
            } else {
                break
            }
        }
        
        return chunks
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, size, fileURL, extractedText, textChunks, originalTokenCount, compressedTokenCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        size = try container.decode(Int64.self, forKey: .size)
        fileURL = try container.decodeIfPresent(URL.self, forKey: .fileURL)
        extractedText = try container.decodeIfPresent(String.self, forKey: .extractedText)
        textChunks = try container.decodeIfPresent([String].self, forKey: .textChunks)
        originalTokenCount = try container.decodeIfPresent(Int.self, forKey: .originalTokenCount)
        compressedTokenCount = try container.decodeIfPresent(Int.self, forKey: .compressedTokenCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encodeIfPresent(extractedText, forKey: .extractedText)
        try container.encodeIfPresent(textChunks, forKey: .textChunks)
        try container.encodeIfPresent(originalTokenCount, forKey: .originalTokenCount)
        try container.encodeIfPresent(compressedTokenCount, forKey: .compressedTokenCount)
    }
}
