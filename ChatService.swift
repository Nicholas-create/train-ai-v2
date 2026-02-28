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
      private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
      var messages: [ChatMessage] = []
      var isLoading: Bool = false
      var errorMessage: String? = nil
      var currentConversation: Conversation?
    var systemPrompt: String = ""

      func send(userText: String, modelContext: ModelContext) {
          guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
              errorMessage = "No API key found. Add your Anthropic key in the side menu."
              return
          }

          errorMessage = nil
          messages.append(ChatMessage(role: .user, content: userText))
          isLoading = true
          saveCurrentConversation(modelContext: modelContext)

          Task {
              await callAnthropicAPI(apiKey: apiKey, modelContext: modelContext)
          }
      }

      private func callAnthropicAPI(apiKey: String, modelContext: ModelContext) async {
          var request = URLRequest(url: Self.apiURL)
           request.httpMethod = "POST"
           request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
           request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
           request.setValue("application/json", forHTTPHeaderField: "content-type")

           let messagePayload = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
           var body: [String: Any] = [
               "model": selectedModel.rawValue,
               "max_tokens": 1024,
               "stream": true,                          // ← NEW
               "messages": messagePayload
           ]
           if !systemPrompt.isEmpty {
               body["system"] = systemPrompt
           }

           do {
               request.httpBody = try JSONSerialization.data(withJSONObject: body)
           } catch {
               await MainActor.run {
                   errorMessage = "Failed to prepare message. Please try again."
                   isLoading = false
               }
               return
           }

           // Add an empty placeholder message right away
           await MainActor.run {
               messages.append(ChatMessage(role: .assistant, content: ""))
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
                   errorMessage = "Connection error. Check your internet and try again."
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
            let firstUserMessage = messages.first(where: { $0.role == .user }) {
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
              let sdMessage = SDMessage(role: msg.role.rawValue, content: msg.content, timestamp: msg.timestamp, conversation: conversation)
              conversation.messages.append(sdMessage)
          }
      }

      func loadConversation(_ conversation: Conversation) {
          currentConversation = conversation
          messages = conversation.messages
              .sorted { $0.timestamp < $1.timestamp }
              .map { ChatMessage(role: ChatMessage.MessageRole(rawValue: $0.role) ?? .user, content: $0.content) }
      }

      func startNewChat() {
          currentConversation = nil
          messages = []
          errorMessage = nil
      }

      func buildSystemPrompt(profile: UserProfile?, units: String) {
          let base = coachingSystemPrompt

          guard let p = profile else {
              systemPrompt = base
              return
          }

          var block = "\n\n---\n\n## User Profile\n"

          if !p.nickname.isEmpty     { block += "- Nickname: \(sanitize(p.nickname))\n" }
          if let year = p.birthYear {
              let currentYear = Calendar.current.component(.year, from: Date())
              block += "- Age: ~\(currentYear - year)\n"
          }
          if let g = p.gender, g != "prefer_not_to_say", !g.isEmpty {
              block += "- Gender: \(g.replacingOccurrences(of: "_", with: "-"))\n"
          }
          if let h = p.heightCm          { block += "- Height: \(formatHeight(h, units: units))\n" }
          if let w = p.currentWeightKg   { block += "- Current Weight: \(formatWeight(w, units: units))\n" }
          if let w = p.startWeightKg     { block += "- Start Weight: \(formatWeight(w, units: units))\n" }
          if let w = p.goalWeightKg      { block += "- Goal Weight: \(formatWeight(w, units: units))\n" }
          if let bf = p.bodyFatPercent   { block += "- Body Fat: \(Int(bf))%\n" }

          if let raw = p.primaryGoal, !raw.isEmpty {
              let labels: [String: String] = [
                  "lose_weight": "Lose Weight", "build_muscle": "Build Muscle",
                  "endurance": "Endurance",     "flexibility": "Flexibility",
                  "general_health": "General Health", "sport_specific": "Sport Specific"
              ]
              let readable = raw.split(separator: ",")
                  .map { labels[String($0)] ?? String($0) }
                  .joined(separator: ", ")
              block += "- Goals: \(readable)\n"
          }
          if let d = p.goalDeadline {
              let f = DateFormatter(); f.dateStyle = .medium
              block += "- Goal Deadline: \(f.string(from: d))\n"
          }
          if let note = p.motivationNote, !note.isEmpty { block += "- Motivation: \(sanitize(note))\n" }

          if let lvl = p.experienceLevel, !lvl.isEmpty {
              block += "- Experience Level: \(lvl.capitalized)\n"
          }
          if let act = p.activityLevel, !act.isEmpty {
              block += "- Activity Level: \(act.replacingOccurrences(of: "_", with: " ").capitalized)\n"
          }

          if let c = p.medicalConditions, !c.isEmpty  { block += "- Medical Conditions: \(sanitize(c))\n" }
          if let i = p.currentInjuries, !i.isEmpty    { block += "- Current Injuries: \(sanitize(i))\n" }
          if let m = p.medications, !m.isEmpty        { block += "- Medications: \(sanitize(m))\n" }

          if let s = p.sleepHoursPerNight { block += "- Sleep: \(String(format: "%.1f", s))h/night\n" }
          if let s = p.stressLevel        { block += "- Stress Level: \(s)/10\n" }
          if let d = p.dietaryPreferences, !d.isEmpty { block += "- Dietary Preferences: \(sanitize(d))\n" }
          if let a = p.foodAllergies, !a.isEmpty      { block += "- Food Allergies: \(sanitize(a))\n" }

          if let loc = p.trainingLocation, !loc.isEmpty   { block += "- Training Location: \(loc.capitalized)\n" }
          if let days = p.preferredDaysPerWeek            { block += "- Preferred Days/Week: \(days)\n" }
          if let mins = p.preferredSessionMinutes          { block += "- Preferred Session Length: \(mins) min\n" }
          if let t = p.preferredTimeOfDay, !t.isEmpty      { block += "- Preferred Time of Day: \(t.capitalized)\n" }

          systemPrompt = base + block
      }

      /// Strips newline characters from user-supplied free-text before it is
      /// interpolated into the system prompt, preventing multi-line prompt injection.
      private func sanitize(_ text: String) -> String {
          text
              .replacingOccurrences(of: "\n", with: " ")
              .replacingOccurrences(of: "\r", with: " ")
      }

      private func formatWeight(_ kg: Double, units: String) -> String {
          units == "imperial" ? "\(Int(kg * 2.20462)) lbs" : "\(Int(kg)) kg"
      }

      private func formatHeight(_ cm: Double, units: String) -> String {
          if units == "imperial" {
              let inches = Int(cm / 2.54)
              return "\(inches / 12)'\(inches % 12)\""
          }
          return "\(Int(cm)) cm"
      }
  }
