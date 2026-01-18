//
//  ChatMessage.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

enum MessageRole {
    case user
    case assistant
}

/// Compression statistics for a message
struct MessageCompressionStats {
    let transcriptionOriginalTokens: Int
    let transcriptionCompressedTokens: Int
    let contextOriginalTokens: Int
    let contextCompressedTokens: Int
    
    var totalOriginalTokens: Int {
        transcriptionOriginalTokens + contextOriginalTokens
    }
    
    var totalCompressedTokens: Int {
        transcriptionCompressedTokens + contextCompressedTokens
    }
    
    var totalSavingsPercent: Double {
        guard totalOriginalTokens > 0 else { return 0 }
        return Double(totalOriginalTokens - totalCompressedTokens) / Double(totalOriginalTokens) * 100
    }
    
    var tokensSaved: Int {
        totalOriginalTokens - totalCompressedTokens
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let references: [String]?
    let compressionStats: MessageCompressionStats?
    
    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date = Date(), references: [String]? = nil, compressionStats: MessageCompressionStats? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.references = references
        self.compressionStats = compressionStats
    }
}
