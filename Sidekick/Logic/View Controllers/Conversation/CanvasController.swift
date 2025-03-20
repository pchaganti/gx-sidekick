//
//  CanvasController.swift
//  Sidekick
//
//  Created by John Bean on 3/19/25.
//

import CodeEditorView
import Foundation
import SwiftUI

public class CanvasController: ObservableObject {
	
	@Published public var selectedMessageId: UUID? = nil
	@Published public var isExtractingSnapshot: Bool = false
	
	@Published public var position: CodeEditor.Position = CodeEditor.Position()
	@Published public var selection: String = ""
	
	/// Function to extract a snapshot from the selected conversation
	@MainActor
	public func extractSnapshot(
		selectedConversation: Conversation?
	) async throws {
		// If is extracting, exit
		if self.isExtractingSnapshot { return }
		// Reset selection
		self.position = CodeEditor.Position()
		// Get most recent assistant message
		guard var selectedConversation else {
			throw Snapshot.ExtractionError.noSelectedConversation
		}
		let assistantMessages = selectedConversation.messages.filter { message in
			return message.getSender() == .assistant
		}
		guard var assistantMessage = assistantMessages.last else {
			throw Snapshot.ExtractionError.noAssistantMessages
		}
		guard let userMessage = selectedConversation.messages.previousElement(
			of: assistantMessage
		), userMessage.getSender() == .user else {
			throw Snapshot.ExtractionError.couldNotLocateUserMessage
		}
		// Return if snapshot already exists
		if assistantMessage.snapshot != nil {
			withAnimation(.linear) {
				self.isExtractingSnapshot = false
			}
			throw Snapshot.ExtractionError.alreadyExtractedSnapshot
		}
		// Flip status to extracting
		withAnimation(.linear) {
			self.isExtractingSnapshot = true
		}
		// Use worker model to extract content
		let fullText: String = assistantMessage.responseText
		// Put together messages
		let systemPrompt: String = InferenceSettings.systemPrompt
		let extractPrompt: String = """
A assistant has been given the following instruction to generate a piece of content. 

```
\(userMessage.text)
```

Extract the content that the assistant generated based on the instruction. DO NOT add additional Markdown formatting. DO NOT KEEP the assistant's statements and comments. Respond with the content ONLY. 

```
\(fullText)
```
"""
		let messages: [Message] = [
			Message(text: systemPrompt, sender: .system),
			Message(text: extractPrompt, sender: .user)
		]
		// Indicate background task
		Model.shared.indicateStartedBackgroundTask()
		guard let response: LlamaServer.CompleteResponse = try? await Model.shared.listenThinkRespond(
			messages: messages,
			modelType: .worker,
			mode: .default
		) else {
			withAnimation(.linear) {
				self.isExtractingSnapshot = false
			}
			throw Snapshot.ExtractionError.failedToExtractSnapshot
		}
		// Formulate snapshot
		let snapshot: Snapshot = Snapshot(
			text: response.text.reasoningRemoved.trimmingWhitespaceAndNewlines()
		)
		// Update message and conversation
		assistantMessage.snapshot = snapshot
		selectedConversation.updateMessage(assistantMessage)
		ConversationManager.shared.update(selectedConversation)
		// Set view to new snapshot
		withAnimation(.linear) {
			self.selectedMessageId = assistantMessage.id
			self.isExtractingSnapshot = false
		}
	}
	
}
