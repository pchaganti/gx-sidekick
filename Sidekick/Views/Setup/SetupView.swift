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
	
    var body: some View {
		Group {
			if !selectedModel {
				// If no model, select a model
				ModelSelectionView(selectedModel: $selectedModel)
			} else {
				// Else, show setup complete screen
				SetupCompleteView()
			}
		}
		.padding()
    }
	
}

//#Preview {
//    SetupView()
//}
