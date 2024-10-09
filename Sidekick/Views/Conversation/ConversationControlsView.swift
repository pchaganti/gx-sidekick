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
	
	@State private var prompt: String = ""
	
	@State private var sentConversation: Conversation? = nil
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var messages: [Message] {
		return selectedConversation?.messages ?? []
	}
	
	var body: some View {
		Group {
			TextField("Message", text: $prompt, axis: .vertical)
				.onSubmit(onSubmit)
				.focused($isFocused)
				.textFieldStyle(ChatStyle(isFocused: _isFocused))
				.submitLabel(.send)
				.padding([.vertical, .leading], 10)
				.onAppear {
					self.isFocused = true
				}
		}
    }
	
	private func onSubmit() {
		// New line if shift or option pressed
		if CGKeyCode.kVK_Shift.isPressed || CGKeyCode.kVK_Option.isPressed {
			prompt += "\n"
		} else if prompt.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
			// Send message
			self.submit()
		}
	}
	
	private func submit() {
		// Get previous content
		guard var conversation = selectedConversation else { return }
		// Make request message
		let newUserMessage: Message = Message(
			text: prompt,
			sender: .user
		)
		let _ = conversation.addMessage(newUserMessage)
		conversationManager.update(conversation)
		prompt = ""
		// Set sentConversation
		sentConversation = conversation
		// Get response
		Task {
			await getResponse()
		}
	}
	
	private func getResponse() async {
		// If processing, use recursion to update
		if (model.status == .processing || model.status == .coldProcessing) {
			Task {
				await model.interrupt()
				Task.detached(priority: .userInitiated) {
					try? await Task.sleep(for: .seconds(1))
					await getResponse()
				}
			}
			return
		}
		// Get conversation
		guard var conversation = sentConversation else { return }
		// Get response
		var response: LlamaServer.CompleteResponse
		do {
			response = try await model.listenThinkRespond(
				sentConversationId: conversation.id,
				messages: self.messages
			)
		} catch let error as LlamaServerError {
			await model.interrupt()
			handleResponseError(error)
			return
		} catch {
			print("Agent listen threw unexpected error", error as Any)
			return
		}
		// Update UI
		await MainActor.run {
			// Exit if conversation is inactive
			if self.selectedConversation?.id != conversation.id {
				return
			}
			// Output final output to debug console
//			print("response.text: \(response.text)")
			// Make response message
			var responseMessage: Message = Message(
				text: "",
				sender: .system
			)
			responseMessage.update(
				newText: response.text,
				tokensPerSecond: response.predictedPerSecond ,
				responseStartSeconds: response.responseStartSeconds
			)
			responseMessage.end()
			// Update conversation
			let _ = conversation.addMessage(
				responseMessage
			)
			conversationManager.update(conversation)
			// Reset sendConversation
			self.sentConversation = nil
		}
	}
	
	@MainActor
	func handleResponseError(_ error: LlamaServerError) {
		print("Handle response error:", error.localizedDescription)
		let errorDescription: String = error.errorDescription ?? "Unknown Error"
		let recoverySuggestion: String = error.recoverySuggestion
		Dialogs.showAlert(
			title: "\(errorDescription): \(recoverySuggestion)"
		)
	}
	
}
//
//#Preview {
//    ConversationControlsView()
//}
