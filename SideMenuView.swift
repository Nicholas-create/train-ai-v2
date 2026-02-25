//
//  SideMenuView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isOpen: Bool
    @State private var apiKeyInput: String = ""
    @State private var saveStatus: String? = nil

    var body: some View {
        ZStack {
            // Dimmed Background
            AppTheme.dimOverlay
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isOpen = false
                    }
                }

            // Side Menu Content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Menu Header
                    HStack {
                        Text("Menu")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryText)

                        Spacer()

                        Button(action: {
                            withAnimation {
                                isOpen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.primaryText)
                        }
                    }
                    .padding()
                    .background(AppTheme.surface)

                    // Menu Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // API Key Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Anthropic API Key")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)

                                SecureField("sk-ant-...", text: $apiKeyInput)
                                    .font(.system(size: 14))
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.inputFieldBackground)
                                    )
                                    .onAppear {
                                        // Pre-fill with placeholder if key already saved
                                        if KeychainHelper.loadAPIKey() != nil {
                                            apiKeyInput = ""
                                        }
                                    }

                                Button(action: saveAPIKey) {
                                    Text("Save Key")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.buttonText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(AppTheme.buttonBackground)
                                        )
                                }

                                if let status = saveStatus {
                                    Text(status)
                                        .font(.system(size: 12))
                                        .foregroundColor(status.hasPrefix("Saved") ? AppTheme.successText : AppTheme.errorText)
                                }

                                if KeychainHelper.loadAPIKey() != nil {
                                    Text("Key is saved. Enter a new key to replace it.")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                        }
                        .padding()
                    }

                    Spacer()
                }
                .frame(width: 320)
                .background(AppTheme.surface)
                .shadow(color: AppTheme.shadowMedium, radius: 10, x: 5, y: 0)

                Spacer()
            }
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            saveStatus = "Please enter a key."
            return
        }
        let success = KeychainHelper.saveAPIKey(trimmed)
        saveStatus = success ? "Saved successfully." : "Failed to save key."
        if success {
            apiKeyInput = ""
        }
    }
}

#Preview {
    SideMenuView(isOpen: .constant(true))
}
