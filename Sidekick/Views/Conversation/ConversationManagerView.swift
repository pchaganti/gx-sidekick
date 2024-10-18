//
//  ConversationManagerView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI
import Combine

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
	}
	
	@StateObject private var model: Model
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var toolbarTextColor: Color {
		return selectedProfile?.color.adaptedTextColor ?? .primary
	}
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var navTitle: String {
		return self.selectedConversation?.title ?? String(
			localized: "Conversations"
		)
	}
	
    var body: some View {
		NavigationSplitView {
			ConversationNavigationListView()
			.padding(.top, 7)
		} detail: {
			conversationView
		}
		.navigationTitle("")
		.toolbar {
			ToolbarItem(placement: .navigation) {
				Text(navTitle)
					.font(.title3)
					.bold()
					.foregroundStyle(toolbarTextColor)
			}
			ToolbarItemGroup(placement: .principal) {
				ProfileSelectionMenu()
					.onChange(
						of: conversationState.selectedProfileId
					) {
						guard var selectedConversation = self.selectedConversation else {
							return
						}
						selectedConversation.profileId = self.conversationState.selectedProfileId
						self.conversationManager.update(selectedConversation)
					}
			}
			ToolbarItemGroup() {
				if InferenceSettings.lowUnifiedMemory {
					lowMemoryWarning
				}
				if #available(macOS 15, *) {
					LengthyTasksToolbarButton()
				}
			}
		}
		.if(selectedProfile != nil) { view in
			return view
				.toolbarBackground(
					selectedProfile!.color,
					for: .windowToolbar
				)
		}
		.onChange(of: selectedProfile) {
			updateSystemPrompt()
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.systemPromptChanged.name
			)
		) { output in
			updateSystemPrompt()
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.newConversation.name
			)
		) { output in
			self.conversationState.selectedProfileId = profileManager.default?.id
			if let firstConversationId = conversationManager.firstConversation?.id {
				self.conversationState.selectedConversationId = firstConversationId
			}
		}
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
		.environmentObject(model)
    }
	
	var conversationView: some View {
		Group {
			if conversationState.selectedConversationId == nil || selectedConversation == nil {
				noSelectedConversation
			} else {
				ConversationView()
			}
		}
	}
	
	var noSelectedConversation: some View {
		HStack {
			Text("Hit")
			Button("Command ⌘ + N") {
				ConversationManager.shared.newConversation()
				conversationState.selectedProfileId = profileManager.default?.id
			}
			Text("to start a conversation.")
		}
	}
	
	var lowMemoryWarning: some View {
		PopoverButton {
			Label("Low Memory", systemImage: "exclamationmark.triangle.fill")
				.foregroundStyle(.yellow)
		} content: {
			Text("Your system has only \(InferenceSettings.unifiedMemorySize) GB of RAM, which may not be sufficient for running an LLM. \nPlease save progress in all open apps, and close memory hogging applications **in case a system crash occurs.**")
				.padding()
		}
	}
	
	private func updateSystemPrompt() {
		// Set new prompt
		var prompt: String = InferenceSettings.systemPrompt
		if let systemPrompt = self.selectedProfile?.systemPrompt {
			prompt = systemPrompt
		}
		
		Task {
			await self.model.updateSystemPrompt(prompt)
		}
		// Update conversation
	}
	
}

//#Preview {
//	ConversationManagerView()
//}
