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
    @State private var isSettingsOpen = false
    @State private var isProfileOpen = false
    @Query private var profiles: [UserProfile]
    @State private var navigateToChat = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let sideMenuWidth = min(geo.size.width * 0.82, 380)

            ZStack(alignment: .leading) {
                mainContent
                    .offset(x: isSideMenuOpen ? sideMenuWidth : 0)
                    .zIndex(2)

                if isSideMenuOpen {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { isSideMenuOpen = false }
                        }
                        .offset(x: sideMenuWidth)
                        .zIndex(3)
                }

                if isSideMenuOpen {
                    SideMenuView(isOpen: $isSideMenuOpen, width: sideMenuWidth,
                                 isSettingsOpen: $isSettingsOpen, isProfileOpen: $isProfileOpen)
                        .transition(.identity)
                        .zIndex(1)
                }
            }
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 1.0, blendDuration: 0), value: isSideMenuOpen)
            .sheet(isPresented: $isSettingsOpen) {
                SettingsView()
            }
            .sheet(isPresented: $isProfileOpen) {
                if let profile = profiles.first {
                    ProfileView(profile: profile)
                } else {
                    ProgressView()
                        .onAppear {
                            let p = UserProfile()
                            modelContext.insert(p)
                        }
                }
            }
        }
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
                        VStack {
                            Spacer()
                            Text(searchText.isEmpty ? "No conversations yet" : "No results found")
                                .font(.system(size: 17))
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isSearchFocused = false }
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
                                                .font(.system(size: 16, weight: .regular))
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
                                    .padding(.vertical, 2)
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
                                .focused($isSearchFocused) // <-- ADDED
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))

                        if isSearchFocused {
                            Button {
                                isSearchFocused = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            }
                            .glassEffect(.regular, in: Circle())
                        } else {
                            Button {
                                chatService.startNewChat()
                                navigateToChat = true
                            } label: {
                                Image(systemName: "plus.message")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                            }
                            .glassEffect(.regular, in: Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline) 
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { isSideMenuOpen.toggle() }
                        isSearchFocused = false   // ← ADDED
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
        .modelContainer(for: [Conversation.self, SDMessage.self, UserProfile.self], inMemory: true)
}
