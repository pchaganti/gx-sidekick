//
//  WebSearch.swift
//  Sidekick
//
//  Created by John Bean on 4/17/25.
//

import Foundation

public class WebSearch {
    
    /// Function to search the web for sources
    public static func search(
        query: String,
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
                    resultCount: resultCount
                )
            case .tavily:
                // Try with first key
                results = try? await TavilySearch.search(
                    query: query,
                    resultCount: resultCount
                )
                if results == nil {
                    // Try with backup key
                    results = try await TavilySearch.search(
                        query: query,
                        resultCount: resultCount,
                        useBackupApi: true
                    )
                }
        }
        // Return
        return results ?? []
    }
    
}
