//
//  AppDelegate.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import FSKit_macOS
import SwiftUI
import TipKit

public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	
	/// A object of type  `InlineAssistantController` controller
	let inlineAssistantController: InlineAssistantController = .shared
	
	/// Function that runs after the app is initialized
	public func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Relocate legacy resources
		self.relocateLegacyResources()
		// Configure Tip's data container
		try? Tips.configure(
			[
				.datastoreLocation(.applicationDefault),
				.displayFrequency(.daily)
			]
		)
		// Configure keyboard shortcuts
		ShortcutController.setDefaultShortcuts()
		ShortcutController.setupShortcut(
			name: .toggleInlineAssistant
		) {
			self.inlineAssistantController.toggleInlineAssistant()
		}
	}
	
	/// Function that runs before the app is terminated
	public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		// Remove stale sources
		SourcesManager.shared.removeStaleSources()
		// Remove non-persisted resources
		ProfileManager.shared.removeUnpersistedResources()
		return .terminateNow
	}
	
	/// Function to relocate legacy resources
	@MainActor
	func relocateLegacyResources() {
		let legacyResources: URL = URL
			.libraryDirectory
			.appendingPathComponent("Containers")
			.appendingPathComponent("com.pattonium.Sidekick")
			.appendingPathComponent("Data")
			.appendingPathComponent("Library")
			.appendingPathComponent("Application Support")
		if let contents = legacyResources.contents,
		   legacyResources.appendingPathComponent(
			"Conversations"
		   ).fileExists {
			// Move all contents
			for content in contents {
				// Skip CrashReporter and symlinks
				if content.lastPathComponent == "" || !content.hasDirectoryPath {
					continue
				}
				// Move content
				let newLocation: URL = URL
					.applicationSupportDirectory
					.appendingPathComponent(content.lastPathComponent)
				if newLocation.fileExists {
					FileManager.removeItem(at: newLocation)
				}
				FileManager.moveItem(from: content, to: newLocation)
			}
			// Move settings
			let settingsLocation: URL = URL
				.libraryDirectory
				.appendingPathComponent("Containers")
				.appendingPathComponent("com.pattonium.Sidekick")
				.appendingPathComponent("Data")
				.appendingPathComponent("Library")
				.appendingPathComponent("Preferences")
				.appendingPathComponent("com.pattonium.Sidekick.plist")
			let newSettingsLocation: URL = URL
				.libraryDirectory
				.appendingPathComponent("Preferences")
				.appendingPathComponent("com.pattonium.Sidekick.plist")
			FileManager.moveItem(
				from: settingsLocation,
				to: newSettingsLocation
			)
			// Present dialog
			Dialogs.showAlert(
				title: String(localized: "Restart Sidekick"),
				message: String(localized: "To properly load your content, please restart Sidekick.")
			)
		}
	}
	
}
