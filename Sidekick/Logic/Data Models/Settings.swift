//
//  Settings.swift
//  Sidekick
//
//  Created by Bean John on 9/23/24.
//

import Foundation
import AppKit
import FSKit_macOS
import UniformTypeIdentifiers

public class Settings {
	
	/// Static constant for the `gguf` UniformTypeIdentifier
	static let ggufType: UTType = UTType("com.npc-pet.Chats.gguf") ?? .data
	
	/// Computed property for whether the app's setup was completed
	static var setupComplete: Bool {
		get {
			return UserDefaults.standard.bool(
				forKey: "setupComplete"
			) && Self.hasModel
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "setupComplete")
		}
	}
	
	/// Static constant for the LLM directory
	static let dirUrl: URL = URL
		.applicationSupportDirectory
		.appendingPathComponent("Sidekick")
	
	/// Computed property for the LLM's location
	static var modelUrl: URL? {
		get {
			let result: URL
			if let url = UserDefaults.standard.url(forKey: "modelUrl") {
				result = url
			} else {
				// Get default
				if let modelUrl: URL = Self.dirUrl.contents?.first {
					result = modelUrl
				} else {
					// If no model, return nil
					return nil
				}
			}
			return result
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "modelUrl")
		}
	}
	
	/// Function to check if an LLM exists
	static var hasModel: Bool {
		if let modelUrl = Self.modelUrl {
			// Return if model was located
			return modelUrl.fileExists
		} else {
			// No model
			return false
		}
	}
	
	/// Function to select a model
	@MainActor static func selectModel() -> Bool {
		if let modelUrls = try? FileManager.selectFile(
			dialogTitle: "Select a Model",
			canSelectDirectories: false,
			allowedContentTypes: [Self.ggufType],
			allowMultipleSelection: false,
			persistPermissions: true
		) {
			// Set and signal success
			Self.modelUrl = modelUrls.first
			return true
		} else {
			// Signal failure
			return false
		}
	}
	
	/// Function to clear user defaults (for debug uses)
	@MainActor static func clearUserDefaults() {
		// Show dialog
		let _ = Dialogs.showConfirmation(
			title: "Are you sure you want clear all Settings? This will delete all settings and quit Sidekick."
		) {
			// If "yes"
			UserDefaults.standard.dictionaryRepresentation().keys.forEach({
				UserDefaults.standard.removeObject(forKey: $0)
			})
			// Set defaults
			Settings.setDefaults()
			InferenceSettings.setDefaults()
			NSApplication.shared.terminate(nil)
		}
	}
	
	/// Computed property that determines whether the setup screen should be shown
	static var showSetup: Bool {
		return !Self.setupComplete || !Self.hasModel
	}
	
	/// Function to set defaults
	static func setDefaults() {
		Settings.setupComplete = false
	}
	
	/// Function to finish setup
	static func finishSetup() {
		Settings.setupComplete = true
		InferenceSettings.setDefaults()
	}
	
}
