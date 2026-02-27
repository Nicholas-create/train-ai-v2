//
//  ChatView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Bindable var chatService: ChatService
    @State private var messageText = ""
    @State private var textEditorHeight: CGFloat = 40
    @State private var containerWidth: CGFloat = 390
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.background,
                    AppTheme.backgroundGradientEnd
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Message area or welcome screen
                if chatService.messages.isEmpty {
                    Spacer()
                    welcomeContent
                    Spacer()
                } else {
                    messageListView
                }

                // Loading / error indicators
                if chatService.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Claude is thinking...")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = chatService.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.errorText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Bottom Input Container
                bottomInputContainer
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Chats")
                            .font(.system(size: 17))
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    chatService.startNewChat()
                } label: {
                    Image(systemName: "plus.message")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatService.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: chatService.messages.count) {
                if let last = chatService.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            // Green Leaf Icon
            Image(systemName: "leaf")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accent)

            // Welcome Text
            Text("How can I help you\ntoday?")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.headlineText)
                .lineSpacing(4)
        }
        .padding(.bottom, 60)
    }

    private var bottomInputContainer: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 0)
                .background(GeometryReader { geo in
                    Color.clear.onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in containerWidth = w }
                })
            // White Container Background
            VStack(spacing: 12) {
                // Top Row: Text Input Field
                HStack {
                    TextEditor(text: $messageText)
                        .frame(height: max(40, min(textEditorHeight, 100)))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .font(.system(size: 17))
                        .onChange(of: messageText) { oldValue, newValue in
                            updateTextEditorHeight()
                        }
                        .overlay(
                            Group {
                                if messageText.isEmpty {
                                    Text(" Chat with Personal AI")
                                        .foregroundColor(AppTheme.placeholderText)
                                        .font(.system(size: 17))
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .leading
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Bottom Row: Buttons
                HStack(spacing: 0) {
                    // Plus Button (Attach)
                    Button(action: {
                        // Attach action
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(AppTheme.subtleText)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.leading, 12)

                    Spacer()

                    // Microphone Button
                    Button(action: {
                        // Microphone action
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(AppTheme.subtleText)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 12)

                    // Send Button (Up Arrow) - Black Circle
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.sendButtonIcon)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(chatService.isLoading ? AppTheme.sendButtonDisabled : AppTheme.sendButton)
                            )
                    }
                    .disabled(chatService.isLoading)
                    .padding(.trailing, 12)
                }
                .padding(.bottom, 12)
            }
            .glassEffect(.regular, in:RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.clear.ignoresSafeArea(edges: .bottom))
        .foregroundStyle(AppTheme.subtleText)
    }

    private func updateTextEditorHeight() {
        let size = CGSize(width: containerWidth - 160, height: .infinity)
        let estimatedSize = NSString(string: messageText).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 17)],
            context: nil
        )

        textEditorHeight = max(40, min(estimatedSize.height + 20, 120))
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatService.send(userText: trimmed, modelContext: modelContext)
        messageText = ""
        textEditorHeight = 40
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        if isUser {
            HStack {
                Spacer(minLength: 60)
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.userBubbleText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppTheme.userBubble)
                            //.shadow(color: AppTheme.shadowSubtle, radius: 4, x: 0, y: 2)
                    )
            }
        } else {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.aiBubbleText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(chatService: ChatService())
    }
    .modelContainer(for: [Conversation.self, SDMessage.self], inMemory: true)
}
