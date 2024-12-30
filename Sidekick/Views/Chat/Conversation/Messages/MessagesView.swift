//
//  MessagesView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct MessagesView: View {
	
	@Environment(\.colorScheme) var colorScheme
	
	@EnvironmentObject private var model: Model
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
	
	var messages: [Message] {
		return self.selectedConversation?.messages ?? []
	}
	
	var isGenerating: Bool {
		let statusPass: Bool = self.model.status == .coldProcessing || self.model.status == .processing || self.model.status == .querying
		let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
		return statusPass && conversationPass
	}
	
	var body: some View {
		ScrollView {
			HStack(alignment: .top) {
				LazyVStack(
					alignment: .leading,
					spacing: 13
				) {
					Group {
						messagesView
						if isGenerating {
							PendingMessageView()
						}
					}
				}
				.padding(.vertical)
				.padding(.bottom, 150)
				Spacer()
			}
		}
		.toolbar {
			ToolbarItemGroup() {
				MessageShareMenu(
					messagesView: messagesView
				)
			}
		}
	}
	
	var messagesView: some View {
		ForEach(
			self.messages
		) { message in
			MessageView(
				message: message
			)
			.id(message.id)
		}
	}
	
}
