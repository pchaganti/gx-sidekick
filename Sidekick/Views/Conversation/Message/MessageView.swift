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
	
	private var theme: Splash.Theme {
		// NOTE: We are ignoring the Splash theme font
		switch colorScheme {
			case ColorScheme.dark:
				return .wwdc17(withFont: .init(size: 16))
			default:
				return .sunset(withFont: .init(size: 16))
		}
	}
	
	var viewReferenceTip: ViewReferenceTip = .init()
	
	private var isGenerating: Bool {
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
				contentViewer
			}
		}
		.padding(11)
		.transition(
			.scale(1.0, anchor: .topLeading)
		)
		.background {
			MessageBackgroundView()
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
					.if(index == 0) { view in
						view.popoverTip(viewReferenceTip)
					}
			}
		}
		.padding(.top, 8)
		.onAppear {
			ViewReferenceTip.hasReference = true
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
		.disabled(isGenerating)
		.padding(0)
		.padding(.vertical, 2)
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
	
	var optionsMenu: some View {
		Group {
			Button {
				message.displayedText.copy()
			} label: {
				Text("Copy to Clipboard")
			}
			// Edit button
			if self.canEdit && !self.isEditing {
				Button {
					if self.canEdit {
						withAnimation(
							.linear(duration: 0.5)
						) {
							self.isEditing.toggle()
						}
					}
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
