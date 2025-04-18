//
//  WebFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/15/25.
//

import AppKit
import ExtractKit_macOS
import Foundation

public class WebFunctions {
    
    static var functions: [AnyFunctionBox] = [
        WebFunctions.webSearch,
        WebFunctions.getWebsiteContent,
        WebFunctions.draftEmail,
        WebFunctions.getLocation
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
                throw WebSearchError.notConfigured
            }
            // Conduct search
            let sources: [Source] = try await WebSearch.search(
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
Below are the sites and corresponding content returned from your `web_search` query.

The content from each site here is a summary. Use the `get_website_content` function to get the full content from a website.

\(resultsText)
"""
            // Custom error for Web Search function
            enum WebSearchError: LocalizedError {
                case notConfigured
                var errorDescription: String? {
                    switch self {
                        case .notConfigured:
                            return "Web search has not been properly configured in Settings."
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
    
    /// A function to create an email draft
    static let draftEmail = Function<DraftEmailParams, String>(
        name: "draft_email",
        description: "Uses the \"mailto:\" URL scheme to create an email draft in the default email client.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "recipients",
                description: "An array containing the email addresses of the recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "cc",
                description: "An array containing the email addresses of the cc recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "bcc",
                description: "An array containing the email addresses of the cc recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "subject",
                description: "The subject of the email",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "body",
                description: "The body of the email.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Formulate URL
            var urlString: String = "mailto:"
            urlString += params.recipients.joined(separator: ",")
            // Start query parameters
            var queryItems: [String] = []
            // Add CC & BCC recipients if present
            if let cc = params.cc, !cc.isEmpty {
                queryItems.append("cc=\(cc.joined(separator: ","))")
            }
            if let bcc = params.bcc, !bcc.isEmpty {
                queryItems.append("bcc=\(bcc.joined(separator: ","))")
            }
            // Add subject & body
            if !params.subject.isEmpty {
                queryItems.append("subject=\(params.subject)")
            }
            if !params.body.isEmpty {
                queryItems.append("body=\(params.body)")
            }
            // Append query parameters if there are any
            if !queryItems.isEmpty {
                urlString += "?" + queryItems.joined(separator: "&")
            }
            // URL encode the string
            guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                throw DraftEmailError.percentEncodingFailed
            }
            // Formulate and open URL
            guard let url: URL = URL(string: encodedString) else {
                throw DraftEmailError.urlCreationFailed
            }
            let _ = NSWorkspace.shared.open(url)
            return "Successfully created email draft"
            enum DraftEmailError: LocalizedError {
                
                case percentEncodingFailed
                case urlCreationFailed
                
                var errorDescription: String? {
                    switch self {
                        case .percentEncodingFailed:
                            return "Failed to add percent encoding to `mailto` URL"
                        case .urlCreationFailed:
                            return "Failed to create URL from `mailto` string"
                    }
                }
            }
        }
    )
    struct DraftEmailParams: FunctionParams {
        let recipients: [String]
        let cc: [String]?
        let bcc: [String]?
        let subject: String
        let body: String
    }
    
    /// A function to get the user's location
    static let getLocation = Function<BlankParams, String>(
        name: "get_location",
        description: "A function to get the user's location. Use this before providing answers that depend on location, such as weather or holidays.",
        params: [
        ],
        run: { params in
            return try await IPLocation.getLocation()
        }
    )
    struct BlankParams: FunctionParams {}
    
}
