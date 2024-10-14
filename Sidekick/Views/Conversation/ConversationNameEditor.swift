//
//  ConversationNameEditor.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ConversationNameEditor: View {
	
	init(
		conversation: Conversation
	) {
		self.title = conversation.title
		self.conversation = conversation
	}
	
	@EnvironmentObject private var conversationManager: ConversationManager
	
	@State private var isEditing: Bool = false
	@State private var title: String
	
	@FocusState private var focused: Bool
	
	var conversation: Conversation
	
    var body: some View {
		Group {
			if !isEditing {
				Text(conversation.title)
					.onTapGesture(count: 2) {
						isEditing.toggle()
					}
			} else {
				TextField("Title", text: $title)
					.textFieldStyle(.plain)
					.onSubmit {
						exitAndSave()
					}
					.onExitCommand {
						exitAndSave()
					}
			}
		}
    }
	
	private func exitAndSave() {
		// Exit editing mode
		focused = false
		isEditing = false
		// Save
		var editedConversation: Conversation = conversation
		editedConversation.title = title
		conversationManager.update(editedConversation)
	}
}

//#Preview {
//    ConversationNameEditor()
//}
