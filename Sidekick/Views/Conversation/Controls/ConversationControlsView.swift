//
//  ConversationControlsView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import MarkdownUI
import SwiftUI

struct ConversationControlsView: View {
	
	@StateObject private var promptController: PromptController = .init()
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var messages: [Message] {
		return selectedConversation?.messages ?? []
	}
	
	var showQuickPrompts: Bool {
		let noPrompt: Bool = promptController.prompt.isEmpty
		let noMessages: Bool = messages.isEmpty
		let noResources: Bool = !promptController.hasResources
		return noPrompt && noMessages && noResources
	}
	
	var maxHeight: CGFloat {
		let center: Bool = promptController.prompt.isEmpty && messages.isEmpty
		return center ? .infinity : 0
	}
	
	var body: some View {
		VStack {
			Spacer()
				.frame(maxHeight: maxHeight)
			controls
			Spacer()
				.frame(maxHeight: maxHeight)
		}
	}
	
	var controls: some View {
		VStack {
			if messages.isEmpty {
				Group {
					if promptController.prompt.isEmpty {
						Markdown(
							String(localized: "# How can I help you?")
						)
					}
					inputField
				}
			}
			if showQuickPrompts {
				ConversationQuickPromptsView(
					input: $promptController.prompt
				)
			}
			if promptController.hasResources {
				TemporaryResourcesView()
			}
			if !messages.isEmpty {
				inputField
			}
		}
		.padding(.leading)
		.onDrop(
			of: ["public.file-url"],
			delegate: promptController
		)
		.environmentObject(promptController)
	}
	
	var inputField: some View {
		PromptInputField()
			.overlay {
				Color.clear
					.onDrop(
						of: ["public.file-url"],
						delegate: promptController
					)
			}
	}
	
}

//
//#Preview {
//    ConversationControlsView()
//}
