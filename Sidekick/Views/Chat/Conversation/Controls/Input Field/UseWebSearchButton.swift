//
//  UseWebSearchButton.swift
//  Sidekick
//
//  Created by John Bean on 3/18/25.
//

import SwiftUI

struct UseWebSearchButton: View {
	
	@Binding var useWebSearch: Bool
	
	var useWebSearchTip: UseWebSearchTip = .init()
	
	var webSearchTextColor: Color {
		return self.useWebSearch ? .accentColor : .secondary
	}
	
	var webSearchBubbleColor: Color {
		return self.useWebSearch ? .accentColor.opacity(0.3) : .clear
	}
	
	var webSearchBubbleBorderColor: Color {
		return self.useWebSearch ? webSearchBubbleColor : .secondary
	}
	
    var body: some View {
		Button {
			self.toggleWebSearch()
		} label: {
			Label("Web Search", systemImage: "globe")
				.foregroundStyle(self.webSearchTextColor)
				.font(.caption)
				.padding(5)
				.background {
					capsule
				}
		}
		.buttonStyle(.plain)
		.popoverTip(self.useWebSearchTip)
    }
	
	var capsule: some View {
		ZStack {
			if self.useWebSearch {
				Capsule()
					.fill(self.webSearchBubbleColor)
			}
			Capsule()
				.stroke(
					style: .init(
						lineWidth: 0.3
					)
				)
				.fill(self.webSearchBubbleBorderColor)
		}
	}
	
	private func toggleWebSearch() {
		// Check if search is configured
		if !RetrievalSettings.canUseWebSearch {
			// If not, show error and return
			Dialogs.showAlert(
				title: String(localized: "Search not configured"),
				message: String(localized: "Search is not configured. Please configure it in \"Settings\" -> \"Retrieval\".")
			)
			return
		}
		withAnimation(
			.linear(duration: 0.15)
		) {
			self.useWebSearch.toggle()
		}
	}
	
}
