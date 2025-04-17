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
	
	/// A `Bool` representing whether web search can be used
	static var canUseWebSearch: Bool {
        // Get provider
        let provider: SearchProvider = SearchProvider(
            rawValue: Self.defaultSearchProvider
        ) ?? .duckDuckGo
        // Check for each provider
        switch provider {
            case .duckDuckGo:
                return true
            case .tavily:
                return !Self.tavilyApiKey.isEmpty
        }
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
    
    /// The default search provider, where 0 = DuckDuckGo, 1 = Tavily
    static var defaultSearchProvider: Int {
        get {
            // Default to DuckDuckGo
            if !UserDefaults.standard.exists(key: "defaultSearchProvider") {
                Self.defaultSearchProvider = 0
            }
            return UserDefaults.standard.integer(
                forKey: "defaultSearchProvider"
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultSearchProvider")
        }
    }
    
    /// Search providers supported by Sidekick
    public enum SearchProvider: Int, CaseIterable {
        
        case duckDuckGo = 0
        case tavily = 1
        
    }
	
}
