//
//  ExerciseLibraryView.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isSideMenuOpen: Bool
    @Binding var isOpen: Bool
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedType: String = "All"
    @State private var isAddOpen = false

    private let typeFilters = ["All", "Strength", "Cardio", "Mobility", "Flexibility"]

    private var filtered: [Exercise] {
        exercises.filter {
            let matchSearch = searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.muscleGroups.localizedCaseInsensitiveContains(searchText)
            let matchType = selectedType == "All" ||
                $0.exerciseType == selectedType.lowercased()
            return matchSearch && matchType
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundGradientEnd],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(typeFilters, id: \.self) { filter in
                            Button(filter) { selectedType = filter }
                                .font(.system(size: 14, weight: selectedType == filter ? .semibold : .regular))
                                .foregroundStyle(selectedType == filter ? Color.white : AppTheme.primaryText)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(selectedType == filter ? AppTheme.accent : AppTheme.surface)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }

                List {
                    ForEach(filtered) { exercise in
                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(exercise.name)
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppTheme.primaryText)
                                    if exercise.isCustom {
                                        Text("Custom")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(AppTheme.accent).clipShape(Capsule())
                                    }
                                }
                                Text(exercise.muscleGroups)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if exercise.isCustom {
                                Button(role: .destructive) {
                                    modelContext.delete(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Exercise Library")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .searchable(text: $searchText, prompt: "Search name or muscle group")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation { isSideMenuOpen.toggle() }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { isAddOpen = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddOpen) { AddExerciseView() }
        .onChange(of: isOpen) { _, newValue in
            if !newValue { dismiss() }
        }
    }
}
