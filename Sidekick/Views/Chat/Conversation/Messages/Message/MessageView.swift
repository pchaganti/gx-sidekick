//
//  MessageView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageView: View {
	
	init(
		message: Message,
		canEdit: Bool = true
	) {
		self.messageText = message.text
		self.message = message
		self.canEdit = canEdit
	}
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var conversationState: ConversationState
	@EnvironmentObject private var promptController: PromptController
	
	@State private var isEditing: Bool = false
	@State private var messageText: String
	@State private var isShowingSources: Bool = false
	
	var viewReferenceTip: ViewReferenceTip = .init()
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var message: Message
	
	private var isGenerating: Bool {
		return !message.outputEnded && message.getSender() == .assistant
	}
	
	var canEdit: Bool
	
	var sources: Sources? {
		SourcesManager.shared.getSources(
			id: message.id
		)
	}
	
	var showSources: Bool {
		let hasSources: Bool = !(sources?.sources.isEmpty ?? true)
		return hasSources && self.message.getSender() == .user
	}
	
	private var timeDescription: String {
		return message.startTime.formatted(
			date: .abbreviated,
			time: .shortened
		)
	}
	
    var body: some View {
		HStack(
			alignment: .top,
			spacing: 0
		) {
			message.icon
				.padding(.trailing, 10)
			VStack(
				alignment: .leading,
				spacing: 8
			) {
				HStack {
					Text(timeDescription)
						.foregroundStyle(.secondary)
					if showSources {
						sourcesButton
					}
					MessageCopyButton(
						message: message
					)
					MessageOptionsView(
						isEditing: $isEditing,
						message: message,
						canEdit: canEdit
					)
					if self.isGenerating {
						stopButton
					}
				}
				content
			}
		}
		.padding(.trailing)
		.sheet(isPresented: $isShowingSources) {
			SourcesView(
				isShowingSources: $isShowingSources,
				sources: self.sources!
			)
			.frame(minWidth: 600, minHeight: 650, maxHeight: 700)
		}
    }
	
	var content: some View {
		Group {
			// Check for blank message
			if message.text.isEmpty && message.imageUrl == nil && message
				.getSender() == .assistant {
				RetryButton {
					self.retryGeneration()
				}
				.padding(11)
			} else {
				switch message.contentType {
					case .text:
						textContent
					case .image:
						imageContent
				}
			}
		}
		.background {
			MessageBackgroundView()
				.contextMenu {
					copyButton
				}
		}
	}
	
	var imageContent: some View {
		message.image
			.padding(0.5)
	}
	
	var textContent: some View {
		Group {
			if isEditing {
				contentEditor
			} else {
				VStack(
					alignment: .leading,
					spacing: 4
				) {
					// Show reasoning process if availible
					if self.message.hasReasoning {
						MessageReasoningProcessView(message: self.message)
							.if(!self.message.responseText.isEmpty) { view in
								view.padding(.bottom, 6)
							}
					}
					// Show message response
					MessageContentView(text: self.message.responseText)
					// Show references if needed
					if !self.message.referencedURLs.isEmpty {
						messageReferences
					}
				}
			}
		}
		.padding(11)
	}
	
	var contentEditor: some View {
		VStack {
			TextEditor(text: $messageText)
				.frame(minWidth: 0, maxWidth: .infinity)
				.font(.title3)
			HStack {
				Button {
					isEditing.toggle()
				} label: {
					Text("Cancel")
				}
				Button {
					withAnimation(
						.linear(duration: 0.5)
					) {
						self.isEditing.toggle()
					}
					self.updateMessage()
				} label: {
					Text("Save")
				}
				.keyboardShortcut("s", modifiers: .command)
			}
		}
	}
	
	var sourcesButton: some View {
		SourcesButton(showSources: $isShowingSources)
			.menuStyle(.circle)
			.foregroundStyle(.secondary)
			.disabled(!showSources)
			.padding(0)
			.padding(.vertical, 2)
	}
	
	var stopButton: some View {
		StopGenerationButton {
			self.stopGeneration()
		}
		.menuStyle(.circle)
		.foregroundStyle(.secondary)
		.disabled(!isGenerating)
		.padding(0)
		.padding(.vertical, 2)
	}
	
	var copyButton: some View {
		Button {
			self.message.text.copyWithFormatting()
		} label: {
			Text("Copy to Clipboard")
		}
	}
	
	var messageReferences: some View {
		VStack(
			alignment: .leading
		) {
			Text("References:")
				.bold()
				.font(.body)
				.foregroundStyle(Color.secondary)
			ForEach(
				self.message.referencedURLs.indices,
				id: \.self
			) { index in
				self.message.referencedURLs[index].openButton
					.if(index == 0) { view in
						view.popoverTip(
							viewReferenceTip,
							arrowEdge: .top
						) { action in
							// Open reference
							self.message.referencedURLs[index].open()
						}
					}
			}
		}
		.padding(.top, 8)
		.onAppear {
			ViewReferenceTip.hasReference = true
		}
	}
	
	/// Function to stop generation
	private func stopGeneration() {
		Task.detached { @MainActor in
			await self.model.interrupt()
			self.retryGeneration()
		}
	}
	
	private func retryGeneration() {
		// Get conversation
		guard var conversation = selectedConversation else { return }
		// Get last user sent message
		var count: Int = 1
		var prevMessage: Message? = conversation.messages.last
		while prevMessage?.getSender() != .user {
			prevMessage = conversation.messages.dropLast(count).last
			count += 1
		}
		guard prevMessage != nil else { return }
		// Set prompt
		self.promptController.prompt = prevMessage?.text ?? ""
		// Delete messages
		conversation.messages = conversation.messages.dropLast(count)
		conversationManager.update(conversation)
	}
	
	private func updateMessage() {
		guard var conversation = selectedConversation else { return }
		var message: Message = self.message
		message.text = messageText
		conversation.updateMessage(message)
		conversationManager.update(conversation)
	}
	
}
