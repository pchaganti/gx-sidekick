//
//  ConversationCommands.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import SwiftUI

@MainActor
public class ConversationCommands {
	
	static var commands: some Commands {
		
		CommandMenu("Conversation") {
			Button(
				action: ConversationManager.shared.newConversation
			) {
				Text("New Conversation")
			}
			.keyboardShortcut("n", modifiers: .command)
		}
	}
	
}

