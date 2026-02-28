//
//  ExerciseDetailView.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.background, AppTheme.backgroundGradientEnd],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Badges row
                    HStack(spacing: 8) {
                        ExBadge(exercise.exerciseType.capitalized, color: typeColor)
                        ExBadge(exercise.difficulty.capitalized, color: diffColor)
                        if exercise.isCustom { ExBadge("Custom", color: AppTheme.accent) }
                    }
                    ExDetailSection("Muscle Groups") { Text(exercise.muscleGroups.capitalized) }
                    ExDetailSection("Equipment")    { Text(exercise.equipment.capitalized) }
                    ExDetailSection("Instructions") { Text(exercise.instructions).lineSpacing(4) }
                    if !exercise.notes.isEmpty {
                        ExDetailSection("Notes") {
                            Text(exercise.notes).foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var typeColor: Color {
        switch exercise.exerciseType {
        case "strength": return .blue
        case "cardio": return .orange
        case "mobility": return .green
        case "flexibility": return .purple
        default: return .gray
        }
    }

    private var diffColor: Color {
        switch exercise.difficulty {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

struct ExBadge: View {
    let text: String
    let color: Color
    init(_ text: String, color: Color) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4).background(color).clipShape(Capsule())
    }
}

struct ExDetailSection<C: View>: View {
    let title: String
    let content: C
    init(_ title: String, @ViewBuilder content: () -> C) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText).textCase(.uppercase).tracking(0.5)
            content.font(.system(size: 16)).foregroundStyle(AppTheme.primaryText)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
