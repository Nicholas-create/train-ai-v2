//
//  train_ai_v2App.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI
import SwiftData

@main
struct train_ai_v2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
              Conversation.self,
              SDMessage.self,
              UserProfile.self,
          ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
