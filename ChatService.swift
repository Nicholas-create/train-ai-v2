//
//  ChatService.swift
//  train-ai-v2
//
//  Created by Nicholas on 25/02/2026.
//

import Foundation
import Observation

@Observable
final class ChatService {
    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func send(userText: String) {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            errorMessage = "No API key found. Add your Anthropic key in the side menu."
            return
        }

        errorMessage = nil
        messages.append(ChatMessage(role: "user", content: userText))
        isLoading = true

        Task {
            await callAnthropicAPI(apiKey: apiKey)
        }
    }

    private func callAnthropicAPI(apiKey: String) async {
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

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
                await MainActor.run {
                    errorMessage = "API error (\(httpResponse.statusCode)): \(raw)"
                    isLoading = false
                }
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentArray = json["content"] as? [[String: Any]],
                  let firstContent = contentArray.first,
                  let text = firstContent["text"] as? String else {
                await MainActor.run {
                    errorMessage = "Unexpected response format from API."
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                messages.append(ChatMessage(role: "assistant", content: text))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Network error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
