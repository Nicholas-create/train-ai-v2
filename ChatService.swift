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

    // MARK: - Tool definitions

    static let exerciseTools: [[String: Any]] = [
        [
            "name": "create_exercise",
            "description": "Creates a new custom exercise in the user's library. Only call this when the user explicitly asks to add or create an exercise.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "name":         ["type": "string"],
                    "muscleGroups": ["type": "string", "description": "Comma-separated, e.g. 'quads, glutes'"],
                    "equipment":    ["type": "string", "description": "bodyweight|barbell|dumbbell|cable|machine|kettlebell|resistance band|none"],
                    "instructions": ["type": "string"],
                    "difficulty":   ["type": "string", "enum": ["beginner", "intermediate", "advanced"]],
                    "exerciseType": ["type": "string", "enum": ["strength", "cardio", "mobility", "flexibility"]],
                    "notes":        ["type": "string"]
                ],
                "required": ["name", "muscleGroups", "exerciseType"]
            ]
        ],
        [
            "name": "update_exercise",
            "description": "Updates a custom exercise by name. Cannot modify pre-seeded exercises.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "name":         ["type": "string", "description": "Exact current name of the exercise"],
                    "newName":      ["type": "string"],
                    "muscleGroups": ["type": "string"],
                    "equipment":    ["type": "string"],
                    "instructions": ["type": "string"],
                    "difficulty":   ["type": "string", "enum": ["beginner", "intermediate", "advanced"]],
                    "exerciseType": ["type": "string", "enum": ["strength", "cardio", "mobility", "flexibility"]],
                    "notes":        ["type": "string"]
                ],
                "required": ["name"]
            ]
        ],
        [
            "name": "delete_exercise",
            "description": "Deletes a custom exercise by name. Cannot delete pre-seeded exercises.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "name": ["type": "string"]
                ],
                "required": ["name"]
            ]
        ]
    ]

    // MARK: - Public API

    func send(userText: String, modelContext: ModelContext,
              profile: UserProfile?, units: String, exercises: [Exercise] = []) {
        buildSystemPrompt(profile: profile, units: units, exercises: exercises)

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

    // MARK: - Core API call

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
            "stream": true,
            "messages": messagePayload,
            "tools": Self.exerciseTools
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
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                await MainActor.run {
                    messages.removeLast()
                    errorMessage = "API error (\(httpResponse.statusCode))"
                    isLoading = false
                }
                return
            }

            // Streaming state for tool use detection
            var pendingToolId    = ""
            var pendingToolName  = ""
            var pendingToolInput = ""   // partial JSON accumulates here
            var assistantText   = ""   // text Claude spoke before the tool call

            for try await line in asyncBytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let jsonString = String(line.dropFirst(6))
                guard jsonString != "[DONE]" else { break }

                guard let data = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }

                switch json["type"] as? String ?? "" {

                case "content_block_start":
                    if let block = json["content_block"] as? [String: Any],
                       block["type"] as? String == "tool_use" {
                        pendingToolId    = block["id"]   as? String ?? ""
                        pendingToolName  = block["name"] as? String ?? ""
                        pendingToolInput = ""
                    }

                case "content_block_delta":
                    let delta = json["delta"] as? [String: Any] ?? [:]
                    if let text = delta["text"] as? String {
                        assistantText += text
                        await MainActor.run { messages[messages.count - 1].content += text }
                    } else if let partial = delta["partial_json"] as? String {
                        pendingToolInput += partial
                    }

                case "message_delta":
                    if let delta = json["delta"] as? [String: Any],
                       delta["stop_reason"] as? String == "tool_use",
                       !pendingToolName.isEmpty {
                        await handleToolCall(
                            assistantTextSoFar: assistantText,
                            toolId:             pendingToolId,
                            toolName:           pendingToolName,
                            toolInputJson:      pendingToolInput,
                            apiKey:             apiKey,
                            modelContext:       modelContext
                        )
                    }

                default: break
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

    // MARK: - Tool Use

    private func handleToolCall(
        assistantTextSoFar: String,
        toolId:             String,
        toolName:           String,
        toolInputJson:      String,
        apiKey:             String,
        modelContext:       ModelContext
    ) async {
        guard let inputData = toolInputJson.data(using: .utf8),
              let input = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any]
        else { return }

        let result: String
        switch toolName {
        case "create_exercise": result = await createExercise(from: input, modelContext: modelContext)
        case "update_exercise": result = await updateExercise(from: input, modelContext: modelContext)
        case "delete_exercise": result = await deleteExercise(from: input, modelContext: modelContext)
        default: result = "Unknown tool: \(toolName)"
        }

        // Build the full message payload:
        //   (a) all prior messages minus the empty placeholder
        //   (b) the assistant's turn (text block + tool_use block)
        //   (c) a user turn with the tool_result
        let history = messages.dropLast()
        var payload: [[String: Any]] = history.map {
            ["role": $0.role.rawValue, "content": $0.content]
        }
        var assistantContent: [[String: Any]] = []
        if !assistantTextSoFar.isEmpty {
            assistantContent.append(["type": "text", "text": assistantTextSoFar])
        }
        assistantContent.append(["type": "tool_use", "id": toolId, "name": toolName, "input": input])
        payload.append(["role": "assistant", "content": assistantContent])
        payload.append([
            "role": "user",
            "content": [["type": "tool_result", "tool_use_id": toolId, "content": result]]
        ])

        await resumeAfterToolCall(payload: payload, apiKey: apiKey, modelContext: modelContext)
    }

    private func resumeAfterToolCall(
        payload:      [[String: Any]],
        apiKey:       String,
        modelContext: ModelContext
    ) async {
        var request = URLRequest(url: Self.apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey,       forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        var body: [String: Any] = [
            "model": selectedModel.rawValue,
            "max_tokens": 1024,
            "stream": true,
            "messages": payload,
            "tools": Self.exerciseTools
        ]
        if !systemPrompt.isEmpty { body["system"] = systemPrompt }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = bodyData

        do {
            let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
            for try await line in asyncBytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let js = String(line.dropFirst(6))
                guard js != "[DONE]" else { break }
                if let d = js.data(using: .utf8),
                   let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                   let text = (j["delta"] as? [String: Any])?["text"] as? String {
                    await MainActor.run { messages[messages.count - 1].content += text }
                }
            }
            await MainActor.run {
                isLoading = false
                saveCurrentConversation(modelContext: modelContext)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Connection error after tool execution."
                isLoading = false
            }
        }
    }

    // MARK: - SwiftData Exercise Handlers

    @MainActor
    private func createExercise(from input: [String: Any], modelContext: ModelContext) async -> String {
        let name = (input["name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "Error: exercise name is required." }
        modelContext.insert(Exercise(
            name: name,
            muscleGroups: input["muscleGroups"] as? String ?? "",
            equipment:    input["equipment"]    as? String ?? "bodyweight",
            instructions: input["instructions"] as? String ?? "",
            difficulty:   input["difficulty"]   as? String ?? "beginner",
            exerciseType: input["exerciseType"] as? String ?? "strength",
            notes:        input["notes"]        as? String ?? "",
            isCustom: true
        ))
        return "Exercise '\(name)' added to the library."
    }

    @MainActor
    private func updateExercise(from input: [String: Any], modelContext: ModelContext) async -> String {
        let name = input["name"] as? String ?? ""
        let desc = FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == name })
        guard let ex = try? modelContext.fetch(desc).first else { return "Exercise '\(name)' not found." }
        guard ex.isCustom else { return "'\(name)' is a pre-seeded exercise and cannot be modified." }
        if let v = input["newName"]      as? String { ex.name          = v }
        if let v = input["muscleGroups"] as? String { ex.muscleGroups  = v }
        if let v = input["equipment"]    as? String { ex.equipment     = v }
        if let v = input["instructions"] as? String { ex.instructions  = v }
        if let v = input["difficulty"]   as? String { ex.difficulty    = v }
        if let v = input["exerciseType"] as? String { ex.exerciseType  = v }
        if let v = input["notes"]        as? String { ex.notes         = v }
        return "Exercise '\(name)' updated."
    }

    @MainActor
    private func deleteExercise(from input: [String: Any], modelContext: ModelContext) async -> String {
        let name = input["name"] as? String ?? ""
        let desc = FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == name })
        guard let ex = try? modelContext.fetch(desc).first else { return "Exercise '\(name)' not found." }
        guard ex.isCustom else { return "'\(name)' is a pre-seeded exercise and cannot be deleted." }
        modelContext.delete(ex)
        return "Exercise '\(name)' removed from the library."
    }

    // MARK: - Conversation Management

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

    // MARK: - System Prompt

    func buildSystemPrompt(profile: UserProfile?, units: String, exercises: [Exercise] = []) {
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

        if !exercises.isEmpty {
            var eBlock = "\n\n---\n\n## Exercise Library\n"
            eBlock += "Prefer exercises from this list when suggesting workouts. "
            eBlock += "You have tools to create, update, or delete custom exercises when asked.\n\n"
            let grouped = Dictionary(grouping: exercises, by: { $0.exerciseType })
            for type in ["strength", "cardio", "mobility", "flexibility"] {
                guard let group = grouped[type], !group.isEmpty else { continue }
                eBlock += "**\(type.capitalized):** "
                eBlock += group.sorted { $0.name < $1.name }.map { sanitize($0.name) }.joined(separator: ", ")
                eBlock += "\n"
            }
            block += eBlock
        }

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
        units == "imperial" ? "\(Int((kg * 2.20462).rounded())) lbs" : "\(Int(kg.rounded())) kg"
    }

    private func formatHeight(_ cm: Double, units: String) -> String {
        if units == "imperial" {
            let inches = Int((cm / 2.54).rounded())
            return "\(inches / 12)'\(inches % 12)\""
        }
        return "\(Int(cm.rounded())) cm"
    }
}
