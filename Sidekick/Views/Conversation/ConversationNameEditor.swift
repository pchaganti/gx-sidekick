//
//  ConversationNameEditor.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ConversationNameEditor: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	
	@State private var isEditing: Bool = false
	@Binding var conversation: Conversation
	
	@FocusState private var focused: Bool
	
    var body: some View {
		Group {
			if !isEditing {
				Text(conversation.title)
					.onTapGesture(count: 2) {
						isEditing.toggle()
					}
			} else {
				TextField("Title", text: $conversation.title)
					.textFieldStyle(.plain)
					.onSubmit {
						exitEditingMode()
					}
					.onExitCommand {
						exitEditingMode()
					}
			}
		}
		.contextMenu {
			Button {
				isEditing.toggle()
			} label: {
				Text("Edit")
			}
		}
	}
	
	private func exitEditingMode() {
		// Exit editing mode
		focused = false
		isEditing = false
	}
}

//#Preview {
//    ConversationNameEditor()
//}
