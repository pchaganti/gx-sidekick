//
//  DebugCommands.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import Foundation
import SwiftUI
import TipKit

@MainActor
public class DebugCommands {
	
	static var commands: some Commands {
        CommandGroup(after: .help) {
			Menu("Debug") {
				Self.debugSettings
				Self.debugConversations
				Button(
					action: ExpertManager.shared.resetDatastore
				) {
					Text("Delete All Experts")
				}
				Button {
					FileManager.showItemInFinder(
						url: Settings.containerUrl
					)
				} label: {
					Text("Show Container in Finder")
				}
			}
		}
	}
	
	private static var debugSettings: some View {
		Menu("Settings") {
			Button(
				action: Settings.clearUserDefaults
			) {
				Text("Clear All Settings")
			}
			Button(
				action: InferenceSettings.setDefaults
			) {
				Text("Set Inference Settings to Defaults")
			}
		}
	}
	
	private static var debugConversations: some View {
		Menu("Conversations") {
			Button(
				action: ConversationManager.shared.createBackup
			) {
				Text("Backup Conversations")
			}
			if ConversationManager.shared.backupExists {
				Button(
					action: ConversationManager.shared.retoreFromBackup
				) {
					Text("Restore Conversations from Backup")
				}
			}
			Button(
				action: ConversationManager.shared.resetDatastore
			) {
				Text("Delete All Conversations")
			}
		}
	}
	
}
