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
	
	@Binding var selectedConversationId: UUID?
	
	var body: some View {
		List(
			self.conversationManager.conversations.sorted(
				by: \.createdAt,
				order: .reverse
			),
			selection: $selectedConversationId
		) { conversation in
			NavigationLink(
				conversation.title,
				value: conversation.id
			)
			.contextMenu {
				Button("Delete") {
					self.conversationManager.delete(conversation)
				}
			}
		}
		.navigationSplitViewColumnWidth(
			min: 90,
			ideal: 150,
			max: 225
		)
		.onDeleteCommand {
			if let conversationId = selectedConversationId {
				self.delete(conversationId)
			}
		}
	}
	
	private func delete(_ conversationId: UUID) {
		let _ = Dialogs.showConfirmation(
			title: "Delete Conversation",
			message: "Are you sure you want to delete this conversation?"
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
