//
//  MessageShareMenu.swift
//  Sidekick
//
//  Created by Bean John on 10/30/24.
//

import SwiftUI

struct MessageShareMenu<MessagesView: View>: View {
	
	var messagesView: MessagesView
	
	@Environment(\.colorScheme) var colorScheme
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var messages: [Message] {
		return self.selectedConversation?.messages ?? []
	}
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var isInverted: Bool {
		guard let luminance = selectedProfile?.color.luminance else { return false }
		let darkModeResult: Bool = luminance > 0.5
		let lightModeResult: Bool = !(luminance > 0.5)
		return colorScheme == .dark ? darkModeResult : lightModeResult
	}
	
	var isGenerating: Bool {
		let statusPass: Bool = self.model.status == .coldProcessing || self.model.status == .processing || self.model.status == .querying
		let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
		return statusPass && conversationPass
	}
	
	var body: some View {
		Menu {
			pngButton
		} label: {
			Label("Export", systemImage: "square.and.arrow.up")
		}
		.disabled(isGenerating || self.messages.isEmpty)
		.if(isInverted) { view in
			view.colorInvert()
		}
	}
	
	var pngButton: some View {
		Button {
			VStack(
				alignment: .leading,
				spacing: 15
			) {
				messagesView
			}
			.padding()
			.background(Color.gray)
			.frame(width: 1000)
			.generatePng()
		} label: {
			Text("Save as Image")
		}
	}
	
}
