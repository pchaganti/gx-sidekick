//
//  PromptInputField.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI
import SimilaritySearchKit
import ImagePlayground

struct PromptInputField: View {
	
	@FocusState private var isFocused: Bool
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var expertManager: ExpertManager
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
	
	var selectedExpert: Expert? {
		guard let selectedExpertId = conversationState.selectedExpertId else {
			return nil
		}
		return expertManager.getExpert(id: selectedExpertId)
	}
	
	var messages: [Message] {
		return selectedConversation?.messages ?? []
	}
	
	var showQuickPrompts: Bool {
		return promptController.prompt.isEmpty && messages.isEmpty
	}
	
	var addFilesTip: AddFilesTip = .init()
	
	var body: some View {
		textField
			.onExitCommand {
				self.isFocused = false
			}
			.onChange(of: isFocused) {
				// Show add files and dictation tips if needed
				if self.isFocused {
					AddFilesTip.readyForAddingFiles = true
					DictationTip.readyForDictation = true
				}
			}
			.onChange(of: conversationState.selectedConversationId) {
				self.isFocused = true
				withAnimation(.linear) {
					self.conversationState.selectedExpertId = expertManager.default?.id
				}
			}
			.onAppear {
				self.isFocused = true
			}
			.popoverTip(addFilesTip)
	}
	
	var textField: some View {
		TextField(
			"Send a Message",
			text: $promptController.prompt.animation(
				.linear
			),
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
		.overlay(alignment: .leading) {
			AttachmentSelectionButton()
		}
		.overlay(alignment: .trailing) {
			DictationButton()
		}
		.submitLabel(.send)
		.padding([.vertical, .leading], 10)
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
		// Get prompt expected result type
		let resultType: PromptAnalyzer.ResultType = PromptAnalyzer.analyzePrompt(
			promptController.prompt
		)
		// Make request message
		let newUserMessage: Message = Message(
			text: promptController.prompt,
			sender: .user
		)
		let _ = conversation.addMessage(newUserMessage)
		conversationManager.update(conversation)
		// Set sentConversation
		self.sentConversation = conversation
		// Capture temp resources
		let tempResources: [TemporaryResource] = self.promptController.tempResources
		// If result type is text, send message
		switch resultType {
			case .text:
				self.startTextGeneration(
					tempResources: tempResources
				)
			case .image:
				// If image generation is available, start generating image
				if PromptAnalyzer.ResultType.image.isAvailable {
					self.startImageGeneration()
				} else {
					// Else, fall back to text
					self.startTextGeneration(
						tempResources: tempResources
					)
				}
		}
		// Clear prompt
		self.clearInputs()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.clearInputs()
		}
	}
	
	private func startTextGeneration(
		tempResources: [TemporaryResource]
	) {
		// Get response
		Task {
			await self.generateChatResponse(
				tempResources: tempResources
			)
		}
	}
	
	private func startImageGeneration() {
		if #available(macOS 15.2, *) {
			// Start generation
			self.promptController.imageConcept = self.promptController.prompt
			self.promptController.isGeneratingImage = true
			// Reset sentConversation
			self.sentConversation = nil
		}
	}
	
	private func clearInputs() {
		self.promptController.prompt.removeAll()
	}
	
	private func generateChatResponse(
		tempResources: [TemporaryResource]
	) async {
		// If processing, use recursion to update
		if (model.status == .processing || model.status == .coldProcessing) {
			Task {
				await model.interrupt()
				Task.detached(priority: .userInitiated) {
					try? await Task.sleep(for: .seconds(1))
					await generateChatResponse(
						tempResources: tempResources
					)
				}
			}
			return
		}
		// Get conversation
		guard var conversation = sentConversation else { return }
		// Get response
		var response: LlamaServer.CompleteResponse
		var didUseSources: Bool = false
		do {
			self.model.indicateStartedQuerying(
				sentConversationId: conversation.id
			)
			var index: SimilarityIndex? = nil
			// If there are resources
			if !((selectedExpert?.resources.resources.isEmpty) ?? true) {
				// Load
				index = await selectedExpert?.resources.loadIndex()
			}
			let useWebSearch: Bool = selectedExpert?.useWebSearch ?? true
			// Set if sources were used
			let hasIndexItems: Bool = !((
				index?.indexItems.isEmpty
			) ?? true)
			didUseSources = useWebSearch || hasIndexItems || !tempResources.isEmpty
			response = try await model.listenThinkRespond(
				messages: self.messages,
				mode: .chat,
				similarityIndex: index,
				useWebSearch: useWebSearch,
				temporaryResources: tempResources
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
				sender: .assistant,
				model: response.modelName,
				usedServer: response.usedServer
			)
			responseMessage.update(
				response: response,
				includeReferences: didUseSources
			)
			responseMessage.end()
			// Update conversation
			let _ = conversation.addMessage(
				responseMessage
			)
			conversation.tokenCount = response.usage?.total_tokens
			self.conversationManager.update(conversation)
			// Make sound
			if Settings.playSoundEffects {
				SoundEffects.ping.play()
			}
			// Reset sentConversation
			self.sentConversation = nil
		}
	}
	
	@MainActor
	private func handleResponseError(_ error: LlamaServerError) {
		print("Handle response error:", error.localizedDescription)
		let errorDescription: String = error.errorDescription ?? "Unknown Error"
		let recoverySuggestion: String = error.recoverySuggestion
		Dialogs.showAlert(
			title: "\(errorDescription): \(recoverySuggestion)"
		)
	}

}
