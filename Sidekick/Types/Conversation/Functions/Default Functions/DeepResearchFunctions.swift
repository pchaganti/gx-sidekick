//
//  DeepResearchFunctions.swift
//  Sidekick
//
//  Created by John Bean on 5/14/25.
//

import Foundation

public class DeepResearchFunctions {
    
    static var functions: [AnyFunctionBox] {
        var functions: [AnyFunctionBox] = [
            DeepResearchFunctions.getWebsiteContent,
            WebFunctions.getLocation
        ]
        // Add web search function
        let provider: RetrievalSettings.SearchProvider = RetrievalSettings.SearchProvider(
            rawValue: RetrievalSettings.defaultSearchProvider
        ) ?? .duckDuckGo
        if provider == .tavily {
            functions.append(WebFunctions.tavilyWebSearch)
        } else {
            functions.append(WebFunctions.duckDuckGoWebSearch)
        }
        // Add vector search functions
        functions += ExpertFunctions.functions
        return functions
    }
    
    /// A function to get the content of a website via its url
    static let getWebsiteContent = Function<GetWebsiteContentParams, String>(
        name: "get_website_content",
        description: "Retrieves the full content of a website via its URL, then returns content relevant to the query.",
        params: [
            FunctionParameter(
                label: "url",
                description: "The website's URL",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "query",
                description: "A description of the content you want to find within the website content",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Get website content
            var content: String = try await WebScrape.scrape(url: params.url)
            // Trim if needed
            let maxTokens: Int = Int(
                Double(InferenceSettings.useServer ? 128_000 : InferenceSettings.contextLength) * 0.75
            )
            content.trimmingSuffixToTokens(maxTokens: maxTokens)
            // Make call to worker model
            let filterPrompt: String = """
You are given the following website content:

\(content)

The user’s query is: "\(params.query)"

Extract and return only the parts of the website content that are directly relevant to the user’s query. Do not add any additional information or commentary. Respond with the relevant content ONLY.
"""
            let filterMessage: Message = Message(
                text: filterPrompt,
                sender: .user
            )
            let response: String = try await Model.shared.listenThinkRespond(
                messages: [filterMessage],
                modelType: .regular,
                mode: .default
            ).text.reasoningRemoved
            return """
Below is content extracted from `\(params.url)` that is directly relevant to the user’s query "\(params.query)":

\(response)
"""
        }
    )
    struct GetWebsiteContentParams: FunctionParams {
        let url: String
        let query: String
    }
    
}
