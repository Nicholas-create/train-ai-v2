//
//  CurrentInjuriesDetailView.swift
//  train-ai-v2
//

import SwiftUI

// MARK: – Value types

private struct BodyPart {
    let name: String     // Display label shown to the user
    let key: String      // Serialization key used in the stored string
    let hasSide: Bool    // Whether a Left / Right / Both picker is shown
}

private struct InjuryEntry: Equatable {
    var isActive: Bool = false
    var side: String = "Both"      // "Left" | "Right" | "Both"
    var severity: String = "Mild"  // "Mild" | "Moderate" | "Severe"
}

// MARK: – Row subview (extracted so the parent body stays simple)

private struct BodyPartRow: View {
    let part: BodyPart
    @Binding var entry: InjuryEntry
    let sides: [String]
    let severities: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(part.name)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Toggle("", isOn: $entry.isActive)
                    .labelsHidden()
            }
            if entry.isActive {
                if part.hasSide {
                    Picker("Side", selection: $entry.side) {
                        ForEach(sides, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Picker("Severity", selection: $entry.severity) {
                    ForEach(severities, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(AppTheme.card)
        .animation(.easeInOut(duration: 0.2), value: entry.isActive)
    }
}

// MARK: – Main view

struct CurrentInjuriesDetailView: View {
    @Binding var value: String?

    // Parallel array: entries[i] corresponds to bodyParts[i]
    @State private var entries: [InjuryEntry]
    @State private var notes: String = ""

    private static let bodyParts: [BodyPart] = [
        BodyPart(name: "Neck",         key: "Neck",       hasSide: false),
        BodyPart(name: "Shoulder",     key: "Shoulder",   hasSide: true),
        BodyPart(name: "Elbow",        key: "Elbow",      hasSide: true),
        BodyPart(name: "Wrist / Hand", key: "Wrist",      hasSide: true),
        BodyPart(name: "Upper Back",   key: "Upper Back", hasSide: false),
        BodyPart(name: "Lower Back",   key: "Lower Back", hasSide: false),
        BodyPart(name: "Hip",          key: "Hip",        hasSide: true),
        BodyPart(name: "Knee",         key: "Knee",       hasSide: true),
        BodyPart(name: "Ankle / Foot", key: "Ankle",      hasSide: true)
    ]

    private static let sides: [String]      = ["Left", "Both", "Right"]
    private static let severities: [String] = ["Mild", "Moderate", "Severe"]

    init(value: Binding<String?>) {
        self._value = value
        self._entries = State(initialValue: Array(
            repeating: InjuryEntry(),
            count: Self.bodyParts.count
        ))
    }

    var body: some View {
        Form {
            Section("Affected Areas") {
                ForEach(Self.bodyParts.indices, id: \.self) { idx in
                    BodyPartRow(
                        part: Self.bodyParts[idx],
                        entry: $entries[idx],
                        sides: Self.sides,
                        severities: Self.severities
                    )
                }
            }
            Section("Notes") {
                TextField(
                    "E.g. post-ACL surgery, cleared for swimming…",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .foregroundStyle(AppTheme.primaryText)
                .listRowBackground(AppTheme.card)
            }
        }
        .navigationTitle("Current Injuries")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .onAppear { parseFromString() }
        .onChange(of: entries) { serializeToString() }
        .onChange(of: notes) { serializeToString() }
    }

    // MARK: – Parse

    private func parseFromString() {
        guard let v = value, !v.isEmpty else { return }

        let topParts = v.components(separatedBy: " || Notes: ")
        let tokens = topParts[0]
            .components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var parsedAny = false

        for token in tokens {
            guard let openParen = token.lastIndex(of: "("),
                  let closeParen = token.lastIndex(of: ")"),
                  openParen < closeParen else { continue }

            let severityCandidate = String(token[token.index(after: openParen)..<closeParen])
            guard Self.severities.contains(severityCandidate) else { continue }

            let prefix = String(token[token.startIndex..<openParen])
                .trimmingCharacters(in: .whitespaces)

            var side = "Both"
            var bodyPartKey = prefix
            for s in ["Left", "Right", "Both"] where prefix.hasPrefix(s + " ") {
                side = s
                bodyPartKey = String(prefix.dropFirst(s.count + 1))
                break
            }

            if let idx = Self.bodyParts.firstIndex(where: { $0.key == bodyPartKey }) {
                entries[idx] = InjuryEntry(isActive: true, side: side, severity: severityCandidate)
                parsedAny = true
            }
        }

        if !parsedAny && !tokens.isEmpty {
            notes = v
        } else {
            notes = topParts.count > 1 ? topParts[1] : ""
        }
    }

    // MARK: – Serialize

    private func serializeToString() {
        let active = Self.bodyParts.indices.compactMap { idx -> String? in
            let part = Self.bodyParts[idx]
            let entry = entries[idx]
            guard entry.isActive else { return nil }
            return part.hasSide
                ? "\(entry.side) \(part.key) (\(entry.severity))"
                : "\(part.key) (\(entry.severity))"
        }.joined(separator: ", ")

        let result: String
        if active.isEmpty && notes.isEmpty {
            result = ""
        } else if active.isEmpty {
            result = "|| Notes: \(notes)"
        } else if notes.isEmpty {
            result = active
        } else {
            result = "\(active) || Notes: \(notes)"
        }
        value = result.isEmpty ? nil : result
    }
}
