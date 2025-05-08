//
//  ToggleSearchButton.swift
//  Sidekick
//
//  Created by John Bean on 3/18/25.
//

import SwiftUI

struct ToggleSearchButton: View {
	
	@Binding var useWebSearch: Bool
	
	var useWebSearchTip: UseWebSearchTip = .init()
	
    var body: some View {
        CapsuleButton(
            label: String(localized: "Search"),
            systemImage: "magnifyingglass",
            isActivated: self.$useWebSearch
        ) { newValue in
            self.onToggle(newValue: newValue)
        }
		.popoverTip(self.useWebSearchTip)
    }
	
    private func onToggle(
        newValue: Bool
    ) {
		// Check if search is configured
		if !RetrievalSettings.canUseWebSearch {
			// If not, show error and return
			Dialogs.showAlert(
				title: String(localized: "Search not configured"),
				message: String(localized: "Search is not configured properly. Please configure it in \"Settings\" -> \"Retrieval\".")
			)
            // Set back to false
            self.useWebSearch = false
			return
		}
	}
	
}
