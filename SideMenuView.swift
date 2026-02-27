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

                Text("Train AI")
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    // ── Nav Items
                    navRow(icon: "sparkle.text.clipboard", label: "Workout Program") {
                        withAnimation { isOpen = false }
                    }
                    
                    navRow(icon: "bubble.left.and.bubble.right", label: "Chats") {
                        withAnimation { isOpen = false }
                    }
                    
                    navRow(icon: "clock", label: "History") { }
                    navRow(icon: "chart.line.uptrend.xyaxis", label: "Progression") { }
                    navRow(icon: "person.crop.circle", label: "Profile") { }
                    
                    // ── Separator

                    Divider()
                          .padding(.horizontal, 24)
                          .padding(.vertical, 20)

                      ScrollView {
                          VStack(alignment: .leading, spacing: 10) {
                              Text("Anthropic API Key")
                                  .font(.system(size: 14, weight: .semibold))
                                  .foregroundStyle(AppTheme.secondaryText)

                              SecureField("sk-ant-...", text: $apiKeyInput)
                                  .font(.system(size: 14))
                                  .padding(10)
                                  .background(
                                      RoundedRectangle(cornerRadius: 10)
                                          .fill(AppTheme.inputFieldBackground)
                                  )
                                  .onAppear {
                                      if KeychainHelper.loadAPIKey() != nil {
                                          apiKeyInput = ""
                                      }
                                  }

                              Button(action: saveAPIKey) {
                                  Text("Save Key")
                                      .font(.system(size: 14, weight: .semibold))
                                      .foregroundStyle(AppTheme.buttonText)
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
                                      .foregroundStyle(status.hasPrefix("Saved") ? AppTheme.successText : AppTheme.errorText)
                              }

                              if KeychainHelper.loadAPIKey() != nil {
                                  Text("Key is saved. Enter a new key to replace it.")
                                      .font(.system(size: 11))
                                      .foregroundStyle(AppTheme.secondaryText)
                              }
                          }
                          .padding(.horizontal, 24)
                          .padding(.bottom, 20)
                      }

                      Spacer()


                }
                .frame(width: 320)
                .background(AppTheme.surface)
                .shadow(color: AppTheme.shadowMedium, radius: 10, x: -5, y: 0)

                Spacer()
            }
        }
    }

    private func navRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
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
