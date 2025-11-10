//
//  WebSearch.swift
//  Sidekick
//
//  Created by John Bean on 4/17/25.
//

import Foundation
import GoogleSearch

public class WebSearch {
    
    /// Function to search the web for sources
    public static func search(
        query: String,
        site: String? = nil,
        resultCount: Int
    ) async throws -> [Source] {
        // Get provider
        let provider: RetrievalSettings.SearchProvider = .init(
            rawValue: RetrievalSettings.defaultSearchProvider
        ) ?? .duckDuckGo
        // Handle for each provider
        var results: [Source]? = nil
        switch provider {
            case .duckDuckGo:
                // Search with DuckDuckGo
                results = try await DuckDuckGoSearch.search(
                    query: query,
                    site: site,
                    resultCount: resultCount
                )
            case .google:
                // Search with Google
                let searchResults = try await GoogleSearch.search(
                    query: query,
                    site: site,
                    resultCount: resultCount
                )
                results = searchResults.map { searchResult in
                    return Source(
                        text: searchResult.text,
                        source: searchResult.url
                    )
                }
            case .tavily:
                // Try with first key
                results = try? await Tavily.search(
                    query: query,
                    site: site,
                    resultCount: resultCount
                )
                if results == nil {
                    // Try with backup key
                    results = try await Tavily.search(
                        query: query,
                        site: site,
                        resultCount: resultCount,
                        useBackupKey: true
                    )
                }
        }
        // Return
        return results ?? []
    }
    
}
