//
//  SettingsView.swift
//  train-ai-v2
//

import SwiftUI

struct SettingsView: View {
    // Stored in UserDefaults via @AppStorage
    @AppStorage("app_color_scheme") private var colorScheme: String = "system"
    @AppStorage("app_units") private var units: String = "metric"

    // Keychain API key — same pattern as SideMenuView used to have
    @State private var apiKeyInput: String = ""
    @State private var saveStatus: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                // ── Section 1: Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $colorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                // ── Section 2: Units
                Section("Units") {
                    Picker("Measurement", selection: $units) {
                        Text("Metric").tag("metric")
                        Text("Imperial").tag("imperial")
                    }
                    .pickerStyle(.segmented)
                }

                // ── Section 3: API Key (moved from SideMenuView)
                Section("Anthropic API Key") {
                    SecureField("sk-ant-...", text: $apiKeyInput)
                        .onAppear {
                            if KeychainHelper.loadAPIKey() != nil {
                                apiKeyInput = ""
                            }
                        }

                    Button(action: saveAPIKey) {
                        Text("Save Key")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.buttonBackground)

                    if let status = saveStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(
                                status.hasPrefix("Saved")
                                    ? AppTheme.successText
                                    : AppTheme.errorText
                            )
                    }

                    if KeychainHelper.loadAPIKey() != nil {
                        Text("Key is saved. Enter a new key to replace it.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
        if success { apiKeyInput = "" }
    }
}

#Preview {
    SettingsView()
}
