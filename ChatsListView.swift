//
//  ChatsListView.swift
//  train-ai-v2
//

import SwiftUI
import SwiftData

struct ChatsListView: View {
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    @Environment(\.modelContext) private var modelContext

    @State private var chatService = ChatService()
    @State private var isSideMenuOpen = false
    @State private var navigateToChat = false
    @State private var searchText = ""

    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Main content with NavigationStack
            mainContent
                .offset(x: isSideMenuOpen ? 320 : 0)
                .zIndex(2)

            // Invisible overlay to catch taps when menu is open
            if isSideMenuOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { isSideMenuOpen = false }
                    }
                    .offset(x: 320)
                    .zIndex(3)
            }

            // Side Menu
            if isSideMenuOpen {
                SideMenuView(isOpen: $isSideMenuOpen)
                    .transition(.identity)
                    .zIndex(1)
            }
        }
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 1.0, blendDuration: 0), value: isSideMenuOpen)
    }

    private var mainContent: some View {
        NavigationStack {
            ZStack {
                // Background gradient
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
                    // Chat list
                    if filteredConversations.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "No conversations yet" : "No results found")
                            .font(.system(size: 17))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredConversations) { conversation in
                                Button {
                                    chatService.loadConversation(conversation)
                                    navigateToChat = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(conversation.title)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(AppTheme.primaryText)
                                                .lineLimit(1)
                                            Text(conversation.updatedAt.relativeDescription())
                                                .font(.system(size: 13))
                                                .foregroundColor(AppTheme.secondaryText)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .onDelete(perform: deleteConversations)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }

                    // Bottom bar: search + new chat button
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.secondaryText)
                            TextField("Search chats", text: $searchText)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))

                        Button {
                            chatService.startNewChat()
                            navigateToChat = true
                        } label: {
                            Image(systemName: "plus.message")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.white)
                                .frame(width: 44, height: 44)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .glassEffect(.regular, in: Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { isSideMenuOpen.toggle() }
                    } label: {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToChat) {
                ChatView(chatService: chatService)
            }
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = filteredConversations[index]
            if chatService.currentConversation === conversation {
                chatService.startNewChat()
            }
            modelContext.delete(conversation)
        }
    }
}

// MARK: - Date Extension

extension Date {
    func relativeDescription() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    ChatsListView()
        .modelContainer(for: [Conversation.self, SDMessage.self], inMemory: true)
}
