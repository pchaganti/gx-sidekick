//
//  Tavily.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation
import OSLog

public class Tavily {
	
	/// A `Logger` object for the `Tavily` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: Tavily.self)
	)
	
	/// Function to search tavily for sources
	public static func search(
		query: String,
        site: String? = nil,
		resultCount: Int,
        searchDepth: Tavily.SearchRequest.SearchDepth = .basic,
        timeRange: TimeRange? = nil,
        useBackupKey: Bool = false
	) async throws -> [Source] {
		// Check if API key is available
        if RetrievalSettings.tavilyApiKey.isEmpty && !useBackupKey {
            throw TavilyError.noApiKey
		}
        if RetrievalSettings.tavilyBackupApiKey.isEmpty && useBackupKey {
            throw TavilyError.noBackupApiKey
        }
        // Formulate full query
        var query: String = query
        if let site = site {
            query += " site:\(site)"
        }
        // Get results from Tavily
        let apiKey: String = !useBackupKey ? RetrievalSettings.tavilyApiKey : RetrievalSettings.tavilyBackupApiKey
        if apiKey.isEmpty {
            self.logger.error("No API key provided for Tavily")
            throw TavilyError.invalidApiKey
        }
		do {
            let tavilyResults: [Tavily.SearchResponse.Result] = try await Self.hitSearchApi(
				query: query,
				apiKey: apiKey,
                resultCount: resultCount,
                searchDepth: searchDepth,
                timeRange: timeRange
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
	
	/// Function to hit Tavily Search API
	public static func hitSearchApi(
		query: String,
		apiKey: String,
        resultCount: Int,
        searchDepth: Tavily.SearchRequest.SearchDepth = .basic,
        timeRange: TimeRange?
	) async throws -> [Tavily.SearchResponse.Result] {
		// Set up query params
		let startTime: Date = .now
		let params = Tavily.SearchRequest(
			query: query,
            max_results: resultCount,
            search_depth: searchDepth,
            time_range: timeRange
		)
		let tavilyEndpoint: URL = URL(string: "https://api.tavily.com/search")!
		// Set up request
		var request: URLRequest = URLRequest(
			url: tavilyEndpoint
		)
		request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
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
            "Tavily search returned results in \(Date.now.timeIntervalSince(startTime)) secs"
        )
		let decoder: JSONDecoder = JSONDecoder()
		let response: Tavily.SearchResponse = try decoder.decode(
			Tavily.SearchResponse.self,
			from: data
		)
		// Add direct answer to results
		let answerResult: Tavily.SearchResponse.Result = Tavily.SearchResponse.Result(
			title: "Answer Summary",
			url: "https://tavily.com",
			content: response.answer,
			score: 1.0
		)
		let results: [Tavily.SearchResponse.Result] = response.results + [answerResult]
		return results
	}
    
    public enum TimeRange: String, CaseIterable, Codable {
        case day, week, month, year
    }
    
    /// Function to use Tavily to extract website content
    public static func extract(
        url: String,
        useBackupKey: Bool = false
    ) async throws -> String {
        // Check if API key is available
        if RetrievalSettings.tavilyApiKey.isEmpty && !useBackupKey {
            throw TavilyError.noApiKey
        }
        if RetrievalSettings.tavilyBackupApiKey.isEmpty && useBackupKey {
            throw TavilyError.noBackupApiKey
        }
        // Get results from Tavily
        let apiKey: String = !useBackupKey ? RetrievalSettings.tavilyApiKey : RetrievalSettings.tavilyBackupApiKey
        if apiKey.isEmpty {
            self.logger.error("No API key provided for Tavily")
            throw TavilyError.invalidApiKey
        }
        do {
            let tavilyResult: Tavily.ExtractResponse.Result = try await Self.hitExtractApi(
                url: url,
                apiKey: apiKey
            )
            return tavilyResult.raw_content
        } catch {
            self.logger.error("Tavily Search Error: \(error, privacy: .public)")
            throw error
        }
    }
    
    /// Function to hit Tavily Extract API
    public static func hitExtractApi(
        url: String,
        apiKey: String
    ) async throws -> Tavily.ExtractResponse.Result {
        // Set up query params
        let startTime: Date = .now
        let params = Tavily.ExtractRequest(urls: url)
        let tavilyEndpoint: URL = URL(string: "https://api.tavily.com/extract")!
        // Set up request
        var request: URLRequest = URLRequest(
            url: tavilyEndpoint
        )
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
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
            "Tavily extract returned results in \(Date.now.timeIntervalSince(startTime)) secs"
        )
        let decoder: JSONDecoder = JSONDecoder()
        let response: Tavily.ExtractResponse = try decoder.decode(
            Tavily.ExtractResponse.self,
            from: data
        )
        guard let result = response.results.first else {
            throw TavilyError.extractFailed
        }
        return result
    }
	
    enum TavilyError: LocalizedError {
        
		case noApiKey
        case noBackupApiKey
		case invalidApiKey
        case extractFailed
        
        var errorDescription: String? {
            switch self {
                case .noApiKey:
                    return "No API key provided"
                case .noBackupApiKey:
                    return "No backup API key provided"
                case .invalidApiKey:
                    return "Invalid API key"
                case .extractFailed:
                    return "Failed to extract website content"
            }
        }
        
	}
	
}
