//
//  PendingMessageView.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import SwiftUI

struct PendingMessageView: View {
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationState: ConversationState
	
	var pendingMessage: Message {
		var text: String = "Loading LLM..."
		if !self.model.pendingMessage.isEmpty {
			// Show progress if availible
			text = self.model.pendingMessage
		} else if self.model.status == .querying {
			text = "Querying resources..."
		}
		return Message(
			text: text,
			sender: .assistant
		)
	}
	
    var body: some View {
		MessageView(
			message: pendingMessage,
			canEdit: false
		)
    }
	
}

//#Preview {
//    PendingMessageView()
//}
