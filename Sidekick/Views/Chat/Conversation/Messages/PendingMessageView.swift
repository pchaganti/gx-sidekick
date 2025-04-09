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
	
    var body: some View {
		MessageView(
            message: self.model.displayedPendingMessage,
			canEdit: false
		)
    }
	
}
