//
//  ContentView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("app_color_scheme") private var colorScheme: String = "system"

    private var preferredScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // nil = follow system
        }
    }

    var body: some View {
        ChatsListView()
            .preferredColorScheme(preferredScheme)
    }
}

#Preview {
    ContentView()
}
