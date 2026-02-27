//
//  SideMenuView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isOpen: Bool
    var width: CGFloat
    @Binding var isSettingsOpen: Bool
    @Binding var isProfileOpen: Bool

    var body: some View {
        ZStack {
            // Dimmed Background
            AppTheme.dimOverlay
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isOpen = false
                    }
                }

            // Side Menu Content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {

                Text("Train AI")
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    // ── Nav Items
                    navRow(icon: "sparkle.text.clipboard", label: "Workout Program") {
                        withAnimation { isOpen = false }
                    }
                    
                    navRow(icon: "bubble.left.and.bubble.right", label: "Chats") {
                        withAnimation { isOpen = false }
                    }
                    
                    navRow(icon: "clock", label: "History") { }
                    navRow(icon: "chart.line.uptrend.xyaxis", label: "Progression") { }

                    Spacer()

                    // ── Separator

                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    navRow(icon: "person.crop.circle", label: "Profile") {
                        withAnimation { isOpen = false }
                        isProfileOpen = true
                    }

                    navRow(icon: "gearshape", label: "Settings") {
                        withAnimation { isOpen = false }
                        isSettingsOpen = true
                    }


                }
                .frame(width: width)
                .background(AppTheme.surface)
                .shadow(color: AppTheme.shadowMedium, radius: 10, x: -5, y: 0)

                Spacer()
            }
        }
    }

    private func navRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
        }
    }
    
}


#Preview {
    SideMenuView(isOpen: .constant(true), width: 320,
                 isSettingsOpen: .constant(false), isProfileOpen: .constant(false))
}
