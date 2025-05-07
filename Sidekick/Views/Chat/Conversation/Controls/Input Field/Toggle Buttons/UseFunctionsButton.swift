//
//  UseFunctionsButton.swift
//  Sidekick
//
//  Created by John Bean on 4/14/25.
//

import SwiftUI

struct UseFunctionsButton: View {
    
    var activatedFillColor: Color
    
    @Binding var useFunctions: Bool
    
    var useFunctionsTip: UseFunctionsTip = .init()
    
    var body: some View {
        CapsuleButton(
            label: String(localized: "Functions"),
            systemImage: "function",
            activatedFillColor: activatedFillColor,
            isActivated: self.$useFunctions
        ) { newValue in
            self.onToggle(newValue: newValue)
        }
        .popoverTip(self.useFunctionsTip)
    }
    
    private func onToggle(
        newValue: Bool
    ) {
        // Check if functions is configured
        if !Settings.useFunctions {
            // If not, show error and return
            Dialogs.showAlert(
                title: String(localized: "Functions Disabled"),
                message: String(localized: "Functions are disabled in Settings. Please configure it in \"Settings\" -> \"General\" -> \"Functions\".")
            )
            // Set back to false
            self.useFunctions = false
            return
        }
    }
    
}
