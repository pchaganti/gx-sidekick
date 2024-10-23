//
//  PromptInputField.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI
import SimilaritySearchKit

struct PromptInputField: View {
	
	@FocusState private var isFocused: Bool
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	@EnvironmentObject private var promptController: PromptController
	
	@State private var sentConversation: Conversation? = nil
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var messages: [Message] {
		return selectedConversation?.messages ?? []
	}
	
	var showQuickPrompts: Bool {
		return promptController.prompt.isEmpty && messages.isEmpty
	}
	
    var body: some View {
		TextField(
			"Send a Message",
			text: $promptController.prompt.animation(.linear),
			axis: .vertical
		)
		.onSubmit(onSubmit)
		.focused($isFocused)
		.textFieldStyle(
			ChatStyle(
				isFocused: _isFocused,
				isRecording: $promptController.isRecording
			)
		)
		.overlay(alignment: .trailing) {
			DictationButton()
		}
		.submitLabel(.send)
		.padding([.vertical, .leading], 10)
		.onExitCommand {
			self.isFocused = false
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.didSelectConversation.name
			)
		) { output in
			self.isFocused = false
		}
		.onChange(of: isFocused) {
			// Show dictation if needed
			if self.isFocused {
				DictationTip.readyForDictation = true
			}
		}
		.onChange(of: conversationState.selectedConversationId) {
			self.isFocused = true
			self.conversationState.selectedProfileId = profileManager.default?.id
		}
    }
	
	/// Function to run when the `return` key is hit
	private func onSubmit() {
		// New line if shift or option pressed
		if CGKeyCode.kVK_Shift.isPressed || CGKeyCode.kVK_Option.isPressed {
			promptController.prompt += "\n"
		} else if promptController.prompt.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
			// End recording
			self.promptController.stopRecording()
			// Send message
			self.submit()
		}
	}
	
	/// Function to send to bot
	private func submit() {
		// Make sound
		if Settings.playSoundEffects {
			SoundEffects.send.play()
		}
		// Get previous content
		guard var conversation = selectedConversation else { return }
		// Make request message
		let newUserMessage: Message = Message(
			text: promptController.prompt,
			sender: .user
		)
		let _ = conversation.addMessage(newUserMessage)
		conversationManager.update(conversation)
		// Set sentConversation
		sentConversation = conversation
		// Clear prompt
		self.promptController.prompt.removeAll()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.promptController.prompt.removeAll()
		}
		// Get response
		Task {
			await self.getResponse()
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
			self.model.indicateStartedQuerying(
				sentConversationId: conversation.id
			)
			var index: SimilarityIndex? = nil
			// If there are resources
			if !((selectedProfile?.resources.resources.isEmpty) ?? true) {
				// Load
				index = await selectedProfile?.resources.loadIndex()
			}
			let useWebSearch: Bool = selectedProfile?.useWebSearch ?? true
			response = try await model.listenThinkRespond(
				messages: self.messages,
				similarityIndex: index,
				useWebSearch: useWebSearch
			)
		} catch let error as LlamaServerError {
			print("Interupted response: \(error)")
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
			// Make response message
			var responseMessage: Message = Message(
				text: "",
				sender: .assistant
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
			// Make sound
			if Settings.playSoundEffects {
				SoundEffects.ping.play()
			}
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

//#Preview {
//    PromptInputField()
//}
