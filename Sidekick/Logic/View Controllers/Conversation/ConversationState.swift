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
	
	/// The topmost conversation listed in the sidebar
	static var topmostConversation: Conversation? {
		return ConversationManager.shared.conversations.first
	}
	
	/// The currently selected conversation
	public var selectedConversation: Conversation? {
		guard let selectedConversationId = self.selectedConversationId else {
			return nil
		}
		return ConversationManager.shared.getConversation(
			id: selectedConversationId
		)
	}
	
	@Published var selectedExpertId: UUID? = ConversationManager.shared.conversations.first?.messages.last?.expertId ?? ExpertManager.shared.default?.id
	
	@Published var useCanvas: Bool = false
	
	/// Function to create a new conversation
	public func newConversation() {
		// Create new conversation
		ConversationManager.shared.newConversation()
		// Reset selected expert
		withAnimation(.linear) {
			self.selectedExpertId = ExpertManager.shared.default?.id
		}
		// Select newly created conversation
		if let recentConversationId = ConversationManager.shared.recentConversation?.id {
			withAnimation(.linear) {
				self.selectedConversationId = recentConversationId
			}
		}
	}
	
}
