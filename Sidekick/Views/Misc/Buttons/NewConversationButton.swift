//
//  NewConversationButton.swift
//  Sidekick
//
//  Created by John Bean on 2/12/25.
//

import SwiftUI

struct NewConversationButton: View {
	
	@State private var isHovering: Bool = false
	
	var action: () -> Void
	
	var buttonOpacity: Double {
		return self.isHovering ? 0.2 : 0
	}
	
    var body: some View {
		Button {
			self.action()
		} label: {
			Label(
				"New Conversation",
				systemImage: "square.and.pencil"
			)
			.foregroundStyle(.secondary)
			.font(.headline)
			.fontWeight(.regular)
			.padding(.horizontal, 8)
			.padding(.vertical, 7)
			.background(
				Color.gray.opacity(self.buttonOpacity)
			)
			.clipShape(
				RoundedRectangle(cornerRadius: 7)
			)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(.linear(duration: 0.3)) {
				self.isHovering = hovering
			}
		}
    }
	
}

#Preview {
	NewConversationButton {
		print("Clicked")
	}
}
