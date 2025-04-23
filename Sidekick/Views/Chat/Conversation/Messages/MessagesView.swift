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
	@EnvironmentObject private var expertManager: ExpertManager
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
	
	var shouldShowPreview: Bool {
        let statusPass: Bool = self.model.status.isWorking && self.model.status != .backgroundTask
		let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
		return statusPass && conversationPass
	}
	
    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                LazyVStack(alignment: .leading, spacing: 13) {
                    Group {
                        self.messagesView
                        if self.shouldShowPreview {
                            PendingMessageView()
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 175)
                Spacer()
            }
        }
    }
	
	var messagesView: some View {
        ForEach(
            self.messages
        ) { message in
            MessageView(message: message)
                .equatable()
                .id(message.id)
        }
	}
	
}
