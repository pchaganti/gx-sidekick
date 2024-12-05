//
//  Message.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SimilaritySearchKit
import SwiftUI

public struct Message: Identifiable, Codable, Hashable {
	
	init(
		text: String,
		sender: Sender,
		model: String? = nil,
		usedServer: Bool = false
	) {
		self.id = UUID()
		self.text = text.replacingOccurrences(
			of: "\\[",
			with: "$$"
		)
		.replacingOccurrences(
			of: "\\]",
			with: "$$"
		)
		self.sender = sender
		self.startTime = .now
		self.lastUpdated = .now
		self.outputEnded = false
		var modelName: String = model ?? String(
			localized: "Unknown"
		)
		if usedServer == true {
			modelName = String(localized: "Remote Model: ") + modelName
		}
		self.model = modelName
	}
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the message text
	public var text: String
	
	/// Computed property returning the displayed text
	public var displayedText: String {
		// Return original text if sender is not assistant
		if self.sender != .assistant { return self.text }
		return text
	}
	
	/// Function returning the message text that is submitted to the LLM
	public func submittedText(
		similarityIndex: SimilarityIndex?,
		useWebSearch: Bool,
		temporaryResources: [TemporaryResource]
	) async -> (
		text: String,
		sources: Int
	) {
		// If assistant or system, no sources needed
		if self.sender != .user {
			return (self.text, 0)
		}
		// Search in profile resources
		// If no resources, return blank array
		let hasResources: Bool = similarityIndex != nil && !(similarityIndex?.indexItems.isEmpty ?? true)
		let searchResultsMultiplier: Int = RetrievalSettings.searchResultsMultiplier * 2
		let resourcesSearchResults: [SearchResult] = await similarityIndex?.search(
			query: text,
			maxResults: searchResultsMultiplier
		) ?? []
		let resourcesResults: [Source] = resourcesSearchResults.map { result in
			// If search result context is not being used, skip
			if !RetrievalSettings.useSearchResultContext {
				return Source(
					text: result.text,
					source: result.sourceUrlText!
				)
			}
			// Get item index
			guard let index: Int = result.itemIndex else {
				return Source(
					text: result.text,
					source: result.sourceUrlText!
				)
			}
			// Get items in the same file
			guard let sameFileItems: [IndexItem] = similarityIndex?.indexItems.filter({
				$0.sourceUrlText == result.sourceUrlText
			}) else {
				return Source(
					text: result.text,
					source: result.sourceUrlText!
				)
			}
			// Get pre & post content
			let preContent: String = sameFileItems.filter({
				$0.itemIndex == index - 1
			}).first?.text ?? ""
			let postContent: String = sameFileItems.filter({
				$0.itemIndex == index + 1
			}).first?.text ?? ""
			// Make final text
			let fullText: String = [preContent, result.text, postContent].joined(separator: " ")
			return Source(
				text: fullText,
				source: result.sourceUrlText!
			)
		}
		// Search Tavily
		var resultsCount: Int = (hasResources && !resourcesResults.isEmpty) ? 1 : 2
		resultsCount = resultsCount * searchResultsMultiplier
		var tavilyResults: [Source]? = []
		if useWebSearch {
			tavilyResults = try? await TavilySearch.search(
				query: text,
				resultCount: resultsCount
			)
			if tavilyResults == nil {
				tavilyResults = try? await TavilySearch.search(
					query: text,
					resultCount: resultsCount,
					useBackupApi: true
				)
			}
		}
		// Get temporary resources as sources
		let temporaryResourcesSources: [Source] = temporaryResources.map(
			\.source
		).compactMap({ $0 })
		// Combine
		let results: [Source] = resourcesResults + (
			tavilyResults ?? []
		) + temporaryResourcesSources
		// Save sources
		let sources: Sources = Sources(
			messageId: self.id,
			sources: results
		)
		SourcesManager.shared.add(sources)
		// Skip if no results
		if results.isEmpty { return (self.text, 0) }
		let resultsTexts: [String] = results.enumerated().map { index, result in
			return """
{
	"text": "\(result.text)",
	"url": "\(result.source)"
}
"""
		}
		let resultsText: String = resultsTexts.joined(separator: ",\n")
		let messageText: String = """
\(self.text)

Below is information that may or may not be relevant to my request in JSON format. 

When multiple sources provide correct, but conflicting information (e.g. different definitions), prioritize the use of sources from local files, not websites. 

If your response uses information from one or more sources, your response MUST contain a single exaustive ARRAY OF FILEPATHS AND URLS of ALL referenced sources, with no duplicates. This corresponds to the "references" property of the response JSON schema. 

If no provided sources were used, an empty array should be returned for the "references" property of the response JSON schema.

DO NOT reference sources outside of those provided below. If you did not reference provided sources, do not mention sources in your response. NO headers, labels, numbering or comments are needed in this list of referenced sources.

\(resultsText)
"""
		return (messageText, results.count)
	}
	
