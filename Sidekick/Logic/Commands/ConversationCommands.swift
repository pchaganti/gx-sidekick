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
					.keyboardShortcut(
						KeyEquivalent(
							Character(
								stringValue: String(
									ProfileManager.shared.getProfileIndex(
										profile: profile
									) + 1
								)
							)!
						),
						modifiers: .command
					)
				}
			} label: {
				Text("Profiles")
			}
		}
	}
	
}

