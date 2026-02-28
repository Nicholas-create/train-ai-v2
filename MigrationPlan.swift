//
//  MigrationPlan.swift
//  train-ai-v2
//
//  Created by Nicholas on 28/02/2026.
//

import SwiftData

// MARK: - Versioned schemas

/// V1 = the current live schema (birthYear: Int?, nickname via @Attribute).
/// Any future field change must add a V2 enum + a new MigrationStage here.
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Conversation.self, SDMessage.self, UserProfile.self]
    }
}

// MARK: - Migration plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AppSchemaV1.self] }
    static var stages: [MigrationStage] { [] }   // no migrations needed yet
}
