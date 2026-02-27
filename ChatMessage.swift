//
//  ChatMessage.swift
//  train-ai-v2
//
//  Created by Nicholas on 25/02/2026.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole      // "user" or "assistant"
    var content: String
    let timestamp: Date
    enum MessageRole: String {
        case user = "user"
        case assistant = "assistant"
    }

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}
