//
//  SearchMenuToggleButton.swift
//  Sidekick
//
//  Created by John Bean on 5/7/25.
//

import SwiftUI

struct SearchMenuToggleButton: View {
    
    var activatedFillColor: Color
    
    @Binding var useWebSearch: Bool
    @Binding var selectedSearchState: SearchState
    
    var body: some View {
        CapsuleMenuButton(
            systemImage: "magnifyingglass",
            activatedFillColor: activatedFillColor,
            isActivated: self.$useWebSearch,
            selectedOption: self.$selectedSearchState
        ) { newValue in
            self.onToggle(newValue: newValue)
        }
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
