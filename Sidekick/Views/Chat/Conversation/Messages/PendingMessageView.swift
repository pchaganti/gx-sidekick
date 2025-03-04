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
		if !self.model.pendingMessage.isEmpty {
			// Show progress if availible
			text = self.model.pendingMessage.replacingOccurrences(
				of: "\\[",
				with: "$$"
			)
			.replacingOccurrences(
				of: "\\]",
				with: "$$"
			)
		} else if self.model.status == .querying {
			if RetrievalSettings.useTavilySearch && useWebSearch {
				text = String(localized: "Searching in resources and on the web...")
			} else {
				text = String(localized: "Searching in resources...")
			}
		} else if self.model.status == .usingInterpreter {
			text = String(localized: "Using code interpreter...")
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
