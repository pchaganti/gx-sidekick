//
//  ConversationView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationView: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
    var body: some View {
		MessagesView(
			selectedConversationId: $selectedConversationId
		)
		.padding(.horizontal)
		.overlay(alignment: .bottom) {
			ConversationControlsView(
				selectedConversationId: $selectedConversationId
			)
			.padding(.trailing)
		}
    }
	
}

//#Preview {
//    ConversationView()
//}
