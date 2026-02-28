//
//  Exercise.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var muscleGroups: String    // comma-separated, e.g. "quads, glutes"
    var equipment: String       // "barbell" | "dumbbell" | "bodyweight" | etc.
    var instructions: String
    var difficulty: String      // "beginner" | "intermediate" | "advanced"
    var exerciseType: String    // "strength" | "cardio" | "mobility" | "flexibility"
    var notes: String
    var isCustom: Bool          // false = pre-seeded, true = user/AI created
    var createdAt: Date

    init(
        name: String = "",
        muscleGroups: String = "",
        equipment: String = "bodyweight",
        instructions: String = "",
        difficulty: String = "beginner",
        exerciseType: String = "strength",
        notes: String = "",
        isCustom: Bool = false,
        createdAt: Date = Date()
    ) {
        self.name = name; self.muscleGroups = muscleGroups
        self.equipment = equipment; self.instructions = instructions
        self.difficulty = difficulty; self.exerciseType = exerciseType
        self.notes = notes; self.isCustom = isCustom; self.createdAt = createdAt
    }
}
