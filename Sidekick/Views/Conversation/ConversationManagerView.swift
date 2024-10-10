//
//  ConversationManagerView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationManagerView: View {
	
	init(
		selectedConversationId: Binding<UUID?>
	) {
		var systemPrompt: String = InferenceSettings.systemPrompt
		if let conversationId = selectedConversationId.wrappedValue {
			systemPrompt = ConversationManager.shared
				.getConversation(
					id: conversationId
				)?.systemPrompt ?? InferenceSettings.systemPrompt
		}
		self._model = StateObject(
			wrappedValue: Model(systemPrompt: systemPrompt)
		)
		self._selectedConversationId = selectedConversationId
	}
	
	@StateObject private var model: Model
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var navTitle: String {
		return self.selectedConversation?.title ?? "Conversations"
	}
	
    var body: some View {
		NavigationSplitView {
			ConversationNavigationListView(
				selectedConversationId: $selectedConversationId
			)
			.padding(.top)
		} detail: {
			conversationView
		}
		.navigationTitle(navTitle)
		.environmentObject(model)
		.onReceive(
			NotificationCenter.default.publisher(
				for: NSApplication.willTerminateNotification
			)
		) { output in
			/// Stop server before app is quit
			Task {
				await model.llama.stopServer()
			}
		}
    }
	
	var conversationView: some View {
		Group {
			if selectedConversationId == nil || selectedConversation == nil {
				noSelectedConversation
			} else {
				ConversationView(
					selectedConversationId: $selectedConversationId
				)
			}
		}
	}
	
	var noSelectedConversation: some View {
		HStack {
			Text("Hit")
			Button(
				"Command ⌘ + N",
				action: ConversationManager.shared.newConversation
			)
			Text("to start a conversation.")
		}
	}
	
}

//#Preview {
//	ConversationManagerView()
//}
