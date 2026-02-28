//
//  AddExerciseView.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroups = ""
    @State private var equipment = "bodyweight"
    @State private var instructions = ""
    @State private var difficulty = "beginner"
    @State private var exerciseType = "strength"
    @State private var notes = ""

    private let equipmentOptions = ["bodyweight", "barbell", "dumbbell", "cable", "machine", "kettlebell", "resistance band", "none"]
    private let difficultyOptions = ["beginner", "intermediate", "advanced"]
    private let typeOptions = ["strength", "cardio", "mobility", "flexibility"]
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !muscleGroups.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.background, AppTheme.backgroundGradientEnd],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise Info section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Exercise Info")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.bottom, 8)
                            VStack(spacing: 0) {
                                TextField("Name (e.g. Bulgarian Split Squat)", text: $name)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .padding(16)
                                Divider().background(AppTheme.secondaryText.opacity(0.2))
                                TextField("Muscle groups (e.g. quads, glutes)", text: $muscleGroups)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .padding(16)
                            }
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Details section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Details")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.bottom, 8)
                            VStack(spacing: 0) {
                                Picker("Equipment", selection: $equipment) {
                                    ForEach(equipmentOptions, id: \.self) { Text($0.capitalized) }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                Divider().background(AppTheme.secondaryText.opacity(0.2))
                                Picker("Difficulty", selection: $difficulty) {
                                    ForEach(difficultyOptions, id: \.self) { Text($0.capitalized) }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                Divider().background(AppTheme.secondaryText.opacity(0.2))
                                Picker("Type", selection: $exerciseType) {
                                    ForEach(typeOptions, id: \.self) { Text($0.capitalized) }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                            }
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Instructions section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Instructions")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.bottom, 8)
                            TextEditor(text: $instructions)
                                .foregroundStyle(AppTheme.primaryText)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 100)
                                .padding(16)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Notes section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Notes (optional)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.bottom, 8)
                            TextEditor(text: $notes)
                                .foregroundStyle(AppTheme.primaryText)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 60)
                                .padding(16)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Exercise").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        modelContext.insert(Exercise(
                            name: name.trimmingCharacters(in: .whitespaces),
                            muscleGroups: muscleGroups.trimmingCharacters(in: .whitespaces),
                            equipment: equipment,
                            instructions: instructions.trimmingCharacters(in: .whitespaces),
                            difficulty: difficulty,
                            exerciseType: exerciseType,
                            notes: notes.trimmingCharacters(in: .whitespaces),
                            isCustom: true
                        ))
                        dismiss()
                    }
                    .disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
    }
}
