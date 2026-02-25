//
//  SideMenuView.swift
//  train-ai-v2
//
//  Created by Nicholas on 24/02/2026.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isOpen: Bool
    
    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isOpen = false
                    }
                }
            
            // Side Menu Content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Menu Header
                    HStack {
                        Text("Menu")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                isOpen = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    // Menu Content (Empty for now)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Add menu items here later
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .frame(width: 270)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 0)
                
                Spacer()
            }
        }
    }
}

#Preview {
    SideMenuView(isOpen: .constant(true))
}
