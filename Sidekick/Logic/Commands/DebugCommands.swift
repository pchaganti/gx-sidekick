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
				Button(
					action: ConversationManager.shared.resetDatastore
				) {
					Text("Delete All Conversations")
				}
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
					Text("Show App Support Folder in Finder")
				}
				Button {
					try? Tips.resetDatastore()
				} label: {
					Text("Reset Tips Datastore")
				}
			}
		}
	}
	
}
