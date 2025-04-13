//
//  Refactorer.swift
//  Sidekick
//
//  Created by John Bean on 2/23/25.
//

import AppKit
import Foundation
import FSKit_macOS
import OSLog

public class Refactorer {
	
    /// A `Logger` object for the ``Refactorer`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Refactorer.self)
    )
    
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
			// Continue if destination URL exists
			if destinationURL.fileExists { continue }
			// If directory exists at source, move
			if sourceURL.fileExists {
				// Set didRelocate to true
				didRelocate = true
				FileManager.moveItem(
					from: sourceURL,
					to: destinationURL,
					replacing: true
				)
			} else {
				// Else, create the directory
				FileManager.createDirectory(
					at: destinationURL,
					withIntermediateDirectories: true
				)
			}
		}
		// Return if relocated
		return didRelocate
	}
    
    /// Function to update endpoint
    @MainActor
    static func updateEndpoint() async {
        // Update endpoint url format if needed
        if InferenceSettings.endpointFormatVersion <= 0,
           !InferenceSettings.endpoint.isEmpty {
            // Create new endpoint
            let newEndpoint: String = InferenceSettings.endpoint + "/v1"
            // Test new endpoint
            if await Model.shared.remoteServerIsReachable(
                endpoint: newEndpoint
            ) {
                // If it works, set it
                InferenceSettings.endpoint = newEndpoint
                Self.logger.info(
                    "Updated endpoint to \(newEndpoint)"
                )
            } else {
                // Else, log and show error
                Self.logger.error(
                    "Failed to update endpoint to \(newEndpoint)"
                )
                Dialogs.showAlert(
                    title: String(localized: "Endpoint Error"),
                    message: String(
                        localized: """
Sidekick has adopted OpenAI's API endpoint format. Please navigate to `Settings` -> `Inference` and update your endpoint to end with `/v1`.
"""
                    )
                )
            }
            // Update version
            InferenceSettings.endpointFormatVersion = 1
        }
    }
	
}
