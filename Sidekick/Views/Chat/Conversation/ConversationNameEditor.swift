//
//  ConversationNameEditor.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ConversationNameEditor: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@State private var isEditing: Bool = false
	@Binding var conversation: Conversation
	
	@FocusState private var isFocused: Bool
	
    var body: some View {
		Group {
			if !isEditing {
				Text(conversation.title)
					.contentTransition(.numericText())
			} else {
				TextField("Title", text: $conversation.title)
					.focused($isFocused)
					.textFieldStyle(.plain)
					.onSubmit {
						self.toggleEditingMode()
					}
					.onExitCommand {
						self.toggleEditingMode()
					}
			}
		}
		.contextMenu {
			Group {
				Button {
					self.toggleEditingMode()
				} label: {
					Text("Rename")
				}
				Button {
					self.delete()
				} label: {
					Text("Delete")
				}
			}
		}
	}
	
	private func delete() {
		// If deleting selected conversation, reset selected conversation
		if self.conversationState.selectedConversationId == self.conversation.id {
			self.conversationState.selectedConversationId = nil
		}
		// Delete
		self.conversationManager.delete(conversation)
	}
	
	private func toggleEditingMode() {
		// Exit editing mode
		self.isFocused.toggle()
		self.isEditing.toggle()
	}
	
}
