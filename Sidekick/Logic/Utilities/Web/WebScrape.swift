//
//  WebScrape.swift
//  Sidekick
//
//  Created by John Bean on 5/7/25.
//

import ExtractKit_macOS
import Foundation

public class WebScrape {
 
    /// Function to scrape the content on a website
    public static func scrape(
        url: String
    ) async throws -> String {
        // Check URL
        guard let url =  URL(string: url) else {
            throw WebScrapeError.invalidUrl
        }
        // Check if user has tavily
        let hasTavilyApiKey: Bool = !RetrievalSettings.tavilyApiKey.isEmpty
        // If yes, use Tavily Extract
        if hasTavilyApiKey {
            do {
                return try await Tavily.extract(url: url.absoluteString)
            } catch {
                do {
                    return try await Tavily.extract(
                        url: url.absoluteString,
                        useBackupKey: true
                    )
                } catch {
                    return try await ExtractKit.shared.extractText(
                        url: url,
                        contentType: .website
                    )
                }
            }
        } else {
            // Extract text
            return try await ExtractKit.shared.extractText(
                url: url,
                contentType: .website
            )
        }
    }
    
    public enum WebScrapeError: LocalizedError {
        case invalidUrl
        public var errorDescription: String? {
            switch self {
                case .invalidUrl:
                    return "The provided website URL is invalid."
            }
        }
    }
    
}
