//
//  ContainerRefactorer.swift
//  Sidekick
//
//  Created by John Bean on 2/23/25.
//

import Foundation
import FSKit_macOS
import AppKit

public class ContainerRefactorer {
	
	/// Function 
	@MainActor
	static func refactor() {
		// Init check for refactor
		var didRefactor: [Bool] = []
		didRefactor.append(Self.relocateOutOfSandbox())
		didRefactor.append(Self.relocateIntoContainer())
		// Present dialog if needed
		if didRefactor.contains(true) {
			Dialogs.showAlert(
				title: String(localized: "Restart Sidekick"),
				message: String(localized: "To properly load your content, please restart Sidekick.")
			)
			NSApplication.shared.terminate(nil)
		}
	}
	
	/// Function to move folders out of the app's sandbox
	@MainActor
	static func relocateOutOfSandbox() -> Bool {
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
			return true
		}
		return false
	}
	
	/// Function to relocate into new container within application support
	@MainActor
	static func relocateIntoContainer() -> Bool {
		// Create container directory
		FileManager.createDirectory(
			at: Settings.containerUrl,
			withIntermediateDirectories: true
		)
		// List directory names
		let directoryNames: [String] = [
			"Cache",
			"Commands",
			"Conversations",
			"Models",
			"Profiles",
			"Sources",
			"Generated Images",
			"Resources"
		]
		// Move directories
		var didRelocate: Bool = false
		for directoryName in directoryNames {
			let sourceURL: URL = URL
				.applicationSupportDirectory
				.appendingPathComponent(directoryName)
			let destinationURL: URL = Settings
				.containerUrl
				.appendingPathComponent(directoryName)
			// Continue if source URL exists
			if !sourceURL.fileExists { continue }
			didRelocate = true
			FileManager.moveItem(
				from: sourceURL,
				to: destinationURL,
				replacing: true
			)
		}
		// Return if relocated
		return didRelocate
	}
	
}
