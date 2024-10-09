//
//  ConversationControlsView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationControlsView: View {
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@FocusState private var isFocused: Bool
	
	@State private var input: String = ""
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var body: some View {
		Group {
			TextField("Message", text: $input, axis: .vertical)
				.onSubmit(onSubmit)
				.focused($isFocused)
				.textFieldStyle(ChatStyle(isFocused: _isFocused))
				.submitLabel(.send)
				.padding([.vertical, .leading], 10)
				.onAppear {
					self.isFocused = true
				}
		}
		.onChange(of: model.output) {
			// Update message
			let output: String = self.model.output
			let tokenCount: Int = self.model.encode(output).count
			// Update last message
			guard var conversation = self.selectedConversation else { return }
			guard var lastMessage = self.selectedConversation?.messages.last else { return }
			if lastMessage.outputEnded { return }
			lastMessage.update(
				newText: output,
				newTokenCount: tokenCount
			)
			conversation.updateMessage(lastMessage)
			let _ = conversationManager.update(conversation)
		}
    }
	
	private func onSubmit() {
		// New line if shift or option pressed
		if CGKeyCode.kVK_Shift.isPressed || CGKeyCode.kVK_Option.isPressed {
			input += "\n"
		} else if input.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
			// Else, send message
			self.sendMessage()
		}
	}
	
	private func sendMessage() {
		// Get previous content
		guard var conversation = selectedConversation else { return }
		// Formulate message
		let newUserMessage: Message = Message(
			text: input,
			sender: .user
		)
		let newBotMessage: Message = Message(
			text: "",
			sender: .bot
		)
		let _ = conversation.addMessage(newUserMessage)
		let _ = conversation.addMessage(newBotMessage)
		conversationManager.update(conversation)
		// Get response
		Task {
			await triggerResponse()
		}
	}
	
	private func triggerResponse() async {
		// Set update func
		self.model.update = { delta in
			// End message
			if delta == nil {
				guard var conversation = self.selectedConversation else {
					return
				}
				guard var lastMessage = conversation.messages.last else {
					return
				}
				lastMessage.end()
				conversation.updateMessage(lastMessage)
				Task {
					await MainActor.run {
						self.conversationManager.update(conversation)
					}
				}
			}
		}
		let input: String = self.input
		self.input.removeAll()
		await self.model.respond(to: input)
	}
	
}
//
//#Preview {
//    ConversationControlsView()
//}
