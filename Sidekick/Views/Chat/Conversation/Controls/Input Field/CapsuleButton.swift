//
//  CapsuleButton.swift
//  Sidekick
//
//  Created by John Bean on 4/14/25.
//

import SwiftUI

struct CapsuleButton: View {
    
    var label: String
    var systemImage: String
    var activatedFillColor: Color = .accentColor
    
    @Binding var isActivated: Bool
    var onToggle: (Bool) -> Void
    
    var textColor: Color {
        return self.isActivated ? self.activatedFillColor : .secondary
    }
    
    var bubbleColor: Color {
        return self.isActivated ? self.activatedFillColor.opacity(0.3) : .white.opacity(0.0001)
    }
    
    var bubbleBorderColor: Color {
        return self.isActivated ? bubbleColor : .secondary
    }
    
    var body: some View {
        Button {
            self.toggle()
        } label: {
            Label(self.label, systemImage: self.systemImage)
                .foregroundStyle(self.textColor)
                .font(.caption)
                .padding(5)
                .background {
                    capsule
                }
        }
        .buttonStyle(.plain)
    }
    
    var capsule: some View {
        ZStack {
            Capsule()
                .fill(self.bubbleColor)
            Capsule()
                .stroke(
                    style: .init(
                        lineWidth: 0.3
                    )
                )
                .fill(self.bubbleBorderColor)
        }
    }
    
    private func toggle() {
        // Toggle
        withAnimation(
            .linear(duration: 0.15)
        ) {
            self.isActivated.toggle()
        }
        // Run handler
        self.onToggle(self.isActivated)
    }
    
}
