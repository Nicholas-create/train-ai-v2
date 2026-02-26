//
//  AppTheme.swift
//  train-ai-v2
//
//  Created by Nicholas on 25/02/2026.
//

import SwiftUI

struct AppTheme {
    // MARK: - Backgrounds
    static let background = Color(red: 0.96, green: 0.94, blue: 0.92)
    static let backgroundGradientEnd = Color(red: 0.97, green: 0.95, blue: 0.93)
    static let surface = Color.white

    // MARK: - Accent (change this to retheme the whole app)
    static let accent = Color(red: 0.18, green: 0.55, blue: 0.34)

    // MARK: - Message Bubbles
    static let userBubble = Color(red: 0.87, green: 0.84, blue: 0.79)
    static let userBubbleText = Color(red: 0.15, green: 0.13, blue: 0.12)
    static let aiBubbleText = Color.primary

    // MARK: - Buttons
    static let sendButton = Color.black
    static let sendButtonDisabled = Color.gray
    static let sendButtonIcon = Color.white
    static let buttonBackground = Color.black
    static let buttonText = Color.white

    // MARK: - Text
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let subtleText = Color.primary.opacity(0.6)
    static let headlineText = Color.primary.opacity(0.85)
    static let placeholderText = Color.gray.opacity(0.5)
    static let errorText = Color.red
    static let successText = Color(red: 0.18, green: 0.55, blue: 0.34)

    // MARK: - Shadows
    static let shadowLight = Color.black.opacity(0.08)
    static let shadowMedium = Color.black.opacity(0.2)
    static let shadowSubtle = Color.black.opacity(0.06)

    // MARK: - Overlays & Fields
    static let dimOverlay = Color.black.opacity(0.3)
    static let inputFieldBackground = Color(UIColor.systemGray6)
}
