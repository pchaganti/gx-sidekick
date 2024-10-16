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
		
		CommandGroup(replacing: .newItem) {
			Button("New Conversation") {
				ConversationManager.shared.newConversation()
			}
			.keyboardShortcut("n", modifiers: .command)
		}
	}
	
}

