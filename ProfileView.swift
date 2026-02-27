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

    var body: some View {
        NavigationStack {
            List {

                // ── Avatar Header ─────────────────────────────────────────
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

                // ── Identity ──────────────────────────────────────────────
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

                // ── Body Stats ────────────────────────────────────────────
                Section("Body Stats") {
                    Button {
                        showingHeightPicker = true
                    } label: {
                        HStack {
                            Text("Height")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(Int(profile.heightCm ?? 170)) cm")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingHeightPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingHeightPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Height", selection: Binding(
                                get: { Int(profile.heightCm ?? 170) },
                                set: { profile.heightCm = Double($0) }
                            )) {
                                ForEach(100...250, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    Button {
                        showingStartWeightPicker = true
                    } label: {
                        HStack {
                            Text("Start Weight")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(Int(profile.startWeightKg ?? 70)) kg")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingStartWeightPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingStartWeightPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Start Weight", selection: Binding(
                                get: { Int(profile.startWeightKg ?? 70) },
                                set: { profile.startWeightKg = Double($0) }
                            )) {
                                ForEach(30...250, id: \.self) { kg in
                                    Text("\(kg) kg").tag(kg)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    Button {
                        showingCurrentWeightPicker = true
                    } label: {
                        HStack {
                            Text("Current Weight")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(Int(profile.currentWeightKg ?? 70)) kg")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingCurrentWeightPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingCurrentWeightPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Current Weight", selection: Binding(
                                get: { Int(profile.currentWeightKg ?? 70) },
                                set: { profile.currentWeightKg = Double($0) }
                            )) {
                                ForEach(30...250, id: \.self) { kg in
                                    Text("\(kg) kg").tag(kg)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    Button {
                        showingGoalWeightPicker = true
                    } label: {
                        HStack {
                            Text("Goal Weight")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(Int(profile.goalWeightKg ?? 70)) kg")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingGoalWeightPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingGoalWeightPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Goal Weight", selection: Binding(
                                get: { Int(profile.goalWeightKg ?? 70) },
                                set: { profile.goalWeightKg = Double($0) }
                            )) {
                                ForEach(30...250, id: \.self) { kg in
                                    Text("\(kg) kg").tag(kg)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    DatePicker(
                        "Date of Birth",
                        selection: Binding(
                            get: { profile.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -25, to: Date())! },
                            set: { profile.dateOfBirth = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .listRowBackground(AppTheme.card)

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

                // ── Body Composition ──────────────────────────────────────
                Section("Body Composition") {

                    // Body Fat
                    HStack {
                        Text("Body Fat")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.bodyFatPercent != nil {
                            Button { showingBodyFatPicker = true } label: {
                                Text("\(Int(profile.bodyFatPercent ?? 15))%")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.bodyFatPercent != nil },
                            set: { on in
                                if on {
                                    profile.bodyFatPercent = 15
                                    showingBodyFatPicker = true
                                } else {
                                    profile.bodyFatPercent = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingBodyFatPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingBodyFatPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Body Fat", selection: Binding(
                                get: { Int(profile.bodyFatPercent ?? 15) },
                                set: { profile.bodyFatPercent = Double($0) }
                            )) {
                                ForEach(3...50, id: \.self) { pct in
                                    Text("\(pct)%").tag(pct)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Waist
                    HStack {
                        Text("Waist")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.waistCm != nil {
                            Button { showingWaistPicker = true } label: {
                                Text("\(Int(profile.waistCm ?? 80)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.waistCm != nil },
                            set: { on in
                                if on {
                                    profile.waistCm = 80
                                    showingWaistPicker = true
                                } else {
                                    profile.waistCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingWaistPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingWaistPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Waist", selection: Binding(
                                get: { Int(profile.waistCm ?? 80) },
                                set: { profile.waistCm = Double($0) }
                            )) {
                                ForEach(50...150, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Hips
                    HStack {
                        Text("Hips")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.hipsCm != nil {
                            Button { showingHipsPicker = true } label: {
                                Text("\(Int(profile.hipsCm ?? 90)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.hipsCm != nil },
                            set: { on in
                                if on {
                                    profile.hipsCm = 90
                                    showingHipsPicker = true
                                } else {
                                    profile.hipsCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingHipsPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingHipsPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Hips", selection: Binding(
                                get: { Int(profile.hipsCm ?? 90) },
                                set: { profile.hipsCm = Double($0) }
                            )) {
                                ForEach(50...160, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Chest
                    HStack {
                        Text("Chest")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.chestCm != nil {
                            Button { showingChestPicker = true } label: {
                                Text("\(Int(profile.chestCm ?? 95)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.chestCm != nil },
                            set: { on in
                                if on {
                                    profile.chestCm = 95
                                    showingChestPicker = true
                                } else {
                                    profile.chestCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingChestPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingChestPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Chest", selection: Binding(
                                get: { Int(profile.chestCm ?? 95) },
                                set: { profile.chestCm = Double($0) }
                            )) {
                                ForEach(60...160, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Left Arm
                    HStack {
                        Text("Left Arm")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.leftArmCm != nil {
                            Button { showingLeftArmPicker = true } label: {
                                Text("\(Int(profile.leftArmCm ?? 35)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.leftArmCm != nil },
                            set: { on in
                                if on {
                                    profile.leftArmCm = 35
                                    showingLeftArmPicker = true
                                } else {
                                    profile.leftArmCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingLeftArmPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingLeftArmPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Left Arm", selection: Binding(
                                get: { Int(profile.leftArmCm ?? 35) },
                                set: { profile.leftArmCm = Double($0) }
                            )) {
                                ForEach(20...60, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Right Arm
                    HStack {
                        Text("Right Arm")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.rightArmCm != nil {
                            Button { showingRightArmPicker = true } label: {
                                Text("\(Int(profile.rightArmCm ?? 35)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.rightArmCm != nil },
                            set: { on in
                                if on {
                                    profile.rightArmCm = 35
                                    showingRightArmPicker = true
                                } else {
                                    profile.rightArmCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingRightArmPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingRightArmPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Right Arm", selection: Binding(
                                get: { Int(profile.rightArmCm ?? 35) },
                                set: { profile.rightArmCm = Double($0) }
                            )) {
                                ForEach(20...60, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Left Thigh
                    HStack {
                        Text("Left Thigh")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.leftThighCm != nil {
                            Button { showingLeftThighPicker = true } label: {
                                Text("\(Int(profile.leftThighCm ?? 55)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.leftThighCm != nil },
                            set: { on in
                                if on {
                                    profile.leftThighCm = 55
                                    showingLeftThighPicker = true
                                } else {
                                    profile.leftThighCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingLeftThighPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingLeftThighPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Left Thigh", selection: Binding(
                                get: { Int(profile.leftThighCm ?? 55) },
                                set: { profile.leftThighCm = Double($0) }
                            )) {
                                ForEach(30...80, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    // Right Thigh
                    HStack {
                        Text("Right Thigh")
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        if profile.rightThighCm != nil {
                            Button { showingRightThighPicker = true } label: {
                                Text("\(Int(profile.rightThighCm ?? 55)) cm")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("", isOn: Binding(
                            get: { profile.rightThighCm != nil },
                            set: { on in
                                if on {
                                    profile.rightThighCm = 55
                                    showingRightThighPicker = true
                                } else {
                                    profile.rightThighCm = nil
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingRightThighPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingRightThighPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Right Thigh", selection: Binding(
                                get: { Int(profile.rightThighCm ?? 55) },
                                set: { profile.rightThighCm = Double($0) }
                            )) {
                                ForEach(30...80, id: \.self) { cm in
                                    Text("\(cm) cm").tag(cm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }
                }

                // ── Goals ─────────────────────────────────────────────────
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
                                Text(goal.label)
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                if isGoalSelected(goal.tag) {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
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

                // ── Health & Experience ───────────────────────────────────
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
                            Text("Medical Conditions")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(medicalConditionsSummary)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    .listRowBackground(AppTheme.card)

                    NavigationLink {
                        CurrentInjuriesDetailView(value: $profile.currentInjuries)
                    } label: {
                        HStack {
                            Text("Current Injuries")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(currentInjuriesSummary)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    .listRowBackground(AppTheme.card)

                }

                // ── Lifestyle ─────────────────────────────────────────────
                Section("Lifestyle") {
                    Button { showingSleepPicker = true } label: {
                        HStack {
                            Text("Sleep")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(String(format: "%.1f", profile.sleepHoursPerNight ?? 7))h / night")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingSleepPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingSleepPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Sleep", selection: Binding(
                                get: { profile.sleepHoursPerNight ?? 7 },
                                set: { profile.sleepHoursPerNight = $0 }
                            )) {
                                ForEach(Array(stride(from: 3.0, through: 12.0, by: 0.5)), id: \.self) { h in
                                    Text("\(String(format: "%.1f", h))h").tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    Button { showingStressPicker = true } label: {
                        HStack {
                            Text("Stress Level")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(profile.stressLevel ?? 5) / 10")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingStressPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingStressPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Stress Level", selection: Binding(
                                get: { profile.stressLevel ?? 5 },
                                set: { profile.stressLevel = $0 }
                            )) {
                                ForEach(1...10, id: \.self) { level in
                                    Text("\(level) / 10").tag(level)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
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

                // ── Training ──────────────────────────────────────────────
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
                            Text("Days / Week")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(profile.preferredDaysPerWeek ?? 3) days")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingDaysPerWeekPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingDaysPerWeekPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Days / Week", selection: Binding(
                                get: { profile.preferredDaysPerWeek ?? 3 },
                                set: { profile.preferredDaysPerWeek = $0 }
                            )) {
                                ForEach(1...7, id: \.self) { day in
                                    Text("\(day) \(day == 1 ? "day" : "days")").tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
                        }
                        .presentationDetents([.height(280)])
                    }

                    Button { showingSessionLengthPicker = true } label: {
                        HStack {
                            Text("Session Length")
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text("\(profile.preferredSessionMinutes ?? 60) min")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .sheet(isPresented: $showingSessionLengthPicker) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") { showingSessionLengthPicker = false }
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            Picker("Session Length", selection: Binding(
                                get: { profile.preferredSessionMinutes ?? 60 },
                                set: { profile.preferredSessionMinutes = $0 }
                            )) {
                                ForEach([30, 45, 60, 90], id: \.self) { mins in
                                    Text("\(mins) min").tag(mins)
                                }
                            }
                            .pickerStyle(.wheel)
                            .padding(.bottom)
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
                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
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
