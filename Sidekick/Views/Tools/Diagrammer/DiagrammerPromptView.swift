//
//  DiagrammerPromptView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct DiagrammerPromptView: View {
	
	@FocusState private var isFocused: Bool
	@State private var didFinishTyping: Bool = false
	
	@EnvironmentObject private var diagrammerViewController: DiagrammerViewController
	
    var body: some View {
		VStack(
			spacing: 20
		) {
			typedText
			field
			DiagrammerQuickPromptsView()
		}
		.padding()
		.frame(minWidth: 500)
    }
	
	var typedText: some View {
		HStack(
			spacing: 5
		) {
			TypedTextView(
				String(localized: "Describe a concept you'd like to see illustrated in a diagram"),
				duration: 1.0,
				didFinish: $didFinishTyping
			)
			.font(.title)
			.bold()
			if !didFinishTyping {
				Circle()
					.fill(.white)
					.frame(width: 15, height: 15)
			}
		}
	}
	
	var field: some View {
		TextField(
			"e.g. Draw a diagram of the eutrophication cycle and how it forms a positive feedback loop.",
			text: $diagrammerViewController.prompt.animation(
				.linear
			),
			axis: .vertical
		)
		.onSubmit(onSubmit)
		.submitLabel(.send)
		.focused($isFocused)
		.textFieldStyle(
			ChatStyle(
                isFocused: self._isFocused,
				isRecording: .constant(false),
				useAttachments: false,
				useDictation: false
			)
		)
	}
	
	/// Function called when the user submits the prompt
	private func onSubmit() {
		// Check for empty prompt
		if !diagrammerViewController.prompt.isEmpty {
			self.diagrammerViewController.submitPrompt()
		}
	}
	
}
