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
	@EnvironmentObject private var expertManager: ExpertManager
	@EnvironmentObject private var conversationManager: ConversationManager
	
	@StateObject private var conversationState: ConversationState = ConversationState()
	
	@State private var showSetup: Bool = Settings.showSetup
	
    var body: some View {
		Group {
			if !showSetup {
				ConversationManagerView()
			} else {
				EmptyView()
			}
		}
		.sheet(
			isPresented: $showSetup
		) {
			SetupView(
				showSetup: $showSetup
			)
		}
		.sheet(
			isPresented: $conversationState.isManagingExperts
		) {
			ExpertManagerView()
				.frame(
					minWidth: 300,
					maxWidth: 450,
					minHeight: 450,
					maxHeight: 700
				)
		}
		.environmentObject(conversationState)
    }
}

#Preview {
    ContentView()
}
