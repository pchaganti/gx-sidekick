//
//  SlideStudioPromptView.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import SwiftUI

struct SlideStudioPromptView: View {

	@FocusState private var isFocused: Bool
	@State private var didFinishTyping: Bool = false
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
    var body: some View {
		VStack(
			spacing: 20
		) {
			typedText
			field
			if !self.slideStudioViewController.hasResources {
				SlideStudioQuickPromptsView()
			}
			if self.slideStudioViewController.hasResources {
				self.resourceCarousel
			}
		}
		.padding()
		.frame(minWidth: 500)
		.onDrop(
			of: ["public.file-url"],
			delegate: slideStudioViewController
		)
    }
	
	var field: some View {
		TextField(
			"e.g. Create a presentation explaining the Von Neumann architecture.",
			text: $slideStudioViewController.prompt.animation(
				.linear
			),
			axis: .vertical
		)
		.onDrop(
			of: ["public.file-url"],
			delegate: slideStudioViewController
		)
		.onSubmit(onSubmit)
		.submitLabel(.send)
		.focused($isFocused)
		.textFieldStyle(
			ChatFieldStyle(
                isFocused: self._isFocused,
				isRecording: .constant(false),
				useAttachments: true,
				bottomOptions: true,
				cornerRadius: 22
			)
		)
		.overlay(alignment: .leading) {
			AttachmentSelectionButton { url in
				await self.slideStudioViewController.addFile(url)
			}
		}
		.overlay(alignment: .bottomLeading) {
			SlideStudioPromptOptionsView()
		}
		.overlay {
			Color.clear
				.onDrop(
					of: ["public.file-url"],
					delegate: slideStudioViewController
				)
		}
	}
	
	var typedText: some View {
		HStack(
			spacing: 5
		) {
			TypedTextView(
				String(localized: "Outline the subject matter of your presentation"),
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
	
	var resourceCarousel: some View {
		TemporaryResourcesView(
			tempResources: self.$slideStudioViewController.tempResources
		)
		.transition(
			.opacity
		)
	}
	
	/// Function to start generation after prompt submission
	private func onSubmit() {
		Task.detached { @MainActor in
			await slideStudioViewController.startGeneration()
		}
	}
	
}
