//
//  ExerciseSeeder.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import SwiftData

struct ExerciseSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        guard existing.isEmpty else { return }

        let seeds: [Exercise] = [
            Exercise(name: "Back Squat", muscleGroups: "quads, glutes, hamstrings",
                     equipment: "barbell",
                     instructions: "Bar across upper back, feet shoulder-width. Descend until thighs parallel, drive through heels.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Deadlift", muscleGroups: "hamstrings, glutes, lower back, traps",
                     equipment: "barbell",
                     instructions: "Bar over mid-foot, hinge and grip. Brace core, drive hips forward to stand.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Push-Up", muscleGroups: "chest, triceps, front delts",
                     equipment: "bodyweight",
                     instructions: "High plank, elbows 45°. Lower chest to floor, press to full extension.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Pull-Up", muscleGroups: "lats, biceps, rear delts",
                     equipment: "bodyweight",
                     instructions: "Overhand grip, shoulder-width. Pull chest to bar driving elbows down.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Bench Press", muscleGroups: "chest, triceps, front delts",
                     equipment: "barbell",
                     instructions: "Grip slightly wider than shoulders. Lower bar to mid-chest, press to lockout.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Overhead Press", muscleGroups: "front delts, triceps, upper chest",
                     equipment: "barbell",
                     instructions: "Bar at shoulder height. Press overhead to full arm extension.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Romanian Deadlift", muscleGroups: "hamstrings, glutes",
                     equipment: "barbell",
                     instructions: "Hinge forward with slight knee bend until hamstrings fully stretched. Drive hips forward.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Barbell Row", muscleGroups: "lats, rhomboids, biceps",
                     equipment: "barbell",
                     instructions: "Hinge to horizontal torso. Pull bar to lower chest, elbows back.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Dumbbell Lunges", muscleGroups: "quads, glutes, hamstrings",
                     equipment: "dumbbell",
                     instructions: "Hold dumbbells at sides. Step forward, lower back knee, drive front foot to return.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Plank", muscleGroups: "core, shoulders",
                     equipment: "bodyweight",
                     instructions: "Forearms on floor, body straight head to heels. Brace abs.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Dips", muscleGroups: "triceps, chest, front delts",
                     equipment: "bodyweight",
                     instructions: "Support on parallel bars. Lower until upper arms parallel to floor, press to lockout.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Cable Row", muscleGroups: "lats, rhomboids, biceps",
                     equipment: "cable",
                     instructions: "Feet on platform. Pull handle to abdomen, squeeze shoulder blades.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Lat Pulldown", muscleGroups: "lats, biceps",
                     equipment: "cable",
                     instructions: "Wide grip, sit tall. Pull bar to upper chest driving elbows down.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Leg Press", muscleGroups: "quads, glutes",
                     equipment: "machine",
                     instructions: "Feet hip-width on plate. Lower to 90° knee angle, press to near lockout.",
                     difficulty: "beginner", exerciseType: "strength"),
            Exercise(name: "Kettlebell Swing", muscleGroups: "glutes, hamstrings, core",
                     equipment: "kettlebell",
                     instructions: "Hinge at hips, swing bell back between legs. Drive hips forward to swing to chest height.",
                     difficulty: "intermediate", exerciseType: "strength"),
            Exercise(name: "Burpee", muscleGroups: "full body",
                     equipment: "bodyweight",
                     instructions: "From standing: hands down, jump back to plank, push-up, jump forward, jump up arms overhead.",
                     difficulty: "intermediate", exerciseType: "cardio"),
            Exercise(name: "Jump Rope", muscleGroups: "calves, shoulders, core",
                     equipment: "none",
                     instructions: "Rotate rope with wrists, jump with both feet slightly off ground as rope passes.",
                     difficulty: "beginner", exerciseType: "cardio"),
            Exercise(name: "Cat-Cow", muscleGroups: "spine, core",
                     equipment: "bodyweight",
                     instructions: "On hands and knees, alternate arching spine (cat) and dropping belly (cow). Move with breath.",
                     difficulty: "beginner", exerciseType: "mobility"),
            Exercise(name: "World's Greatest Stretch", muscleGroups: "hip flexors, thoracic spine, hamstrings",
                     equipment: "bodyweight",
                     instructions: "Step into lunge, same-side hand inside foot. Rotate opposite arm to ceiling. Repeat each side.",
                     difficulty: "beginner", exerciseType: "mobility"),
            Exercise(name: "Hip Flexor Stretch", muscleGroups: "hip flexors",
                     equipment: "bodyweight",
                     instructions: "Kneel on one knee. Shift hips forward until stretch at front of back hip. Hold 30–45s each side.",
                     difficulty: "beginner", exerciseType: "flexibility"),
        ]

        for ex in seeds { modelContext.insert(ex) }
    }
}
