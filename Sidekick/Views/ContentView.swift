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
	
	@State private var selectedProfileId: UUID? = firstProfile?.id
	var selectedProfile: Profile? {
		guard let selectedProfileId = selectedProfileId else { return nil }
		return profileManager.getProfile(id: selectedProfileId)
	}
	@State private var isCreatingProfile: Bool = false
	
	static var latestConversation: Conversation? {
		return ConversationManager.shared.conversations
			.sorted(by: \.createdAt).last
	}
	
	static var firstProfile: Profile? {
		return ProfileManager.shared.profiles.first
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
		.toolbar {
			ToolbarItem(placement: .navigation) {
				ProfileSelectionMenu(
					selectedProfileId: $selectedProfileId,
					isCreatingProfile: $isCreatingProfile
				)
				.padding(.trailing, 5)
			}
		}
		.if(selectedProfile != nil) { view in
			return view
				.toolbarBackground(
					selectedProfile!.color,
					for: .windowToolbar
				)
		}
    }
}

#Preview {
    ContentView()
}
