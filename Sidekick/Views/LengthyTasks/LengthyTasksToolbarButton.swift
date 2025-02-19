//
//  LengthyTasksButton.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI
import TipKit

struct LengthyTasksButton: View {
	
	var usePadding: Bool = false
	
	@Environment(\.colorScheme) var colorScheme
	
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
		let darkModeSetting: Bool = luminance > 0.5 && !usePadding
		let lightModeSetting: Bool = luminance < 0.5 && !usePadding
		return colorScheme == .dark ? darkModeSetting : lightModeSetting
	}
	
	var iconName: String {
		if #unavailable(macOS 15) {
			return "arrow.triangle.2.circlepath"
		}
		return "arrow.trianglehead.2.clockwise"
	}
	
	var lengthyTasksProgressTip: LengthyTasksProgressTip = .init()
	
	var body: some View {
		PopoverButton(arrowEdge: .trailing) {
			Label(
				String(localized: "Tasks")
			) {
				Image(systemName: self.iconName)
					.if(lengthyTasksController.hasTasks) { view in
						view
							.padding([.top, .trailing], 2)
							.overlay(
								alignment: .topTrailing
							) {
								Circle()
									.fill(Color.red)
									.frame(width: 8)
							}
					}
			}
			.font(.headline)
			.fontWeight(.regular)
			.if(usePadding) { view in
				view
					.foregroundStyle(Color.secondary)
					.padding(7)
					.padding(.horizontal, 2)
			}
			.if(isInverted) { view in
				view.colorInvert()
			}
		} content: {
			LengthyTasksList()
		}
		.keyboardShortcut("t", modifiers: [.command, .shift])
		.popoverTip(lengthyTasksProgressTip)
	}
	
}
