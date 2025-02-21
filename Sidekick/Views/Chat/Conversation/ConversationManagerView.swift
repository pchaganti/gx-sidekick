//
//  ConversationManagerView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI
import Combine

struct ConversationManagerView: View {
	
	@Environment(\.appearsActive) var appearsActive
	
	@StateObject private var model: Model = .shared
	
	@EnvironmentObject private var appState: AppState
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	
	@EnvironmentObject private var conversationState: ConversationState
	
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	
	@State private var isViewingExtensions: Bool = false
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var toolbarTextColor: Color {
		guard let luminance = selectedProfile?.color.luminance else {
			return .accentColor
		}
		return (luminance > 0.5) ? .toolbarText : .white
	}
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var contextIsFull: Bool {
		// Get token count
		guard let tokenCount = selectedConversation?.tokenCount else { return false }
		// Return whether context length is full
		return tokenCount > InferenceSettings.contextLength
	}
	
	var navTitle: String {
		return self.selectedConversation?.title ?? String(
			localized: "Conversations"
		)
	}
	
    var body: some View {
		NavigationSplitView {
			conversationList
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
					.opacity(0.9)
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
			ToolbarItemGroup(placement: .primaryAction) {
				Spacer()
				if InferenceSettings.lowUnifiedMemory {
					lowMemoryWarning
				}
				if self.contextIsFull {
					contextFullWarning
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
			self.refreshSystemPrompt()
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.systemPromptChanged.name
			)
		) { output in
			self.refreshSystemPrompt()
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.changedInferenceConfig.name
			)
		) { output in
			self.refreshModel()
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.newConversation.name
			)
		) { output in
			withAnimation(.linear) {
				self.conversationState.selectedProfileId = profileManager.default?.id
			}
			if let recentConversationId = conversationManager.recentConversation?.id {
				withAnimation(.linear) {
					self.conversationState.selectedConversationId = recentConversationId
				}
			}
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: Notifications.didCommandSelectProfile.name
			)
		) { output in
			// Update profile if needed
			if self.appearsActive {
				withAnimation(.linear) {
					self.conversationState.selectedProfileId = self.appState.commandSelectedProfileId
				}
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
	
	var conversationList: some View {
		VStack(
			alignment: .leading,
			spacing: 3
		) {
			ConversationNavigationListView()
			Spacer()
			sidebarButtons
		}
		.padding(.vertical, 7)
	}
	
	var conversationView: some View {
		Group {
			if conversationState.selectedConversationId == nil || selectedConversation == nil {
				noSelectedConversation
			} else {
				ConversationView()
					.frame(minWidth: 450, minHeight: 500)
			}
		}
	}
	
	var noSelectedConversation: some View {
		HStack {
			Text("Hit")
			Button("Command ⌘ + N") {
				self.newConversation()
			}
			Text("to start a conversation.")
		}
	}
	
	var lowMemoryWarning: some View {
		PopoverButton {
			Label("Low Memory", systemImage: "exclamationmark.triangle.fill")
				.foregroundStyle(.yellow)
		} content: {
			Text("Your system has only \(InferenceSettings.unifiedMemorySize) GB of RAM, which may not be sufficient for running an AI model. \nPlease save progress in all open apps, and close memory hogging applications **in case a system crash occurs.**")
				.padding()
		}
	}
	
	var contextFullWarning: some View {
		PopoverButton {
			Label("Context Full", systemImage: "brain.fill")
				.foregroundStyle(.red)
		} content: {
			Text("The AI model's context is full and may forget earlier chat history. Start a new conversation to clear context.")
				.padding()
		}
	}
	
	var sidebarButtons: some View {
		Group {
			if self.lengthyTasksController.hasTasks {
				LengthyTasksNavigationButton()
					.buttonStyle(.plain)
					.foregroundStyle(.secondary)
			}
			SidebarButtonView(
				title: String(localized: "Extensions"),
				systemImage: "puzzlepiece.extension.fill"
			) {
				self.isViewingExtensions.toggle()
			}
			.keyboardShortcut("e", modifiers: [.command])
			.sheet(isPresented: $isViewingExtensions) {
				ExtensionsLibraryView(
					isPresented: $isViewingExtensions
				)
			}
			SidebarButtonView(
				title: String(localized: "New Conversation"),
				systemImage: "square.and.pencil"
			) {
				self.newConversation()
			}
		}
		.padding(.horizontal, 5)
	}
	
	private func newConversation() {
		// Create new conversation
		ConversationManager.shared.newConversation()
		// Reset selected profile
		withAnimation(.linear) {
			conversationState.selectedProfileId = profileManager.default?.id
		}
		// Select newly created conversation
		if let recentConversationId = conversationManager.recentConversation?.id {
			withAnimation(.linear) {
				self.conversationState.selectedConversationId = recentConversationId
			}
		}
	}
	
	private func refreshModel() {
		// Refresh model
		Task {
			await self.model.refreshModel()
		}
	}
	
	private func refreshSystemPrompt() {
		// Set new prompt
		var prompt: String = InferenceSettings.systemPrompt
		if let systemPrompt = self.selectedProfile?.systemPrompt {
			prompt = systemPrompt
		}
		Task {
			await self.model.setSystemPrompt(prompt)
		}
	}
	
}
