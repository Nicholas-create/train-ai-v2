//
//  SettingsView.swift
//  train-ai-v2
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app_color_scheme") private var colorScheme: String = "system"
    @AppStorage("app_units") private var units: String = "metric"

    private var colorSchemeLabel: String {
        switch colorScheme {
        case "light": return "Light"
        case "dark":  return "Dark"
        default:      return "System"
        }
    }
    
    private var colorSchemeIcon: String {
        switch colorScheme {
        case "light": return "sun.max"
        case "dark":  return "moon"
        default:      return "circle.lefthalf.filled"
        }
    }

    private var unitsLabel: String { units == "imperial" ? "Imperial" : "Metric" }

    var body: some View {
        NavigationStack {
            List {
                // ── Section 1: Appearance
                Section("Appearance") {
                    HStack(spacing: 16) {
                        Image(systemName: colorSchemeIcon)
                            .foregroundStyle(Color.gray)
                            .frame(width: 24)
                        Text("Theme")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Menu {
                            Button("System") { colorScheme = "system" }
                            Button("Light")  { colorScheme = "light"  }
                            Button("Dark")   { colorScheme = "dark"   }
                        } label: {
                            HStack(spacing: 4) {
                                Text(colorSchemeLabel)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }

                // ── Section 2: Units
                Section("Units") {
                    HStack(spacing: 16) {
                        Image(systemName: "ruler")
                            .foregroundStyle(Color.gray)
                            .frame(width: 24)
                        Text("Measurement")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Menu {
                            Button("Metric")   { units = "metric"   }
                            Button("Imperial") { units = "imperial" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(unitsLabel)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }

                // ── Section 3: API Key (navigates to sub-page)
                Section("API") {
                    NavigationLink {
                        APIKeyView()
                    } label: {
                        HStack(spacing: 16){
                            Image(systemName: "key.horizontal")
                                .foregroundStyle(Color.gray)
                                .frame(width: 24)
                            Text("Anthropic API Key")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(KeychainHelper.loadAPIKey() != nil ? "Saved" : "Not set")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)        // ← add: hides the default gray system background
            .background(AppTheme.elevated)           // ← add: replaces it with your Elevated color
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }
}

// ── Sub-page: API Key entry ────────────────────────────────────────────────

struct APIKeyView: View {
    @State private var apiKeyInput: String = ""
    @State private var saveStatus: String? = nil

    var body: some View {
        Form {
            Section {
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .onAppear {
                        if KeychainHelper.loadAPIKey() != nil {
                            apiKeyInput = ""
                        }
                    }
            } footer: {
                if KeychainHelper.loadAPIKey() != nil {
                    Text("A key is already saved. Enter a new one to replace it.")
                }
            }

            Section {
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
            }
        }
        .navigationTitle("API Key")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            saveStatus = "Please enter a key."
            return
        }
        // NEW: validate Anthropic key prefix
        guard trimmed.hasPrefix("sk-ant-") else {
            saveStatus = "That doesn't look like an Anthropic key (should start with sk-ant-)."
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
