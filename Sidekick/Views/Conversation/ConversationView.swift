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
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
    var body: some View {
		MessagesView()
		.padding(.horizontal)
		.overlay(alignment: .bottom) {
			ConversationControlsView()
			.padding(.trailing)
		}
    }
	
}

//#Preview {
//    ConversationView()
//}
