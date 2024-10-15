//
//  SetupView.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import SwiftUI

struct SetupView: View {
	
	@EnvironmentObject private var conversationState: ConversationState
	@State private var selectedModel: Bool = Settings.hasModel
	
	@Binding var showSetup: Bool
	
    var body: some View {
		Group {
			if !selectedModel {
				// If no model, select a model
				ModelSelectionView(selectedModel: $selectedModel)
			} else {
				// Else, show setup complete screen
				SetupCompleteView(showSetup: $showSetup)
			}
		}
		.padding()
		.padding(.vertical)
		.interactiveDismissDisabled(true)
    }
	
}

//#Preview {
//    SetupView()
//}
