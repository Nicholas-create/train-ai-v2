//
//  UserProfile.swift
//  train-ai-v2
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    // Identity
    var name: String
    var email: String
    var profilePhotoURL: String?
    var memberSince: Date

    // Body Stats
    var heightCm: Double?
    var startWeightKg: Double?
    var currentWeightKg: Double?
    var goalWeightKg: Double?
    var dateOfBirth: Date?
    var gender: String?           // "male" | "female" | "non-binary" | "prefer_not_to_say"

    // Body Composition
    var waistCm: Double?
    var hipsCm: Double?
    var chestCm: Double?
    var leftArmCm: Double?
    var rightArmCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?
    var bodyFatPercent: Double?

    // Goals
    var primaryGoal: String?      // "lose_weight" | "build_muscle" | "endurance" | etc.
    var goalDeadline: Date?
    var motivationNote: String?

    // Health History
    var experienceLevel: String?  // "beginner" | "intermediate" | "advanced"
    var medicalConditions: String?
    var currentInjuries: String?
    var medications: String?

    // Lifestyle
    var activityLevel: String?    // "sedentary" | "lightly_active" | "moderately_active" | etc.
    var sleepHoursPerNight: Double?
    var stressLevel: Int?         // 1–10
    var dietaryPreferences: String?
    var foodAllergies: String?

    // Training Preferences
    var trainingLocation: String? // "home" | "gym" | "outdoors" | "mix"
    var preferredDaysPerWeek: Int?
    var preferredSessionMinutes: Int?  // 30 | 45 | 60 | 90
    var preferredTimeOfDay: String?    // "morning" | "afternoon" | "evening"

    init(name: String = "", email: String = "",
         profilePhotoURL: String? = nil, memberSince: Date = Date()) {
        self.name = name
        self.email = email
        self.profilePhotoURL = profilePhotoURL
        self.memberSince = memberSince
    }
}
