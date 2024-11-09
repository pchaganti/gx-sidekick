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
		.appendingPathComponent("Models")
	
	/// Computed property for the LLM's location
	static var modelUrl: URL? {
		get {
			let result: URL
			if let url = UserDefaults.standard.url(forKey: "modelUrl") {
				result = url
			} else {
				// Get default
				if let modelUrl: URL = Self.dirUrl.contents?.compactMap({
					$0
				}).filter({
					$0.pathExtension == "gguf"
				}).first {
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
	
	
	/// Computed property for whether the app is in debug mode
	static var isDebugMode: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "isDebugMode") {
				// Default to false
				Self.isDebugMode = false
			}
			return UserDefaults.standard.bool(
				forKey: "isDebugMode"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "isDebugMode")
		}
	}
	
	/// Computed property for whether sound effects are played
	static var playSoundEffects: Bool {
		get {
			return UserDefaults.standard.bool(
				forKey: "playSoundEffects"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "playSoundEffects")
		}
	}
	
	/// Function to select a model
	@MainActor static func selectModel() -> Bool {
		if let modelUrls = try? FileManager.selectFile(
			dialogTitle: String(
				localized: "Select a Model"
			),
			canSelectDirectories: false,
			allowedContentTypes: [Self.ggufType],
			allowMultipleSelection: false,
			persistPermissions: true
		) {
			guard let modelUrl = modelUrls.first else {
				return false
			}
			// Set and signal success
			Self.modelUrl = modelUrl
			// Add to model list
			ModelManager.shared.add(modelUrl)
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
			title: String(
				localized: "Are you sure you want clear all Settings? This will delete all settings and quit Sidekick."
			)
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
