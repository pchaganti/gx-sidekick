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
		var text: String = "Processing..."
		if !self.model.pendingMessage.isEmpty {
			// Show progress if availible
			text = self.model.pendingMessage
		} else if self.model.status == .querying {
			if RetrievalSettings.useTavilySearch {
				text = "Searching in resources and on the web..."
			} else {
				text = "Searching in resources..."
			}
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
