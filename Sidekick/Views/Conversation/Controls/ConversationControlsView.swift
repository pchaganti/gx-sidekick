//
//  ConversationControlsView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

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
	
	var body: some View {
		VStack {
			if showQuickPrompts {
				ConversationQuickPromptsView(
					input: $promptController.prompt
				)
			}
			if promptController.hasResources {
				TemporaryResourcesView()
			}
			HStack(spacing: 0) {
				PromptInputField()
					.overlay {
						Color.clear
							.onDrop(
								of: ["public.file-url"],
								delegate: promptController
							)
					}
				if #unavailable(macOS 15) {
					lengthyTasksButton
				}
			}
		}
		.padding(.leading)
		.onDrop(
			of: ["public.file-url"],
			delegate: promptController
		)
		.environmentObject(promptController)
	}
	
	var lengthyTasksButton: some View {
		LengthyTasksToolbarButton(
			usePadding: true
		)
		.labelStyle(.iconOnly)
		.buttonStyle(ChatButtonStyle())
		.padding(.leading, 7)
	}
	
}

//
//#Preview {
//    ConversationControlsView()
//}
