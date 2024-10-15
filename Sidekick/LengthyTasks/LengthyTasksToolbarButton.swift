//
//  LengthyTasksToolbarButton.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct LengthyTasksToolbarButton: View {
	
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	@EnvironmentObject private var conversationState: ConversationState
	@EnvironmentObject private var profileManager: ProfileManager
	
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
	
	var body: some View {
		PopoverButton(arrowEdge: .bottom) {
			Label(
				"Tasks",
				systemImage: "arrow.trianglehead.2.clockwise"
			)
			.if(isInverted) { view in
				view.colorInvert()
			}
		} content: {
			LengthyTasksList()
		}
		.keyboardShortcut("t", modifiers: [.command, .shift])
	}
	
}

#Preview {
    LengthyTasksToolbarButton()
}
