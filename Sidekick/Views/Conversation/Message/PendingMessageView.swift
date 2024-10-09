//
//  PendingMessageView.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import SwiftUI

struct PendingMessageView: View {
	
	@EnvironmentObject private var model: Model
	
	var pendingMessage: Message {
		var text: String = "Loading model..."
		if self.model.isProcessing {
			text = self.model.pendingMessage
		}
		return Message(
			text: text,
			sender: .system
		)
	}
	
    var body: some View {
		MessageView(message: pendingMessage)
    }
	
}

#Preview {
    PendingMessageView()
}
