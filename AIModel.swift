//
//  AIModel.swift
//  train-ai-v2
//
//  Created by Nicholas on 25/02/2026.
//

// Change .sonnet to .haiku or .opus to switch models
let selectedModel: AIModel = .sonnet

enum AIModel: String {
    case haiku  = "claude-haiku-4-5-20251001"  // fastest / cheapest
    case sonnet = "claude-sonnet-4-6"           // balanced (default)
    case opus   = "claude-opus-4-6"             // most powerful
}
