//
//  Conversation.swift
//  train-ai-v2
//

import Foundation
import SwiftData

  @Model
  final class Conversation {
      var title: String
      var createdAt: Date
      var updatedAt: Date

      @Relationship(deleteRule: .cascade, inverse: \SDMessage.conversation)
      var messages: [SDMessage]

      init(title: String = "New Chat", createdAt: Date = Date(), updatedAt: Date = Date()) {
          self.title = title
          self.createdAt = createdAt
          self.updatedAt = updatedAt
          self.messages = []
      }
  }

  @Model
  final class SDMessage {
      var role: String
      var content: String
      var timestamp: Date
      var conversation: Conversation?

      init(role: String, content: String, timestamp: Date = Date(), conversation: Conversation? = nil) {
          self.role = role
          self.content = content
          self.timestamp = timestamp
          self.conversation = conversation
      }
  }
