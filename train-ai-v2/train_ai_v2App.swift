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
            // Apply file protection to the underlying store after creation.
            // SQLite creates three files: the main store, a write-ahead log (.wal),
            // and a shared-memory index (.shm). All three must be protected.
            let storeURL = modelConfiguration.url
            let companions = [
                storeURL,
                storeURL.appendingPathExtension("wal"),
                storeURL.appendingPathExtension("shm")
            ]
            for fileURL in companions {
                guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }
                do {
                    try FileManager.default.setAttributes(
                        [.protectionKey: FileProtectionType.completeUnlessOpen],
                        ofItemAtPath: fileURL.path
                    )
                } catch {
                    #if DEBUG
                    print("[Security] File protection failed for \(fileURL.lastPathComponent): \(error)")
                    #endif
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
