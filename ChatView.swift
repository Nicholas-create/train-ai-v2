//
//  ChatView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var isSideMenuOpen = false
    @State private var textEditorHeight: CGFloat = 40
    @State private var chatService = ChatService()
    @State private var containerWidth: CGFloat = 390

    var body: some View {
        ZStack(alignment: .leading) {
            // Main Chat View
            mainChatView
                .offset(x: isSideMenuOpen ? 270 : 0)
                .animation(.easeInOut(duration: 0.3), value: isSideMenuOpen)

            // Side Menu
            if isSideMenuOpen {
                SideMenuView(isOpen: $isSideMenuOpen)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var mainChatView: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.92),
                    Color(red: 0.97, green: 0.95, blue: 0.93)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                topNavigationBar

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
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = chatService.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
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

    private var topNavigationBar: some View {
        HStack {
            // Hamburger Menu Button
            Button(action: {
                withAnimation {
                    isSideMenuOpen.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
            }

            Spacer()

            // Profile Icon
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(
                    Text("F")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            // Green Leaf Icon
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            // Welcome Text
            Text("How can I help you\nthis evening?")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.85))
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
                                    Text("Chat with Personal AI")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.system(size: 17))
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
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
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.leading, 12)

                    Spacer()

                    // Microphone Button
                    Button(action: {
                        // Microphone action
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(width: 44, height: 44)
                    }

                    // Send Button (Up Arrow) - Black Circle
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(chatService.isLoading ? Color.gray : Color.black)
                            )
                    }
                    .disabled(chatService.isLoading)
                    .padding(.trailing, 12)
                }
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(
            Color(red: 0.96, green: 0.94, blue: 0.92)
                .ignoresSafeArea(edges: .bottom)
        )
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
        chatService.send(userText: trimmed)
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
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isUser ? Color.black : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                )

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView()
}
