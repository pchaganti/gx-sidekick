//
//  UseReasoningButton.swift
//  Sidekick
//
//  Created by John Bean on 4/28/25.
//

import SwiftUI

struct UseReasoningButton: View {
    
    @EnvironmentObject private var promptController: PromptController
    
    var activatedFillColor: Color
    
    @Binding var useReasoning: Bool
    
    var selectedModel: KnownModel? {
        return Model.shared.selectedModel
    }
    var canToggleReasoning: Bool {
        if let isHybridReasoningModel = self.selectedModel?.isHybridReasoningModel, isHybridReasoningModel {
            return true
        }
        return false
    }
    var modelDoesReason: Bool {
        return self.selectedModel?.isReasoningModel ?? false
    }
    
    var systemImage: String {
        if !self.useReasoning {
            return "lightbulb"
        }
        return "lightbulb.fill"
    }
    
    var body: some View {
        CapsuleButton(
            label: String(localized: "Reason"),
            systemImage: self.systemImage,
            activatedFillColor: self.activatedFillColor,
            isActivated: self.$useReasoning
        ) { newValue in
            self.onToggle(newValue: newValue)
        }
    }
    
    private func onToggle(
        newValue: Bool
    ) {
        // Check if model is hybrid reasoning model
        if !self.canToggleReasoning {
            // If not, show error and return
            self.useReasoning = self.modelDoesReason
            Dialogs.showAlert(
                title: String(localized: "Not Available"),
                message: String(localized: "The selected model is not a hybrid reasoning model. Reasoning cannot be toggled.")
            )
            return
        }
        // Check if deep research is activated
        if self.promptController.isUsingDeepResearch {
            // If true, force reasoning
            self.useReasoning = true
            Dialogs.showAlert(
                title: String(localized: "Not Available"),
                message: String(localized: "Reasoning must be turned on to use Deep Research.")
            )
            return
        }
        // If can toggle, signal toggled
        self.promptController.didManuallyToggleReasoning = true
    }
    
}
