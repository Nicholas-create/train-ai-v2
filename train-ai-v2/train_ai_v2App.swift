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
    let sharedModelContainer: ModelContainer
    @State private var showStoreAlert: Bool

    init() {
        let schema = Schema([
            Conversation.self,
            SDMessage.self,
            UserProfile.self,
        ])

        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )

            // Apply file protection to the underlying store after creation.
            // SQLite creates three files: the main store, a write-ahead log (.wal),
            // and a shared-memory index (.shm). All three must be protected.
            let storeURL = container.configurations.first?.url ?? config.url
            let companions = [
                storeURL,
                storeURL.appendingPathExtension("wal"),
                storeURL.appendingPathExtension("shm"),
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

            self.sharedModelContainer = container
            self._showStoreAlert = State(initialValue: false)

        } catch {
            // Persistent store failed — fall back to an in-memory store so the
            // app remains usable, then surface an alert so the user knows their
            // data won't be saved this session.
            #if DEBUG
            print("[Store] Persistent store failed, falling back to in-memory: \(error)")
            #endif
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // In-memory creation has no disk I/O and cannot realistically fail.
            self.sharedModelContainer = try! ModelContainer(for: schema, configurations: [fallbackConfig])
            self._showStoreAlert = State(initialValue: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Storage Unavailable", isPresented: $showStoreAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your data couldn't be saved to disk this session. Try restarting the app.")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
