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
                
                Spacer()
                
                // Center Welcome Content
                welcomeContent
                
                Spacer()
                
                // Bottom Input Container
                bottomInputContainer
            }
        }
        .onTapGesture {
            hideKeyboard()
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
                                    .fill(Color.black)
                            )
                    }
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
        let size = CGSize(width: UIScreen.main.bounds.width - 160, height: .infinity)
        let estimatedSize = NSString(string: messageText).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 17)],
            context: nil
        )
        
        textEditorHeight = max(40, min(estimatedSize.height + 20, 120))
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Handle send message
        print("Sending message: \(messageText)")
        
        // Clear the message
        messageText = ""
        textEditorHeight = 40
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ChatView()
}
