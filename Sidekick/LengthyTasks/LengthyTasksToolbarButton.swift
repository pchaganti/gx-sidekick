//
//  LengthyTasksToolbarButton.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI
import TipKit

struct LengthyTasksToolbarButton: View {
	
	var usePadding: Bool = false
	
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
	
	var iconName: String {
		if #available(macOS 15, *) {
			return "arrow.trianglehead.2.clockwise"
		} else {
			return "arrow.triangle.2.circlepath"
		}
	}
	
	var lengthyTasksProgressTip: LengthyTasksProgressTip = .init()
	
	var body: some View {
		PopoverButton(arrowEdge: .bottom) {
			Label(
				"Tasks",
				systemImage: iconName
			)
			.if(isInverted) { view in
				view.colorInvert()
			}
			.if(usePadding) { view in
				view.padding(7)
			}
		} content: {
			LengthyTasksList()
		}
		.keyboardShortcut("t", modifiers: [.command, .shift])
		.popoverTip(lengthyTasksProgressTip)
	}
	
}

#Preview {
    LengthyTasksToolbarButton()
}
