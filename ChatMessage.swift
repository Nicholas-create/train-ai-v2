//
//  ChatMessage.swift
//  train-ai-v2
//
//  Created by Nicholas on 25/02/2026.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: String      // "user" or "assistant"
    var content: String
    let timestamp: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}
