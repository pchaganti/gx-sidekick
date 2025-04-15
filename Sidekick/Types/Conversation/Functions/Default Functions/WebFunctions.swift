//
//  WebFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/15/25.
//

import ExtractKit_macOS
import Foundation

public class WebFunctions {
    
    static var functions: [AnyFunctionBox] = [
        WebFunctions.webSearch,
        WebFunctions.getWebsiteContent
    ]
    
    /// A function to check if a web function was used
    public static func includesWebFunction(
        functionNames: [String]
    ) -> Bool {
        return WebFunctions.functions.contains { function in
            functionNames.contains(function.name)
        }
    }
    
    /// A ``Function`` to conduct a web search
    static let webSearch = Function<WebSearchParams, String>(
        name: "web_search",
        description: "Retrieves information from the web with the provided query, instead of estimating it.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "query",
                description: "The topic to look up online",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "num_results",
                description: "The maximum number of search results (optional, default: 5)",
                datatype: .integer,
                isRequired: false
            )
        ],
        run: { params in
            // Check if enabled
            if !RetrievalSettings.canUseWebSearch {
                throw WebSearchError.notEnabled
            }
            // Conduct search
            let sources: [Source] = try await TavilySearch.search(
                query: params.query,
                resultCount: params.num_results ?? 5
            )
            // Convert to JSON
            let sourcesInfo: [Source.SourceInfo] = sources.map(
                \.info
            )
            let jsonEncoder: JSONEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted]
            let jsonData: Data = try! jsonEncoder.encode(sourcesInfo)
            let resultsText: String = String(
                data: jsonData,
                encoding: .utf8
            )!
            return """
Below are the sites and corresponding content returned from your `web_search` query. The content from each site here is a summary; to get the full content from a website, use the `get_website_content` function.

\(resultsText)
"""
            // Custom error for Web Search function
            enum WebSearchError: LocalizedError {
                case notEnabled
                var errorDescription: String? {
                    switch self {
                        case .notEnabled:
                            return "Web search has not been enabled in Settings."
                    }
                }
            }
        }
    )
    struct WebSearchParams: FunctionParams {
        let query: String
        let num_results: Int?
    }
    
    /// A function to get the content of a website via its url
    static let getWebsiteContent = Function<GetWebsiteContentParams, String>(
        name: "get_website_content",
        description: "Retrieves the full content of a website via its URL.",
        params: [
            FunctionParameter(
                label: "url",
                description: "The website's URL",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Check URL
            guard let url: URL = URL(string: params.url) else {
                throw GetWebsiteContentError.invalidUrl
            }
            // Extract text
            return try await ExtractKit.shared.extractText(
                url: url,
                contentType: .website
            )
            // Custom error for Web Search function
            enum GetWebsiteContentError: LocalizedError {
                case invalidUrl
                var errorDescription: String? {
                    switch self {
                        case .invalidUrl:
                            return "The provided website URL is invalid."
                    }
                }
            }
        }
    )
    struct GetWebsiteContentParams: FunctionParams {
        let url: String
    }
    
}
