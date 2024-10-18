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
	
	@Environment(\.colorScheme) private var colorScheme
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@State private var showNerdInfo: Bool = false
	
	@State private var isEditing: Bool = false
	@State private var messageText: String
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var message: Message
	var canEdit: Bool
	
	private var theme: Splash.Theme {
		// NOTE: We are ignoring the Splash theme font
		switch colorScheme {
			case ColorScheme.dark:
				return .wwdc17(withFont: .init(size: 16))
			default:
				return .sunset(withFont: .init(size: 16))
		}
	}
	
	private var isOptionsDisabled: Bool {
		return !message.outputEnded && message.getSender() == .assistant
	}
	
	private var nerdInfo: String {
		var tokensPerSecondStr: String = "Unknown"
		if let tokensPerSecond = message.tokensPerSecond {
			tokensPerSecondStr = "\(round(tokensPerSecond * 10) / 10)"
		}
		let infoDescription: String.LocalizationValue = """
Model: \(message.model)
Tokens per second: \(tokensPerSecondStr)
"""
		return String(localized: infoDescription)
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
					options
				}
				content
			}
		}
    }
	
	var content: some View {
		Group {
			if isEditing {
				contentEditor
			} else {
				contentViewer
			}
		}
	}
	
	var contentViewer: some View {
		VStack(alignment: .leading) {
			Markdown(message.displayedText)
				.markdownTheme(.gitHub)
				.markdownCodeSyntaxHighlighter(
					.splash(theme: self.theme)
				)
				.textSelection(.enabled)
			if !message.referencedURLs.isEmpty {
				messageReferences
			}
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
				message.referencedURLs.indices,
				id: \.self
			) { index in
				message.referencedURLs[index].openButton
			}
		}
		.padding(.top, 8)
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
					isEditing.toggle()
					self.updateMessage()
				} label: {
					Text("Save")
				}
				.keyboardShortcut("s", modifiers: .command)
			}
		}
	}
	
	var options: some View {
		Menu(content: {
			optionsMenu
		}, label: {
			Image(systemName: "ellipsis.circle")
				.imageScale(.medium)
				.background(.clear)
				.imageScale(.small)
				.padding(.leading, 1)
				.padding(.horizontal, 3)
				.frame(width: 15, height: 15)
				.scaleEffect(CGSize(width: 0.96, height: 0.96))
				.background(.primary.opacity(0.00001)) // Needs to be clickable
		})
		.menuStyle(.circle)
		.popover(isPresented: $showNerdInfo) {
			Text(nerdInfo)
				.padding(12)
				.font(.caption)
				.textSelection(.enabled)
		}
		.disabled(isOptionsDisabled)
		.padding(0)
		.padding(.vertical, 2)
	}
	
	var optionsMenu: some View {
		Group {
			Button {
				message.text.copy()
			} label: {
				Text("Copy to Clipboard")
			}
			// Edit button
			if self.canEdit && !self.isEditing {
				Button {
					if self.canEdit { self.isEditing.toggle() }
				} label: {
					Text("Edit")
				}
			}
			// Show info for bots
			if message.getSender() == .assistant {
				Button {
					showNerdInfo.toggle()
				} label: {
					Text("Stats for Nerds")
				}
			}
		}
	}
	
	private func updateMessage() {
		guard var conversation = selectedConversation else { return }
		var message: Message = self.message
		message.text = messageText
		conversation.updateMessage(message)
		conversationManager.update(conversation)
	}
	
}

//#Preview {
//	MessageView()
//}
