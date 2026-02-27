  //
  //  ChatService.swift
  //  train-ai-v2
  //
  //  Created by Nicholas on 25/02/2026.
  //

  import Foundation
  import Observation
  import SwiftData

  @Observable
  final class ChatService {
      var messages: [ChatMessage] = []
      var isLoading: Bool = false
      var errorMessage: String? = nil
      var currentConversation: Conversation?

      func send(userText: String, modelContext: ModelContext) {
          guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
              errorMessage = "No API key found. Add your Anthropic key in the side menu."
              return
          }

          errorMessage = nil
          messages.append(ChatMessage(role: "user", content: userText))
          isLoading = true
          saveCurrentConversation(modelContext: modelContext)

          Task {
              await callAnthropicAPI(apiKey: apiKey, modelContext: modelContext)
          }
      }

      private func callAnthropicAPI(apiKey: String, modelContext: ModelContext) async {
           let url = URL(string: "https://api.anthropic.com/v1/messages")!
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
           request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
           request.setValue("application/json", forHTTPHeaderField: "content-type")

           let messagePayload = messages.map { ["role": $0.role, "content": $0.content] }
           let body: [String: Any] = [
               "model": selectedModel.rawValue,
               "max_tokens": 1024,
               "stream": true,                          // ← NEW
               "messages": messagePayload
           ]

           do {
               request.httpBody = try JSONSerialization.data(withJSONObject: body)
           } catch {
               await MainActor.run {
                   errorMessage = "Failed to encode request: \(error.localizedDescription)"
                   isLoading = false
               }
               return
           }

           // Add an empty placeholder message right away
           await MainActor.run {
               messages.append(ChatMessage(role: "assistant", content: ""))
           }

           do {
               let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)  // ← CHANGED

               if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                   await MainActor.run {
                       messages.removeLast()  // remove the empty placeholder
                       errorMessage = "API error (\(httpResponse.statusCode))"
                       isLoading = false
                   }
                   return
               }

               // Read the stream line by line
               for try await line in asyncBytes.lines {
                   guard line.hasPrefix("data: ") else { continue }
                   let jsonString = String(line.dropFirst(6))  // strip "data: "
                   guard jsonString != "[DONE]" else { break }

                   if let data = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let delta = (json["delta"] as? [String: Any])?["text"] as? String {
                       await MainActor.run {
                           messages[messages.count - 1].content += delta  // append to last message
                       }
                   }
               }

               await MainActor.run {
                   isLoading = false
                   saveCurrentConversation(modelContext: modelContext)
               }
           } catch {
               await MainActor.run {
                   errorMessage = "Network error: \(error.localizedDescription)"
                   isLoading = false
               }
           }
       }


      func saveCurrentConversation(modelContext: ModelContext) {
          if currentConversation == nil {
              let conversation = Conversation()
              modelContext.insert(conversation)
              currentConversation = conversation
          }

          guard let conversation = currentConversation else { return }

          // Auto-generate title from first user message
          if conversation.title == "New Chat",
             let firstUserMessage = messages.first(where: { $0.role == "user" }) {
              let title = String(firstUserMessage.content.prefix(50))
              conversation.title = title
          }

          conversation.updatedAt = Date()

          // Delete old messages from database, then rebuild
          for oldMessage in conversation.messages {
              modelContext.delete(oldMessage)
          }
          conversation.messages.removeAll()
          for msg in messages {
              let sdMessage = SDMessage(role: msg.role, content: msg.content, timestamp: msg.timestamp, conversation: conversation)
              conversation.messages.append(sdMessage)
          }
      }

      func loadConversation(_ conversation: Conversation) {
          currentConversation = conversation
          messages = conversation.messages
              .sorted { $0.timestamp < $1.timestamp }
              .map { ChatMessage(role: $0.role, content: $0.content) }
      }

      func startNewChat() {
          currentConversation = nil
          messages = []
          errorMessage = nil
      }
  }
