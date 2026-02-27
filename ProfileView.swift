//
//  ProfileView.swift
//  train-ai-v2
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app_units") private var units: String = "metric"
    @Bindable var profile: UserProfile
    @State private var showingHeightPicker = false
    @State private var showingStartWeightPicker = false
    @State private var showingCurrentWeightPicker = false
    @State private var showingGoalWeightPicker = false
    @State private var showingBodyFatPicker     = false
    @State private var showingWaistPicker       = false
    @State private var showingHipsPicker        = false
    @State private var showingChestPicker       = false
    @State private var showingLeftArmPicker     = false
    @State private var showingRightArmPicker    = false
    @State private var showingLeftThighPicker   = false
    @State private var showingRightThighPicker  = false
    @State private var showingDaysPerWeekPicker = false
    @State private var showingSessionLengthPicker = false
    @State private var showingSleepPicker = false
    @State private var showingStressPicker = false
    @FocusState private var focusedField: ProfileField?

    private enum ProfileField {
        case name, email, motivation
        case dietaryPreferences, foodAllergies
    }

    // MARK: – Derived text

    private var initials: String {
        let words = profile.name.split(separator: " ")
        return words.prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    private func isGoalSelected(_ goal: String) -> Bool {
        guard let raw = profile.primaryGoal else { return false }
        return raw.split(separator: ",").map(String.init).contains(goal)
    }

    private func toggleGoal(_ goal: String) {
        var goals = Set((profile.primaryGoal ?? "")
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty })
        if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
        profile.primaryGoal = goals.isEmpty ? nil : goals.sorted().joined(separator: ",")
    }

    private var medicalConditionsSummary: String {
        guard let v = profile.medicalConditions, !v.isEmpty else { return "" }
        let conditionsPart = v.components(separatedBy: " || Notes: ").first ?? v
        let items = conditionsPart.components(separatedBy: ", ").filter { !$0.isEmpty }
        if items.isEmpty { return "Notes added" }
        return items.count == 1 ? items[0] : "\(items.count) conditions"
    }

    private var currentInjuriesSummary: String {
        guard let v = profile.currentInjuries, !v.isEmpty else { return "" }
        let injuriesPart = v.components(separatedBy: " || Notes: ").first ?? v
        let items = injuriesPart.components(separatedBy: ", ").filter { !$0.isEmpty }
        if items.isEmpty { return "Notes added" }
        return items.count == 1 ? items[0] : "\(items.count) injuries"
    }

    private var medicationsSummary: String {
        guard let v = profile.medications, !v.isEmpty else { return "" }
        let medPart = v.components(separatedBy: " || Notes: ").first ?? v
        let items = medPart.components(separatedBy: ", ").filter { !$0.isEmpty }
        if items.isEmpty { return "Notes added" }
        if items.count == 1 {
            if let parenRange = items[0].range(of: " (") {
                return String(items[0][items[0].startIndex..<parenRange.lowerBound])
            }
            return items[0]
        }
        return "\(items.count) medications"
    }

    // MARK: – Unit helpers (display only; values always stored in metric)

    private func displayWeight(_ kg: Double) -> String {
        units == "imperial" ? "\(Int(kg * 2.20462)) lbs" : "\(Int(kg)) kg"
    }

    private func displayLength(_ cm: Double) -> String {
        units == "imperial" ? "\(String(format: "%.1f", cm / 2.54)) in" : "\(Int(cm)) cm"
    }

    private func displayHeight(_ cm: Double) -> String {
        if units == "imperial" {
            let t = Int(cm / 2.54)
            return "\(t / 12)'\(t % 12)\""
        }
        return "\(Int(cm)) cm"
    }

    // MARK: – Body

    var body: some View {
        NavigationStack {
            List {
                avatarHeader
                identitySection
                bodyStatsSection
                bodyCompositionSection
                goalsSection
                healthExperienceSection
                lifestyleSection
                trainingSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.elevated)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button { focusedField = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }

    // MARK: – Avatar header

    private var avatarHeader: some View {
        Section {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 80, height: 80)
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(profile.name.isEmpty ? "Your Name" : profile.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text(profile.email.isEmpty ? "email@example.com" : profile.email)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: – Identity

    private var identitySection: some View {
        Section("Identity") {
            TextField("Name", text: $profile.name)
                .focused($focusedField, equals: .name)
                .listRowBackground(AppTheme.card)
            TextField("Email", text: $profile.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .email)
                .listRowBackground(AppTheme.card)
        }
    }

    // MARK: – Body Stats

    private var bodyStatsSection: some View {
        Section("Body Stats") {
            // Height
            Button { showingHeightPicker = true } label: {
                HStack {
                    Text("Height").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(displayHeight(profile.heightCm ?? 170)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingHeightPicker) {
                heightPickerSheet
            }

            // Start Weight
            Button { showingStartWeightPicker = true } label: {
                HStack {
                    Text("Start Weight").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(displayWeight(profile.startWeightKg ?? 70)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingStartWeightPicker) {
                startWeightPickerSheet
            }

            // Current Weight
            Button { showingCurrentWeightPicker = true } label: {
                HStack {
                    Text("Current Weight").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(displayWeight(profile.currentWeightKg ?? 70)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingCurrentWeightPicker) {
                currentWeightPickerSheet
            }

            // Goal Weight
            Button { showingGoalWeightPicker = true } label: {
                HStack {
                    Text("Goal Weight").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(displayWeight(profile.goalWeightKg ?? 70)).foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingGoalWeightPicker) {
                goalWeightPickerSheet
            }

            // Date of Birth
            DatePicker(
                "Date of Birth",
                selection: Binding(
                    get: { profile.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date() },
                    set: { profile.dateOfBirth = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .listRowBackground(AppTheme.card)

            // Gender
            Picker("Gender", selection: Binding(
                get: { profile.gender ?? "" },
                set: { profile.gender = $0.isEmpty ? nil : $0 }
            )) {
                Text("Prefer not to say").tag("")
                Text("Male").tag("male")
                Text("Female").tag("female")
                Text("Non-binary").tag("non-binary")
            }
            .pickerStyle(.menu)
            .listRowBackground(AppTheme.card)
        }
    }

    // MARK: – Body Stats picker sheets

    private var heightPickerSheet: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button("Done") { showingHeightPicker = false }.fontWeight(.semibold).padding() }
            Picker("Height", selection: Binding<Int>(
                get: { units == "imperial" ? Int((profile.heightCm ?? 170) / 2.54) : Int(profile.heightCm ?? 170) },
                set: { profile.heightCm = units == "imperial" ? Double($0) * 2.54 : Double($0) }
            )) {
                if units == "imperial" {
                    ForEach(48...96, id: \.self) { i in Text("\(i/12)'\(i%12)\"").tag(i) }
                } else {
                    ForEach(100...250, id: \.self) { i in Text("\(i) cm").tag(i) }
                }
            }
            .pickerStyle(.wheel).padding(.bottom)
        }
        .presentationDetents([.height(280)])
    }

    private var startWeightPickerSheet: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button("Done") { showingStartWeightPicker = false }.fontWeight(.semibold).padding() }
            Picker("Start Weight", selection: Binding<Int>(
                get: { units == "imperial" ? Int((profile.startWeightKg ?? 70) * 2.20462) : Int(profile.startWeightKg ?? 70) },
                set: { profile.startWeightKg = units == "imperial" ? Double($0) / 2.20462 : Double($0) }
            )) {
                if units == "imperial" {
                    ForEach(66...551, id: \.self) { i in Text("\(i) lbs").tag(i) }
                } else {
                    ForEach(30...250, id: \.self) { i in Text("\(i) kg").tag(i) }
                }
            }
            .pickerStyle(.wheel).padding(.bottom)
        }
        .presentationDetents([.height(280)])
    }

    private var currentWeightPickerSheet: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button("Done") { showingCurrentWeightPicker = false }.fontWeight(.semibold).padding() }
            Picker("Current Weight", selection: Binding<Int>(
                get: { units == "imperial" ? Int((profile.currentWeightKg ?? 70) * 2.20462) : Int(profile.currentWeightKg ?? 70) },
                set: { profile.currentWeightKg = units == "imperial" ? Double($0) / 2.20462 : Double($0) }
            )) {
                if units == "imperial" {
                    ForEach(66...551, id: \.self) { i in Text("\(i) lbs").tag(i) }
                } else {
                    ForEach(30...250, id: \.self) { i in Text("\(i) kg").tag(i) }
                }
            }
            .pickerStyle(.wheel).padding(.bottom)
        }
        .presentationDetents([.height(280)])
    }

    private var goalWeightPickerSheet: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button("Done") { showingGoalWeightPicker = false }.fontWeight(.semibold).padding() }
            Picker("Goal Weight", selection: Binding<Int>(
                get: { units == "imperial" ? Int((profile.goalWeightKg ?? 70) * 2.20462) : Int(profile.goalWeightKg ?? 70) },
                set: { profile.goalWeightKg = units == "imperial" ? Double($0) / 2.20462 : Double($0) }
            )) {
                if units == "imperial" {
                    ForEach(66...551, id: \.self) { i in Text("\(i) lbs").tag(i) }
                } else {
                    ForEach(30...250, id: \.self) { i in Text("\(i) kg").tag(i) }
                }
            }
            .pickerStyle(.wheel).padding(.bottom)
        }
        .presentationDetents([.height(280)])
    }

    // MARK: – Body Composition

    private var bodyCompositionSection: some View {
        Section("Body Composition") {
            bodyFatRow
            measurementRow(
                label: "Waist",
                value: profile.waistCm,
                defaultCm: 80,
                showing: $showingWaistPicker,
                assign: { profile.waistCm = $0 }
            )
            .sheet(isPresented: $showingWaistPicker) {
                measurementSheet("Waist", value: profile.waistCm ?? 80, minCm: 50, maxCm: 150, minIn: 20, maxIn: 59, dismiss: { showingWaistPicker = false }) {
                    profile.waistCm = $0
                }
            }
            measurementRow(
                label: "Hips",
                value: profile.hipsCm,
                defaultCm: 90,
                showing: $showingHipsPicker,
                assign: { profile.hipsCm = $0 }
            )
            .sheet(isPresented: $showingHipsPicker) {
                measurementSheet("Hips", value: profile.hipsCm ?? 90, minCm: 50, maxCm: 160, minIn: 20, maxIn: 63, dismiss: { showingHipsPicker = false }) {
                    profile.hipsCm = $0
                }
            }
            measurementRow(
                label: "Chest",
                value: profile.chestCm,
                defaultCm: 95,
                showing: $showingChestPicker,
                assign: { profile.chestCm = $0 }
            )
            .sheet(isPresented: $showingChestPicker) {
                measurementSheet("Chest", value: profile.chestCm ?? 95, minCm: 60, maxCm: 160, minIn: 24, maxIn: 63, dismiss: { showingChestPicker = false }) {
                    profile.chestCm = $0
                }
            }
            measurementRow(
                label: "Left Arm",
                value: profile.leftArmCm,
                defaultCm: 35,
                showing: $showingLeftArmPicker,
                assign: { profile.leftArmCm = $0 }
            )
            .sheet(isPresented: $showingLeftArmPicker) {
                measurementSheet("Left Arm", value: profile.leftArmCm ?? 35, minCm: 20, maxCm: 60, minIn: 8, maxIn: 24, dismiss: { showingLeftArmPicker = false }) {
                    profile.leftArmCm = $0
                }
            }
            measurementRow(
                label: "Right Arm",
                value: profile.rightArmCm,
                defaultCm: 35,
                showing: $showingRightArmPicker,
                assign: { profile.rightArmCm = $0 }
            )
            .sheet(isPresented: $showingRightArmPicker) {
                measurementSheet("Right Arm", value: profile.rightArmCm ?? 35, minCm: 20, maxCm: 60, minIn: 8, maxIn: 24, dismiss: { showingRightArmPicker = false }) {
                    profile.rightArmCm = $0
                }
            }
            measurementRow(
                label: "Left Thigh",
                value: profile.leftThighCm,
                defaultCm: 55,
                showing: $showingLeftThighPicker,
                assign: { profile.leftThighCm = $0 }
            )
            .sheet(isPresented: $showingLeftThighPicker) {
                measurementSheet("Left Thigh", value: profile.leftThighCm ?? 55, minCm: 30, maxCm: 80, minIn: 12, maxIn: 31, dismiss: { showingLeftThighPicker = false }) {
                    profile.leftThighCm = $0
                }
            }
            measurementRow(
                label: "Right Thigh",
                value: profile.rightThighCm,
                defaultCm: 55,
                showing: $showingRightThighPicker,
                assign: { profile.rightThighCm = $0 }
            )
            .sheet(isPresented: $showingRightThighPicker) {
                measurementSheet("Right Thigh", value: profile.rightThighCm ?? 55, minCm: 30, maxCm: 80, minIn: 12, maxIn: 31, dismiss: { showingRightThighPicker = false }) {
                    profile.rightThighCm = $0
                }
            }
        }
    }

    // Body Fat row (percentage – no unit conversion)
    private var bodyFatRow: some View {
        HStack {
            Text("Body Fat").foregroundStyle(AppTheme.primaryText)
            Spacer()
            if profile.bodyFatPercent != nil {
                Button { showingBodyFatPicker = true } label: {
                    Text("\(Int(profile.bodyFatPercent ?? 15))%").foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
            Toggle("", isOn: Binding(
                get: { profile.bodyFatPercent != nil },
                set: { on in
                    if on { profile.bodyFatPercent = 15; showingBodyFatPicker = true }
                    else  { profile.bodyFatPercent = nil }
                }
            ))
            .labelsHidden()
        }
        .listRowBackground(AppTheme.card)
        .sheet(isPresented: $showingBodyFatPicker) {
            VStack(spacing: 0) {
                HStack { Spacer(); Button("Done") { showingBodyFatPicker = false }.fontWeight(.semibold).padding() }
                Picker("Body Fat", selection: Binding<Int>(
                    get: { Int(profile.bodyFatPercent ?? 15) },
                    set: { profile.bodyFatPercent = Double($0) }
                )) {
                    ForEach(3...50, id: \.self) { Text("\($0)%").tag($0) }
                }
                .pickerStyle(.wheel).padding(.bottom)
            }
            .presentationDetents([.height(280)])
        }
    }

    // Generic toggle+picker row for optional circumference measurements
    @ViewBuilder
    private func measurementRow(
        label: String,
        value: Double?,
        defaultCm: Double,
        showing: Binding<Bool>,
        assign: @escaping (Double?) -> Void
    ) -> some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.primaryText)
            Spacer()
            if value != nil {
                Button { showing.wrappedValue = true } label: {
                    Text(displayLength(value ?? defaultCm)).foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
            Toggle("", isOn: Binding(
                get: { value != nil },
                set: { on in
                    if on { assign(defaultCm); showing.wrappedValue = true }
                    else  { assign(nil) }
                }
            ))
            .labelsHidden()
        }
        .listRowBackground(AppTheme.card)
    }

    // Generic picker sheet for a circumference measurement
    private func measurementSheet(
        _ title: String,
        value: Double,
        minCm: Int, maxCm: Int,
        minIn: Int, maxIn: Int,
        dismiss: @escaping () -> Void,
        assign: @escaping (Double) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button("Done", action: dismiss).fontWeight(.semibold).padding() }
            Picker(title, selection: Binding<Int>(
                get: { units == "imperial" ? Int(value / 2.54) : Int(value) },
                set: { assign(units == "imperial" ? Double($0) * 2.54 : Double($0)) }
            )) {
                if units == "imperial" {
                    ForEach(minIn...maxIn, id: \.self) { Text("\($0) in").tag($0) }
                } else {
                    ForEach(minCm...maxCm, id: \.self) { Text("\($0) cm").tag($0) }
                }
            }
            .pickerStyle(.wheel).padding(.bottom)
        }
        .presentationDetents([.height(280)])
    }

    // MARK: – Goals

    private var goalsSection: some View {
        Section("Goals") {
            let allGoals: [(tag: String, label: String)] = [
                ("lose_weight",    "Lose Weight"),
                ("build_muscle",   "Build Muscle"),
                ("endurance",      "Endurance"),
                ("flexibility",    "Flexibility"),
                ("general_health", "General Health"),
                ("sport_specific", "Sport Specific"),
            ]
            ForEach(allGoals, id: \.tag) { goal in
                Button { toggleGoal(goal.tag) } label: {
                    HStack {
                        Text(goal.label).foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if isGoalSelected(goal.tag) {
                            Image(systemName: "checkmark").fontWeight(.semibold)
                        }
                    }
                }
                .listRowBackground(AppTheme.card)
            }

            DatePicker(
                "Deadline",
                selection: Binding(
                    get: { profile.goalDeadline ?? Date() },
                    set: { profile.goalDeadline = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .listRowBackground(AppTheme.card)

            TextField(
                "Why do you want this?",
                text: Binding(
                    get: { profile.motivationNote ?? "" },
                    set: { profile.motivationNote = $0.isEmpty ? nil : $0 }
                ),
                axis: .vertical
            )
            .lineLimit(3...6)
            .focused($focusedField, equals: .motivation)
            .listRowBackground(AppTheme.card)
        }
    }

    // MARK: – Health & Experience

    private var healthExperienceSection: some View {
        Section("Health & Experience") {
            Picker("Experience Level", selection: Binding(
                get: { profile.experienceLevel ?? "" },
                set: { profile.experienceLevel = $0.isEmpty ? nil : $0 }
            )) {
                Text("Select Experience").tag("")
                Text("Beginner").tag("beginner")
                Text("Intermediate").tag("intermediate")
                Text("Advanced").tag("advanced")
            }
            .pickerStyle(.menu)
            .listRowBackground(AppTheme.card)

            Picker("Activity Level", selection: Binding(
                get: { profile.activityLevel ?? "" },
                set: { profile.activityLevel = $0.isEmpty ? nil : $0 }
            )) {
                Text("Select Activity Level").tag("")
                Text("Sedentary").tag("sedentary")
                Text("Lightly Active").tag("lightly_active")
                Text("Moderately Active").tag("moderately_active")
                Text("Very Active").tag("very_active")
                Text("Extremely Active").tag("extremely_active")
            }
            .pickerStyle(.menu)
            .listRowBackground(AppTheme.card)

            NavigationLink {
                MedicalConditionsDetailView(value: $profile.medicalConditions)
            } label: {
                HStack {
                    Text("Medical Conditions").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(medicalConditionsSummary).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
                }
            }
            .listRowBackground(AppTheme.card)

            NavigationLink {
                CurrentInjuriesDetailView(value: $profile.currentInjuries)
            } label: {
                HStack {
                    Text("Current Injuries").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(currentInjuriesSummary).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
                }
            }
            .listRowBackground(AppTheme.card)

            NavigationLink {
                MedicationsDetailView(value: $profile.medications)
            } label: {
                HStack {
                    Text("Medications").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(medicationsSummary).foregroundStyle(AppTheme.secondaryText).lineLimit(1)
                }
            }
            .listRowBackground(AppTheme.card)
        }
    }

    // MARK: – Lifestyle

    private var lifestyleSection: some View {
        Section("Lifestyle") {
            Button { showingSleepPicker = true } label: {
                HStack {
                    Text("Sleep").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(String(format: "%.1f", profile.sleepHoursPerNight ?? 7))h / night")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingSleepPicker) {
                VStack(spacing: 0) {
                    HStack { Spacer(); Button("Done") { showingSleepPicker = false }.fontWeight(.semibold).padding() }
                    Picker("Sleep", selection: Binding(
                        get: { profile.sleepHoursPerNight ?? 7 },
                        set: { profile.sleepHoursPerNight = $0 }
                    )) {
                        ForEach(Array(stride(from: 3.0, through: 12.0, by: 0.5)), id: \.self) { h in
                            Text("\(String(format: "%.1f", h))h").tag(h)
                        }
                    }
                    .pickerStyle(.wheel).padding(.bottom)
                }
                .presentationDetents([.height(280)])
            }

            Button { showingStressPicker = true } label: {
                HStack {
                    Text("Stress Level").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(profile.stressLevel ?? 5) / 10").foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingStressPicker) {
                VStack(spacing: 0) {
                    HStack { Spacer(); Button("Done") { showingStressPicker = false }.fontWeight(.semibold).padding() }
                    Picker("Stress Level", selection: Binding(
                        get: { profile.stressLevel ?? 5 },
                        set: { profile.stressLevel = $0 }
                    )) {
                        ForEach(1...10, id: \.self) { Text("\($0) / 10").tag($0) }
                    }
                    .pickerStyle(.wheel).padding(.bottom)
                }
                .presentationDetents([.height(280)])
            }

            TextField(
                "Dietary Preferences (e.g. vegan, keto)",
                text: Binding(
                    get: { profile.dietaryPreferences ?? "" },
                    set: { profile.dietaryPreferences = $0.isEmpty ? nil : $0 }
                )
            )
            .focused($focusedField, equals: .dietaryPreferences)
            .listRowBackground(AppTheme.card)

            TextField(
                "Food Allergies",
                text: Binding(
                    get: { profile.foodAllergies ?? "" },
                    set: { profile.foodAllergies = $0.isEmpty ? nil : $0 }
                )
            )
            .focused($focusedField, equals: .foodAllergies)
            .listRowBackground(AppTheme.card)
        }
    }

    // MARK: – Training

    private var trainingSection: some View {
        Section("Training") {
            Picker("Location", selection: Binding(
                get: { profile.trainingLocation ?? "" },
                set: { profile.trainingLocation = $0.isEmpty ? nil : $0 }
            )) {
                Text("Select Location").tag("")
                Text("Home").tag("home")
                Text("Gym").tag("gym")
                Text("Outdoors").tag("outdoors")
                Text("Mix").tag("mix")
            }
            .pickerStyle(.menu)
            .listRowBackground(AppTheme.card)

            Button { showingDaysPerWeekPicker = true } label: {
                HStack {
                    Text("Days / Week").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(profile.preferredDaysPerWeek ?? 3) days").foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingDaysPerWeekPicker) {
                VStack(spacing: 0) {
                    HStack { Spacer(); Button("Done") { showingDaysPerWeekPicker = false }.fontWeight(.semibold).padding() }
                    Picker("Days / Week", selection: Binding(
                        get: { profile.preferredDaysPerWeek ?? 3 },
                        set: { profile.preferredDaysPerWeek = $0 }
                    )) {
                        ForEach(1...7, id: \.self) { d in Text("\(d) \(d == 1 ? "day" : "days")").tag(d) }
                    }
                    .pickerStyle(.wheel).padding(.bottom)
                }
                .presentationDetents([.height(280)])
            }

            Button { showingSessionLengthPicker = true } label: {
                HStack {
                    Text("Session Length").foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(profile.preferredSessionMinutes ?? 60) min").foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.card)
            .sheet(isPresented: $showingSessionLengthPicker) {
                VStack(spacing: 0) {
                    HStack { Spacer(); Button("Done") { showingSessionLengthPicker = false }.fontWeight(.semibold).padding() }
                    Picker("Session Length", selection: Binding(
                        get: { profile.preferredSessionMinutes ?? 60 },
                        set: { profile.preferredSessionMinutes = $0 }
                    )) {
                        ForEach([30, 45, 60, 90], id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .pickerStyle(.wheel).padding(.bottom)
                }
                .presentationDetents([.height(280)])
            }

            Picker("Time of Day", selection: Binding(
                get: { profile.preferredTimeOfDay ?? "" },
                set: { profile.preferredTimeOfDay = $0.isEmpty ? nil : $0 }
            )) {
                Text("Select Time").tag("")
                Text("Morning").tag("morning")
                Text("Afternoon").tag("afternoon")
                Text("Evening").tag("evening")
            }
            .pickerStyle(.menu)
            .listRowBackground(AppTheme.card)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    let sample = UserProfile(name: "Nick Sampson", email: "nick@example.com")
    let _ = {
        sample.primaryGoal = "build_muscle"
        sample.currentWeightKg = 82.5
        sample.heightCm = 183
        sample.experienceLevel = "intermediate"
        container.mainContext.insert(sample)
    }()
    ProfileView(profile: sample)
        .modelContainer(container)
}
