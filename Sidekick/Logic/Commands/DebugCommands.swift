//
//  DebugCommands.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import Foundation
import SwiftUI

@MainActor
public class DebugCommands {
	
#if DEBUG
	static var commands: some Commands {
		CommandGroup(after: .help) {
			Menu("Debug") {
				Button(action: Settings.clearUserDefaults) {
					Text("Clear All Settings")
				}
				Button(action: InferenceSettings.setDefaults) {
					Text("Set Inference Settings to Defaults")
				}
				Button(action: ConversationManager.shared.resetDatastore) {
					Text("Delete All Conversations")
				}
				Button(action: ProfileManager.shared.resetDatastore) {
					Text("Delete All Profiles")
				}
				Button {
					FileManager.showItemInFinder(
						url: URL.homeDirectory
					)
				} label: {
					Text("Show Container in Finder")
				}
				Button {
					FileManager.showItemInFinder(
						url: URL.applicationSupportDirectory
					)
				} label: {
					Text("Show App Support Folder in Finder")
				}
			}
		}
	}
#endif
	
}
