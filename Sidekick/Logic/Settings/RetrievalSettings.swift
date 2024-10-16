//
//  RetrievalSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation
import SecureDefaults

public class RetrievalSettings {
	
	/// Function that returns secure defaults obkect
	private static func secureDefaults() -> SecureDefaults {
		// Init secure defaults object
		let defaults: SecureDefaults = SecureDefaults.shared
		if !defaults.isKeyCreated {
			defaults.password = UUID().uuidString
		}
		return defaults
	}

	/// Computed property for API key
	public static var apiKey: String {
		set {
			let defaults: SecureDefaults = self.secureDefaults()
			defaults.set(newValue, forKey: "apiKey")
		}
		get {
			let defaults: SecureDefaults = self.secureDefaults()
			return defaults.string(forKey: "apiKey") ?? ""
		}
	}
	
	/// Computed property for backup API key
	public static var backupApiKey: String {
		set {
			let defaults: SecureDefaults = self.secureDefaults()
			defaults.set(newValue, forKey: "backupApiKey")
		}
		get {
			let defaults: SecureDefaults = self.secureDefaults()
			return defaults.string(forKey: "backupApiKey") ?? ""
		}
	}
	
	/// Computed property for whether tavily search is used
	static var useTavilySearch: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "useTavilySearch") {
				Self.useTavilySearch = false
			}
			return UserDefaults.standard.bool(
				forKey: "useTavilySearch"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "useTavilySearch")
		}
	}
	
}
