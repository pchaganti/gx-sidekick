//
//  ConversationNavigationListView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationNavigationListView: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var body: some View {
		List(
			self.$conversationManager.conversations,
			editActions: .move,
			selection: $conversationState.selectedConversationId
		) { conversation in
			NavigationLink(value: conversation.id) {
				ConversationNameEditor(conversation: conversation)
			}
		}
		.navigationSplitViewColumnWidth(
			min: 125,
			ideal: 175,
			max: 225
		)
	}

	private func delete(_ conversationId: UUID) {
		let _ = Dialogs.showConfirmation(
			title: String(localized: "Delete Conversation"),
			message: String(localized: "Are you sure you want to delete this conversation?")
		) {
			if let conversation = conversationManager.getConversation(
				id: conversationId
			) {
				conversationManager.delete(conversation)
			}
		}
	}
	
}
