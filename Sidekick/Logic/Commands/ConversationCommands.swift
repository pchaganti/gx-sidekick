//
//  ConversationCommands.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import SwiftUI

@MainActor
public class ConversationCommands {
	
	static var commands: some Commands {
		CommandGroup(replacing: .newItem) {
			Button {
				ConversationManager.shared.newConversation()
			} label: {
				Text("New Conversation")
			}
			.keyboardShortcut("n", modifiers: .command)
		}
	}
	
	static private var experts: [Expert] {
		return ExpertManager.shared.experts
	}
	
	static var expertCommands: some Commands {
		CommandGroup(after: .newItem) {
			Menu {
				ForEach(
					Self.experts
				) { expert in
					ExpertSelectionButton(
						expert: expert
					)
				}
			} label: {
				Text("Experts")
			}
		}
	}
	
	private struct ExpertSelectionButton: View {
		
		public var expert: Expert
		
		private var index: Int {
			return ExpertManager.shared.getExpertIndex(
				expert: expert
			) + 1
		}
		
		public var body: some View {
			Button {
				self.selectExpert()
			} label: {
				Text(expert.name)
			}
			.if(index <= 10) { view in
				view
					.keyboardShortcut(
						KeyEquivalent(
							Character(
								stringValue: String(
									(index % 10)
								)
							)!
						),
						modifiers: .command
					)
			}
		}
		
		private func selectExpert() {
			AppState.setCommandSelectedExpertId(
				expert.id
			)
			NotificationCenter.default.post(
				name: Notifications.didCommandSelectExpert.name,
				object: nil
			)
		}
		
	}
	
}
