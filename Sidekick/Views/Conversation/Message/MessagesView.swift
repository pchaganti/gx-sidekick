//
//  MessagesView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct MessagesView: View {
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@Namespace var pendingViewId
	@Namespace var scrollViewId
	
	@State private var didScrollNearBottom: Bool = false
	
	@State private var prevPendingMessage: String = ""
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId = conversationState.selectedConversationId else {
			return nil
		}
		return self.conversationManager.getConversation(
			id: selectedConversationId
		)
	}
	
	var messages: [Message] {
		return self.selectedConversation?.messages ?? []
	}
	
	var lastMessageId: UUID? {
		return self.selectedConversation?.messages.last?.id
	}
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var isInverted: Bool {
		guard let luminance = selectedProfile?.color.luminance else { return false }
		return luminance > 0.5
	}
	
	var isGenerating: Bool {
		let statusPass: Bool = self.model.status == .coldProcessing || self.model.status == .processing || self.model.status == .querying
		let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
		return statusPass && conversationPass
	}
	
	var body: some View {
		ScrollViewReader { proxy in
			EndDetectionScrollView(
				.vertical,
				showIndicators: true,
				hasScrolledNearEnd: $didScrollNearBottom,
				distanceFromEnd: 75
			) {
				HStack(alignment: .top) {
					LazyVStack(
						alignment: .leading,
						spacing: 13
					) {
						Group {
							messagesView
							if isGenerating {
								PendingMessageView()
									.id(pendingViewId)
							}
						}
					}
					.padding(.vertical)
					.padding(.bottom, 150)
					Spacer()
				}
				.id(scrollViewId)
			}
			.onReceive(self.model.$pendingMessage) { _ in
				// Scroll to end if response was updated & user at bottom
				self.scrollOnUpdate(proxy: proxy)
			}
			.onReceive(self.model.$sentConversationId) { _ in
				// Scroll to end if message was sent
				proxy.scrollTo(scrollViewId, anchor: .bottom)
			}
			.onChange(
				of: self.conversationState.selectedConversationId
			) {
				// Scroll to top if conversation was changed
				proxy.scrollTo(scrollViewId, anchor: .top)
			}
		}
		.toolbar {
			ToolbarItemGroup() {
				exportButton
			}
		}
	}
	
	var messagesView: some View {
		ForEach(
			self.messages
		) { message in
			MessageView(
				message: message
			)
			.id(message.id)
		}
	}
	
	var exportButton: some View {
		Button {
			self.generatePdf()
		} label: {
			Label("Export", systemImage: "square.and.arrow.up")
		}
		.disabled(isGenerating)
		.if(isInverted) { view in
			view.colorInvert()
		}
	}
	
	/// Function to generate and save conversation as a PDF
	private func generatePdf() {
		// Select path
		guard var destination: URL = try? FileManager.selectFile(
				dialogTitle: String(localized: "Select a Save Location"),
				canSelectFiles: false,
				canSelectDirectories: true,
				allowMultipleSelection: false,
				persistPermissions: false
		).first else {
			return
		}
		let filename: String = selectedConversation?.title ?? Date.now.ISO8601Format()
		destination = destination.appendingPathComponent("\(filename).png")
		// Render and save
		let renderer: ImageRenderer = ImageRenderer(
			content: VStack(alignment: .leading, spacing: 15) { messagesView }
				.padding()
				.background(Color.gray)
				.frame(width: 1000)
		)
		renderer.scale = 2.0
		guard let cgImage: CGImage = renderer.cgImage else {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to render image.")
			)
			return
		}
		cgImage.save(to: destination)
	}
	
	/// Function to scroll to bottom when the output refreshes
	private func scrollOnUpdate(proxy: ScrollViewProxy) {
		// Check if at end
		if !self.didScrollNearBottom {
			return
		}
		// Check line count
		let lines: Int = self.model.pendingMessage.split(
			separator: "\n"
		).count
		let prevLines: Int = self.prevPendingMessage.split(
			separator: "\n"
		).count
		// Exit if equal
		if prevLines >= lines {
			prevPendingMessage = ""
			return
		} else if abs(prevLines - lines) >= 2 {
			// Else, scroll to bottom if significant change
			proxy.scrollTo(pendingViewId, anchor: .bottom)
			prevPendingMessage = self.model.pendingMessage
		}
	}
	
}

//#Preview {
//    MessagesView()
//}
