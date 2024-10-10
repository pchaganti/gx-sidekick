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
	
	@Namespace var pendingViewId
	@Namespace var scrollViewId
	
	@State private var didScrollNearBottom: Bool = false
	
	@State private var prevPendingMessage: String = ""
	
	@Binding var selectedConversationId: UUID?
	
	var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
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
	
	var showPendingMessage: Bool {
		let statusPass: Bool = self.model.status == .coldProcessing || self.model.status == .processing
		let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
		return statusPass && conversationPass
	}
	
	var body: some View {
		ScrollViewReader { proxy in
			EndDetectionScrollView(
				.vertical,
				showIndicators: true,
				hasScrolledNearEnd: $didScrollNearBottom,
				distanceFromEnd: 200
			) {
				HStack(alignment: .top) {
					LazyVStack(
						alignment: .leading,
						spacing: 13
					) {
						ForEach(self.messages) { message in
							MessageView(
								message: message
							)
							.id(message.id)
						}
						if showPendingMessage {
							PendingMessageView()
								.id(pendingViewId)
						}
					}
					.padding(.vertical)
					.padding(.bottom, 55)
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
			.onChange(of: self.selectedConversationId) {
				// Scroll to top if conversation was changed
				proxy.scrollTo(scrollViewId, anchor: .top)
			}
		}
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
