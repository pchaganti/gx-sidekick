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
	
	static private var profiles: [Profile] {
		return ProfileManager.shared.profiles
	}
	
	static var profileCommands: some Commands {
		CommandGroup(after: .newItem) {
			Menu {
				ForEach(
					Self.profiles
				) { profile in
					ProfileSelectionButton(
						profile: profile
					)
				}
			} label: {
				Text("Profiles")
			}
		}
	}
	
	private struct ProfileSelectionButton: View {
		
		public var profile: Profile
		
		private var index: Int {
			return ProfileManager.shared.getProfileIndex(
				profile: profile
			) + 1
		}
		
		public var body: some View {
			Button {
				AppState.setCommandSelectedProfileId(
					profile.id
				)
				NotificationCenter.default.post(
					name: Notifications.didCommandSelectProfile.name,
					object: nil
				)
			} label: {
				Text(profile.name)
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
		
	}
	
}
