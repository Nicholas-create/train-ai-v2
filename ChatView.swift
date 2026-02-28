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
    @Query private var profiles: [UserProfile]
    @AppStorage("app_units") private var units: String = "metric"

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
        .onAppear {
            chatService.buildSystemPrompt(profile: profiles.first, units: units)
        }
        .onChange(of: profiles) {
            chatService.buildSystemPrompt(profile: profiles.first, units: units)
        }
        .onChange(of: units) {
            chatService.buildSystemPrompt(profile: profiles.first, units: units)
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
            .onChange(of: chatService.messages.last?.content) {
                if let last = chatService.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
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
        guard trimmed.count <= 4000 else { return }
        chatService.send(userText: trimmed, modelContext: modelContext)
        messageText = ""
        textEditorHeight = 40
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Table Parsing Helpers

enum MessageSegment {
    case text([String])
    case table([[String]])
}

func parseCells(_ line: String) -> [String] {
    var trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("|") { trimmed = String(trimmed.dropFirst()) }
    if trimmed.hasSuffix("|") { trimmed = String(trimmed.dropLast()) }
    return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
}

func isSeparatorRow(_ cells: [String]) -> Bool {
    cells.allSatisfy { cell in
        let stripped = cell.trimmingCharacters(in: CharacterSet(charactersIn: ":-"))
        return stripped.allSatisfy { $0 == "-" } && !cell.isEmpty
    }
}

func parseSegments(_ content: String) -> [MessageSegment] {
    let lines = content.components(separatedBy: "\n")
    var segments: [MessageSegment] = []
    var textBuffer: [String] = []
    var tableBuffer: [String] = []

    func flushText() {
        if !textBuffer.isEmpty {
            segments.append(.text(textBuffer))
            textBuffer = []
        }
    }
    func flushTable() {
        if !tableBuffer.isEmpty {
            let rows = tableBuffer.compactMap { line -> [String]? in
                let cells = parseCells(line)
                return cells.isEmpty ? nil : cells
            }
            let dataRows = rows.filter { !isSeparatorRow($0) }
            if !dataRows.isEmpty {
                segments.append(.table(dataRows))
            }
            tableBuffer = []
        }
    }

    for line in lines {
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
            flushText()
            tableBuffer.append(line)
        } else {
            flushTable()
            textBuffer.append(line)
        }
    }
    flushText()
    flushTable()
    return segments
}

// MARK: - MarkdownTableView

struct MarkdownTableView: View {
    let rows: [[String]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            tableGrid
        }
    }

    private var tableGrid: some View {
        let colCount = rows.map(\.count).max() ?? 1

        return Grid(alignment: .topLeading, horizontalSpacing: 20, verticalSpacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                GridRow {
                    ForEach(0..<colCount, id: \.self) { colIndex in
                        let cell = colIndex < row.count ? row[colIndex] : ""
                        Text(cell.isEmpty ? " " : cell)
                            .font(rowIndex == 0
                                  ? .system(size: 15, weight: .bold)
                                  : .system(size: 15))
                            .foregroundColor(AppTheme.aiBubbleText)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 9)
                            .frame(minWidth: 60, alignment: .leading)
                    }
                }
                if rowIndex < rows.count - 1 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 0.5)
                }
            }
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

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
            let segments = parseSegments(message.content)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    switch segment {
                    case .text(let lines):
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                                if line.hasPrefix("### ") {
                                    Text(line.dropFirst(4))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.aiBubbleText)
                                } else if line.hasPrefix("## ") {
                                    Text(line.dropFirst(3))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(AppTheme.aiBubbleText)
                                } else if line.hasPrefix("# ") {
                                    Text(line.dropFirst(2))
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(AppTheme.aiBubbleText)
                                } else if line.trimmingCharacters(in: .whitespaces) == "---" {
                                    Divider()
                                        .padding(.vertical, 4)
                                } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.aiBubbleText)
                                            .padding(.top, 1)
                                        Text((try? AttributedString(
                                            markdown: String(line.dropFirst(2)),
                                            options: AttributedString.MarkdownParsingOptions(
                                                interpretedSyntax: .inlineOnlyPreservingWhitespace
                                            )
                                        )) ?? AttributedString(String(line.dropFirst(2))))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.aiBubbleText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else if line.first?.isNumber == true,
                                          let dotSpaceRange = line.range(of: ". "),
                                          line[line.startIndex..<dotSpaceRange.lowerBound].allSatisfy({ $0.isNumber }) {
                                    let number = String(line[line.startIndex..<dotSpaceRange.lowerBound]) + "."
                                    let content = String(line[dotSpaceRange.upperBound...])
                                    HStack(alignment: .top, spacing: 6) {
                                        Text(number)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppTheme.aiBubbleText)
                                            .padding(.top, 1)
                                        Text((try? AttributedString(
                                            markdown: content,
                                            options: AttributedString.MarkdownParsingOptions(
                                                interpretedSyntax: .inlineOnlyPreservingWhitespace
                                            )
                                        )) ?? AttributedString(content))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.aiBubbleText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else if line.isEmpty {
                                    Color.clear.frame(height: 6)
                                } else {
                                    Text((try? AttributedString(
                                        markdown: line,
                                        options: AttributedString.MarkdownParsingOptions(
                                            interpretedSyntax: .inlineOnlyPreservingWhitespace
                                        )
                                    )) ?? AttributedString(line))
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.aiBubbleText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    case .table(let rows):
                        MarkdownTableView(rows: rows)
                            .padding(.vertical, 4)
                    }
                }
            }
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
