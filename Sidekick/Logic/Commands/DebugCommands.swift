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
			Button(action: Settings.clearUserDefaults) {
				Text("Clear All Settings")
			}
			Button(action: InferenceSettings.setDefaults) {
				Text("Set Inference Settings to Defaults")
			}
			Button(action: ConversationManager.shared.resetDatastore) {
				Text("Delete All Conversations")
			}
			Button {
				FileManager.showItemInFinder(
					url: URL.homeDirectory
				)
			} label: {
				Text("Open Container")
			}
		}
	}
#endif
	
}
