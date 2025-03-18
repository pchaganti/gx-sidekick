//
//  RetrievalSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation
import SecureDefaults

public class RetrievalSettings {

	/// Computed property for Tavily API key
	public static var tavilyApiKey: String {
		set {
			let defaults: SecureDefaults = SecureDefaults.defaults()
			defaults.set(newValue, forKey: "apiKey")
		}
		get {
			let defaults: SecureDefaults = SecureDefaults.defaults()
			return defaults.string(forKey: "apiKey") ?? ""
		}
	}
	
	/// Computed property for backup Tavily API key
	public static var tavilyBackupApiKey: String {
		set {
			let defaults: SecureDefaults = SecureDefaults.defaults()
			defaults.set(newValue, forKey: "backupApiKey")
		}
		get {
			let defaults: SecureDefaults = SecureDefaults.defaults()
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
	
	/// A `Bool` representing whether web search can be used
	static var canUseWebSearch: Bool {
		return Self.useTavilySearch && !Self.tavilyApiKey.isEmpty
	}
	
	/// Computed property for whether the context of a search result is used
	static var useSearchResultContext: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "useSearchResultContext") {
				// Default to true for more content
				Self.useSearchResultContext = true
			}
			return UserDefaults.standard.bool(
				forKey: "useSearchResultContext"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "useSearchResultContext")
		}
	}
	
	/// Computed property for how many search results are returned
	static var searchResultsMultiplier: Int {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "searchResultsMultiplier") {
				Self.searchResultsMultiplier = 3
			}
			return UserDefaults.standard.integer(
				forKey: "searchResultsMultiplier"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "searchResultsMultiplier")
		}
	}
	
}
