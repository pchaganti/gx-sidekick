//
//  ConversationView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationView: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var body: some View {
		MessagesView()
			.padding(.leading)
			.overlay(alignment: .bottom) {
				ConversationControlsView()
					.padding(.trailing, 40)
			}
	}
	
}

//#Preview {
//    ConversationView()
//}