	/// Computed property for the number of tokens outputted per second
	public var tokensPerSecond: Double?
	
	/// Stored property for the selected model
	public let model: String
	
	/// Stored property for the sender of the message (either `user` or `system`)
	private var sender: Sender
	
	/// A `Bool` representing if the message contains LaTeX
	public var hasLatex: Bool {
		return self.chunks.contains(where: \.isLatex)
	}
	
	/// Computed property for chunks in the message
	public var chunks: [Chunk] {
		return self
			.text
			.replacingOccurrences(
				of: "\\(",
				with: ""
			)
			.replacingOccurrences(
				of: "\\)",
				with: ""
			)
			.splitByLatex()
			.map { chunk in
			return Chunk(content: chunk.string, isLatex: chunk.isLatex)
		}
	}
		
	
	/// An array for URLs of sources referenced in a response
	public var referencedURLs: [ReferencedURL] = []
	
	/// Function to get the sender
	public func getSender() -> Sender {
		return self.sender
	}
	
	/// Computed property for the sender's icon
	var icon: some View {
		sender.icon
	}
	
	/// Stored property for the start time of interaction
	public var startTime: Date
	/// Stored property for the most recent update time
	public var lastUpdated: Date
	
	/// Stored property for the time taken for a response to start
	public var responseStartSeconds: Double?
	
	/// Stored property for whether the output has finished
	public var outputEnded: Bool
	
	/// Function to update message
	@MainActor
	public mutating func update(
		response: LlamaServer.CompleteResponse
	) {
		// Set variables
		self.tokensPerSecond = response.predictedPerSecond
		self.responseStartSeconds = response.responseStartSeconds
		self.lastUpdated = .now
		// Decode text for extract text and references
		let jsonText: String = response.text
		// Get as data
		if let data: Data = try? jsonText.data() {
			// Decode data
			let decoder: JSONDecoder = JSONDecoder()
			if let responseText = try? decoder.decode(
				Message.ResponseText.self,
				from: data
			) {
				self.text = responseText.text
				let uniqueReferences: [ReferencedURL] = Array(Set(responseText.references))
				self.referencedURLs = uniqueReferences.sorted(
					by: \.displayName
				)
				return
			}
		} else {
			self.text = jsonText
			self.referencedURLs = []
			return
		}
	}
	
	/// Function to end a message
	public mutating func end() {
		self.lastUpdated = .now
		self.outputEnded = true
	}
	
	public struct MessageSubset: Codable {
		
		init(
			message: Message,
			similarityIndex: SimilarityIndex? = nil,
			shouldAddSources: Bool = false,
			useWebSearch: Bool = false,
			temporaryResources: [TemporaryResource] = []
		) async {
			self.role = message.sender
			if shouldAddSources {
				self.content = await message.submittedText(
					similarityIndex: similarityIndex,
					useWebSearch: useWebSearch,
					temporaryResources: temporaryResources
				).text
			} else {
				self.content = message.text
			}
		}
		
		/// Stored property for who sent the message
		var role: Sender
		/// Stored property for the message's content
		var content: String
		
	}
	
	public struct Chunk: Identifiable {
		
		init(content: String, isLatex: Bool) {
			self.isLatex = isLatex
			if isLatex {
				self.content = content.trim(
					prefix: "\\[",
					suffix: "\\]"
				)
			} else {
				self.content = content
			}
		}
		
		public let id: UUID = UUID()
		
		public var content: String
		public var isLatex: Bool
	
	}
	
	private struct ResponseText: Codable {
		
		var text: String
		var references: [ReferencedURL]
		
	}
	
	private enum JSONType: String {
		case unknown
		case empty
		case references
	}
	
}
