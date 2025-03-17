//
//  ConversationState.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import Foundation
import SwiftUI

@MainActor
public class ConversationState: ObservableObject {
	
	@Published var isManagingExperts: Bool = false

	@Published var selectedConversationId: UUID? = topmostConversation?.id
	
	static var topmostConversation: Conversation? {
		return ConversationManager.shared.conversations.first
	}
	
	private var selectedConversation: Conversation? {
		guard let selectedConversationId = self.selectedConversationId else {
			return nil
		}
		return ConversationManager.shared.getConversation(
			id: selectedConversationId
		)
	}
	
	@Published var selectedExpertId: UUID? = ConversationManager.shared.conversations.first?.messages.last?.expertId ?? ExpertManager.shared.default?.id
	
}
