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
	@EnvironmentObject private var expertManager: ExpertManager
	@EnvironmentObject private var promptController: PromptController
	
	var selectedExpert: Expert? {
		guard let selectedExpertId = conversationState.selectedExpertId else {
			return nil
		}
		return expertManager.getExpert(id: selectedExpertId)
	}
	
	var useWebSearch: Bool {
		return selectedExpert?.useWebSearch ?? true
	}
	
	var pendingMessage: Message {
		var text: String = String(localized: "Processing...")
		if self.model.status == .generatingTitle {
			text = String(localized: "Generating title...")
		} else if self.model.status == .querying {
			text = String(localized: "Searching...")
		} else if self.model.status == .usingFunctions {
			text = String(localized: "Calling functions...")
		} else if !self.model.pendingMessage.isEmpty {
			// Show progress if availible
			text = self.model.pendingMessage
		}
		return Message(
			text: text,
			sender: .assistant,
			expertId: promptController.sentExpertId
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
