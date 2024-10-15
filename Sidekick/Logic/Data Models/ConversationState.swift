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

	@Published var selectedConversationId: UUID? = latestConversation?.id
	static var latestConversation: Conversation? {
		return ConversationManager.shared.conversations
			.sorted(by: \.createdAt).last
	}
	
	@Published var selectedProfileId: UUID? = nil
	
}
