//
//  SetupCompleteView.swift
//  Sidekick
//
//  Created by Bean John on 9/23/24.
//

import SwiftUI

struct SetupCompleteView: View {
	
	@EnvironmentObject private var conversationState: ConversationState
	
    var body: some View {
		VStack {
			Image(systemName: "checkmark.circle.fill")
				.resizable()
				.frame(width: 60, height: 60)
				.foregroundColor(.green)
				.imageScale(.large)
			
			Text("**Success!**")
				.font(.largeTitle)
			
			Text("The model was installed.")
				.font(.title3)
			
			Button("Continue") {
				Settings.finishSetup()
				conversationState.showSetup = false
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.large)
			.padding(.top, 16)
			.padding(.horizontal, 40)
			.keyboardShortcut(.defaultAction)
		}
		.padding()
    }
	
}

//#Preview {
//    SetupCompleteView()
//}
