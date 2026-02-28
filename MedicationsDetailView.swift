//
//  MedicationsDetailView.swift
//  train-ai-v2
//

import SwiftUI

// MARK: – Value type

private struct MedicationEntry: Identifiable, Equatable {
    let id: UUID
    var nameAndDose: String
    var frequency: String

    init(nameAndDose: String = "", frequency: String = "Daily") {
        self.id = UUID()
        self.nameAndDose = nameAndDose
        self.frequency = frequency
    }
}

// MARK: – Row subview (extracted so the parent body stays simple)

private struct MedicationEntryRow: View {
    @Binding var entry: MedicationEntry
    let frequencies: [String]
    @FocusState.Binding var focusedID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                "",
                text: $entry.nameAndDose,
                prompt: Text("Name and dose (e.g. Metformin 500mg)")
                    .foregroundStyle(AppTheme.secondaryText)
            )
            .focused($focusedID, equals: entry.id)
            .foregroundStyle(AppTheme.primaryText)

            Picker("Frequency", selection: $entry.frequency) {
                ForEach(frequencies, id: \.self) { freq in
                    Text(freq).tag(freq)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.secondaryText)
        }
        .padding(.vertical, 4)
        .listRowBackground(AppTheme.card)
    }
}

// MARK: – Main view

struct MedicationsDetailView: View {
    @Binding var value: String?

    @State private var entries: [MedicationEntry] = []
    @State private var notes: String = ""
    @FocusState private var focusedEntry: UUID?

    private static let frequencies = [
        "Daily", "Twice Daily", "Three Times Daily",
        "Every Other Day", "Weekly", "As Needed"
    ]

    var body: some View {
        Form {
            Section {
                ForEach(entries.indices, id: \.self) { idx in
                    MedicationEntryRow(
                        entry: $entries[idx],
                        frequencies: Self.frequencies,
                        focusedID: $focusedEntry
                    )
                }
                .onDelete { indexSet in
                    entries.remove(atOffsets: indexSet)
                }

                Button {
                    let newEntry = MedicationEntry()
                    entries.append(newEntry)
                    focusedEntry = newEntry.id
                } label: {
                    Label("Add Medication", systemImage: "plus.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }
                .listRowBackground(AppTheme.card)

            } header: {
                Text("Medications")
            } footer: {
                Text("Include name and dose, e.g. \u{201C}Metformin 500mg\u{201D}. Your AI trainer uses this to tailor workout intensity, timing, and recovery advice.")
            }

            Section("Additional Notes") {
                TextField(
                    "E.g. recently started, waiting for dosage review\u{2026}",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .foregroundStyle(AppTheme.primaryText)
                .listRowBackground(AppTheme.card)
            }
        }
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .onAppear { parseFromString() }
        .onChange(of: entries) { serializeToString() }
        .onChange(of: notes)   { serializeToString() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focusedEntry = nil
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
    }

    // MARK: – Serialize

    private func serializeToString() {
        let validEntries = entries.filter {
            !$0.nameAndDose.trimmingCharacters(in: .whitespaces).isEmpty
        }
        let medParts = validEntries
            .map { "\($0.nameAndDose.trimmingCharacters(in: .whitespaces)) (\($0.frequency))" }
            .joined(separator: ", ")

        let result: String
        if medParts.isEmpty && notes.isEmpty {
            result = ""
        } else if medParts.isEmpty {
            result = "|| Notes: \(notes)"
        } else if notes.isEmpty {
            result = medParts
        } else {
            result = "\(medParts) || Notes: \(notes)"
        }
        value = result.isEmpty ? nil : result
    }

    // MARK: – Parse

    private func parseFromString() {
        guard let v = value, !v.isEmpty else { return }

        let topParts = v.components(separatedBy: " || Notes: ")
        notes = topParts.count > 1 ? topParts[1] : ""

        let tokens = topParts[0]
            .components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        entries = tokens.compactMap { token -> MedicationEntry? in
            guard let openParen = token.lastIndex(of: "("),
                  let closeParen = token.lastIndex(of: ")"),
                  openParen < closeParen else {
                return MedicationEntry(nameAndDose: token, frequency: "Daily")
            }
            let frequency = String(token[token.index(after: openParen)..<closeParen])
            let nameAndDose = String(token[token.startIndex..<openParen])
                .trimmingCharacters(in: .whitespaces)
            return nameAndDose.isEmpty ? nil : MedicationEntry(nameAndDose: nameAndDose, frequency: frequency)
        }
    }
}
