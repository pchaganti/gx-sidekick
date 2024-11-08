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
	
	@Published var isManagingProfiles: Bool = false

	@Published var selectedConversationId: UUID? = topmostConversation?.id
	
	static var topmostConversation: Conversation? {
		return ConversationManager.shared.conversations.first
	}
	
	@Published var selectedProfileId: UUID? = ProfileManager.shared.default?.id
	
}
