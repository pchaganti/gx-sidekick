//
//  SetupCompleteView.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import SwiftUI

struct SetupCompleteView: View {
	
	var description: String
	var action: () -> Void
	
    var body: some View {
		VStack {
			Image(systemName: "checkmark.circle.fill")
				.resizable()
				.frame(width: 60, height: 60)
				.foregroundColor(.green)
				.imageScale(.large)
			Text("**Setup Complete**")
				.font(.largeTitle)
			Text(description)
				.font(.title3)
			doneButton
		}
    }
	
	var doneButton: some View {
		Button {
			self.action()
		} label: {
			Text("Continue")
		}
		.buttonStyle(.borderedProminent)
		.controlSize(.large)
		.padding(.top, 16)
		.padding(.horizontal, 40)
		.keyboardShortcut(.defaultAction)
	}
}
