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
			.onTapGesture {
				self.selectConversation(conversation.wrappedValue)
			}
			.contextMenu {
				Button {
					self.conversationManager.delete(conversation)
				} label: {
					Text("Delete")
				}
			}
		}
		.navigationSplitViewColumnWidth(
			min: 90,
			ideal: 150,
			max: 225
		)
		.onDeleteCommand {
			if let conversationId = conversationState.selectedConversationId {
				self.delete(conversationId)
			}
		}
	}
	
	private func selectConversation(_ conversation: Conversation) {
		// Remove text field focus
		NotificationCenter.default.post(
			name: Notifications.didSelectConversation.name,
			object: nil
		)
		// Obtain focus
		conversationState.selectedConversationId = conversation.id
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

//#Preview {
//    ConversationNavigationListView()
//}
