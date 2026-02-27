//
//  MedicalConditionsDetailView.swift
//  train-ai-v2
//

import SwiftUI

struct MedicalConditionsDetailView: View {
    @Binding var value: String?

    @State private var selected: Set<String> = []
    @State private var notes: String = ""

    // PARQ-aligned predefined conditions
    private let conditions: [String] = [
        "High Blood Pressure",
        "Heart Condition",
        "Type 1 Diabetes",
        "Type 2 Diabetes",
        "Asthma",
        "Arthritis",
        "Osteoporosis",
        "Epilepsy",
        "Chronic Back / Spine Condition",
        "Thyroid Condition"
    ]

    var body: some View {
        Form {
            Section("Select all that apply") {
                ForEach(conditions, id: \.self) { condition in
                    conditionRow(condition)
                }
            }
            Section("Other / Additional Notes") {
                TextField(
                    "E.g. controlled hypothyroidism, seasonal allergies…",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .foregroundStyle(AppTheme.primaryText)
                .listRowBackground(AppTheme.card)
            }
        }
        .navigationTitle("Medical Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .onAppear { parseFromString() }
        .onChange(of: selected) { serializeToString() }
        .onChange(of: notes) { serializeToString() }
    }

    // MARK: – Row helper (extracted to reduce type-checker complexity)

    @ViewBuilder
    private func conditionRow(_ condition: String) -> some View {
        Button {
            toggleCondition(condition)
        } label: {
            HStack {
                Text(condition)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                if selected.contains(condition) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(AppTheme.card)
    }

    private func toggleCondition(_ condition: String) {
        if selected.contains(condition) {
            selected.remove(condition)
        } else {
            selected.insert(condition)
        }
    }

    // MARK: – Parse

    private func parseFromString() {
        guard let v = value, !v.isEmpty else { return }
        let parts = v.components(separatedBy: " || Notes: ")
        let tags = parts[0].components(separatedBy: ", ").filter { !$0.isEmpty }
        let recognized = tags.filter { conditions.contains($0) }
        if recognized.isEmpty && !tags.isEmpty {
            notes = v
        } else {
            selected = Set(recognized)
            notes = parts.count > 1 ? parts[1] : ""
        }
    }

    // MARK: – Serialize

    private func serializeToString() {
        let conditionParts = Array(selected).sorted().joined(separator: ", ")
        let result: String
        if conditionParts.isEmpty && notes.isEmpty {
            result = ""
        } else if conditionParts.isEmpty {
            result = "|| Notes: \(notes)"
        } else if notes.isEmpty {
            result = conditionParts
        } else {
            result = "\(conditionParts) || Notes: \(notes)"
        }
        value = result.isEmpty ? nil : result
    }
}
