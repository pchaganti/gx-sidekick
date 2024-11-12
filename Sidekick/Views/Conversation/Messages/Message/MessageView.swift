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
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@State private var isEditing: Bool = false
	@State private var messageText: String
	@State private var isShowingSources: Bool = false
	
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
					MessageOptionsView(
						isEditing: $isEditing,
						message: message,
						canEdit: canEdit
					)
					if showSources {
						sourcesButton
					}
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
			.frame(minWidth: 600, minHeight: 800)
		}
    }
	
	var content: some View {
		Group {
			if isEditing {
				contentEditor
			} else {
				MessageContentView(message: message)
			}
		}
		.padding(11)
		.background {
			MessageBackgroundView()
				.contextMenu {
					copyButton
				}
		}
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
		StopGenerationButton()
			.menuStyle(.circle)
			.foregroundStyle(.secondary)
			.disabled(!isGenerating)
			.padding(0)
			.padding(.vertical, 2)
	}
	
	var copyButton: some View {
		Button {
			self.copy()
		} label: {
			Text("Copy to Clipboard")
		}
	}
	
	private func updateMessage() {
		guard var conversation = selectedConversation else { return }
		var message: Message = self.message
		message.text = messageText
		conversation.updateMessage(message)
		conversationManager.update(conversation)
	}
	
	/// Function to copy message text to clipboard
	private func copy() {
		self.message.displayedText.copy()
	}
	
}
