//
//  SetupView.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import SwiftUI

struct SetupView: View {
	
	@Binding var showSetup: Bool
	@State private var selectedModel: Bool = Settings.hasModel
	
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
    }
	
}

//#Preview {
//    SetupView()
//}
