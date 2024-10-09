//
//  MessagesView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct MessagesView: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var messages: [Message] {
		return self.selectedConversation?.messages ?? []
	}
	
	var body: some View {
		ScrollView {
			HStack(alignment: .top) {
				LazyVStack(
					alignment: .leading,
					spacing: 13
				) {
					ForEach(self.messages) { message in
						MessageView(
							message: message
						)
					}
				}
				.padding(.vertical)
				.padding(.bottom, 55)
				Spacer()
			}
		}
	}
	
}

//#Preview {
//    MessagesView()
//}
