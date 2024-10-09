//
//  ContentView.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import FSKit_macOS
import SwiftUI

struct ContentView: View {

	@EnvironmentObject private var downloadManager: DownloadManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationManager: ConversationManager
	
	@State private var showSetup: Bool = Settings.showSetup
	@State private var selectedConversationId: UUID? = latestConversation?.id
	
	static var latestConversation: Conversation? {
		return ConversationManager.shared.conversations
			.sorted(by: \.createdAt).last
	}
	
    var body: some View {
		Group {
			ConversationManagerView(
				selectedConversationId: $selectedConversationId
			)
		}
		.sheet(isPresented: $showSetup) {
			SetupView(showSetup: $showSetup)
		}
    }
}

#Preview {
    ContentView()
}
