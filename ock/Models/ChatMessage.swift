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

struct ChatMessage: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let references: [String]?
    
    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date = Date(), references: [String]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.references = references
    }
}
