//
//  ExtensionCardButton.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct ExtensionCardButton: View {
	
	@Environment(\.colorScheme) var colorScheme
	@State private var isHovering: Bool = false
	
	var name: String
	var description: String
	var isSvg: Bool = false
	var image: () -> Image
	
	var action: () -> Void
	
	var isDarkMode: Bool {
		return self.colorScheme == .dark
	}
	
	var backgroundOpacity: Double {
		return isHovering ? 0.3 : 0.15
	}
	
    var body: some View {
		Button {
			self.action()
		} label: {
			self.label
		}
		.buttonStyle(.plain)
		.onHover { hover in
			self.isHovering = hover
		}
    }
	
	var label: some View {
		VStack {
			image()
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 75, height: 75)
				.foregroundColor(.primary)
				.if(isSvg && isDarkMode) { view in
					view
						.colorInvert()
				}
				.padding(.bottom, 5)
			Text(name)
				.font(.headline)
				.bold()
				.foregroundColor(.primary)
			Text(description)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
		}
		.frame(width: 150, height: 150)
		.padding()
		.background {
			RoundedRectangle(
				cornerRadius: 12
			)
			.fill(Color.secondary.opacity(backgroundOpacity))
		}
	}
	
}
