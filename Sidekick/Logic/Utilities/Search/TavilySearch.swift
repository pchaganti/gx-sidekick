//
//  TavilySearch.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation
import OSLog

public class TavilySearch {
	
	/// A `Logger` object for the `TavilySearch` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: TavilySearch.self)
	)
	
	/// Function to search tavily for sources
	public static func search(
		query: String,
        site: String? = nil,
		resultCount: Int,
        timeRange: TimeRange? = nil,
        useBackupApi: Bool = false
	) async throws -> [Source] {
		// Check if search is on
        if RetrievalSettings.tavilyApiKey.isEmpty {
            throw TavilySearchError.noApiKey
		}
        // Formulate full query
        var query: String = query
        if let site = site {
            query += " site:\(site)"
        }
        // Get results from Tavily
        let apiKey: String = !useBackupApi ? RetrievalSettings.tavilyApiKey : RetrievalSettings.tavilyBackupApiKey
        if apiKey.isEmpty {
            self.logger.error("No API key provided for Tavily")
            throw TavilySearchError.invalidApiKey
        }
		do {
			let tavilyResults: [Tavily.Response.Result] = try await Self.hitTavilyApi(
				query: query,
				apiKey: apiKey,
                timeRange: timeRange,
				resultCount: resultCount
			)
			let results: [Source] = tavilyResults.map { result in
				return Source(
                    text: result.content,
					source: result.url
				)
			}
			return results
		} catch {
			self.logger.error("Tavily Search Error: \(error, privacy: .public)")
			throw error
		}
	}
	
	/// Function to hit Tavily API
	public static func hitTavilyApi(
		query: String,
		apiKey: String,
        timeRange: TimeRange?,
		resultCount: Int
	) async throws -> [Tavily.Response.Result] {
		// Set up query params
		let startTime: Date = .now
		let params = Tavily.Request(
			api_key: apiKey,
			query: query,
            max_results: resultCount,
            time_range: timeRange
		)
		let tavilyEndpoint: URL = URL(string: "https://api.tavily.com/search")!
		// Set up request
		var request: URLRequest = URLRequest(
			url: tavilyEndpoint
		)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = params.toJSON().data(using: .utf8)
		// Hit the API
		let urlSession: URLSession = URLSession.shared
		urlSession.configuration.waitsForConnectivity = false
		urlSession.configuration.timeoutIntervalForRequest = 7.5
		urlSession.configuration.timeoutIntervalForResource = 10
		let (data, _): (Data, URLResponse) = try await URLSession.shared.data(
			for: request
		)
        Self.logger.info(
            "Tavily returned results in \(Date.now.timeIntervalSince(startTime)) secs"
        )
		let decoder: JSONDecoder = JSONDecoder()
		let response: Tavily.Response = try decoder.decode(
			Tavily.Response.self,
			from: data
		)
		// Add direct answer to results
		let answerResult: Tavily.Response.Result = Tavily.Response.Result(
			title: "Answer Summary",
			url: "https://tavily.com",
			content: response.answer,
			score: 1.0
		)
		let results: [Tavily.Response.Result] = response.results + [answerResult]
		return results
	}
    
    public enum TimeRange: String, CaseIterable, Codable {
        case day, week, month, year
    }
	
    enum TavilySearchError: LocalizedError {
        
		case noApiKey
		case invalidApiKey
        
        var errorDescription: String? {
            switch self {
                case .noApiKey:
                    return "No API key provided"
                case .invalidApiKey:
                    return "Invalid API key"
            }
        }
        
	}
	
}
