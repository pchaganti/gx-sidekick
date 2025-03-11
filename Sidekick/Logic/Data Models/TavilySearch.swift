//
//  TavilySearch.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import ExtractKit_macOS
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
		resultCount: Int,
		useBackupApi: Bool = false
	) async throws -> [Source] {
		// Check if search is on
		if !RetrievalSettings.useTavilySearch {
			throw TavilySearchError.notActivated
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
				resultCount: resultCount
			)
			// Get all site content
			let websiteContent: [Source] = tavilyResults.map { result in
				return Source(
					text: result.content,
					source: result.url
				)
			}
			return websiteContent
		} catch {
			self.logger.error("Tavily Search Error: \(error)")
			throw error
		}
	}
	
	/// Function to hit Tavily API
	public static func hitTavilyApi(
		query: String,
		apiKey: String,
		resultCount: Int
	) async throws -> [Tavily.Response.Result] {
		// Set up query params
		let startTime: Date = .now
		let params = Tavily.Request(
			api_key: apiKey,
			query: query,
			max_results: resultCount
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
		print("Tavily returned results in \(Date.now.timeIntervalSince(startTime)) secs")
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
	
	enum TavilySearchError: Error {
		case notActivated
		case invalidApiKey
	}
	
}
