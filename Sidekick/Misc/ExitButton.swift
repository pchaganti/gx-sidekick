//
//  ExitButton.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import SwiftUI

struct ExitButton: View {
	
	@State private var isHovering: Bool = false
	
	var action: () -> Void
	
	var scale: CGFloat {
		return isHovering ? 1.25 : 1
	}
	
	var color: Color {
		return isHovering ? .accentColor : .primary
	}
	
	var body: some View {
		Button {
			action()
		} label: {
			Image(systemName: "xmark.circle.fill")
		}
		.buttonStyle(PlainButtonStyle())
		.foregroundStyle(color)
		.scaleEffect(scale)
		.onHover { hover in
			withAnimation(.linear) {
				isHovering = hover
			}
		}
		.keyboardShortcut("w", modifiers: .command)
	}
	
}
