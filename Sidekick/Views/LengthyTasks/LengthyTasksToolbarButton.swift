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
	@EnvironmentObject private var expertManager: ExpertManager
	
	var selectedExpert: Expert? {
		guard let selectedExpertId = conversationState.selectedExpertId else {
			return nil
		}
		return expertManager.getExpert(id: selectedExpertId)
	}
	
	var isInverted: Bool {
		guard let luminance = selectedExpert?.color.luminance else { return false }
		let darkModeSetting: Bool = luminance > 0.5 && !usePadding
		let lightModeSetting: Bool = luminance < 0.5 && !usePadding
		return colorScheme == .dark ? darkModeSetting : lightModeSetting
	}
	
	var symbolName: String {
		if lengthyTasksController.hasTasks {
			return "bell.badge.fill"
		}
		return "bell.fill"
	}
	
	var lengthyTasksProgressTip: LengthyTasksProgressTip = .init()
	
	var body: some View {
		PopoverButton(
			arrowEdge: .trailing
		) {
			Label(
				String(localized: "Notifications")
			) {
				Image(systemName: symbolName)
					.symbolRenderingMode(.multicolor)
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
