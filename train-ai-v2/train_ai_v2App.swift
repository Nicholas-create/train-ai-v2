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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Apply file protection to the underlying store after creation
            container.mainContext.container.persistentStoreCoordinator.persistentStores.forEach { store in
                if let storeURL = store.url {
                    try? FileManager.default.setAttributes(
                        [.protectionKey: FileProtectionType.completeUnlessOpen],
                        ofItemAtPath: storeURL.path
                    )
                }
            }
            return container
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
