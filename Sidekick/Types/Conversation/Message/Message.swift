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
		usedServer: Bool = false,
		usedCodeInterpreter: Bool? = false,
		jsCode: String? = nil,
		expertId: UUID? = nil
	) {
		self.id = UUID()
		self.text = text.replacingOccurrences(
			of: "\\[",
			with: "$$"
		).replacingOccurrences(
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
		self.usedCodeInterpreter = usedCodeInterpreter
		self.jsCode = jsCode
		self.expertId = expertId
	}
	
	init(
		imageUrl: URL,
		prompt: String,
		expertId: UUID? = nil
	) {
		self.id = UUID()
		self.text = "Generated an image with the prompt \"\(prompt)\"."
		self.sender = .system
		self.startTime = .now
		self.lastUpdated = .now
		self.outputEnded = true
		self.model = "Image Playground Model"
		self.imageUrl = imageUrl
		self.expertId = expertId
	}
	
	/// A `UUID` for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// A `ContentType` for the message
	public var contentType: Self.ContentType {
		if self.imageUrl != nil {
			return .image
		}
		return .text
	}
	
	/// Stored property for the message text
	public var text: String
	
	/// Computed property returning the response text
	public var responseText: String {
		return self.text.thinkingTagsRemoved
	}
	
	/// A `String` containing the message's reasoning process
	public var reasoningText: String? {
		// Return nil if sender is not assistant
		if self.sender != .assistant { return nil }
		// List special reasoning tokens
		let specialTokenSets: [[String]] = [
			["<think>", "</think>"]
		]
		// Extract text between tokens
		// For each set of tokens
		for specialTokenSet in specialTokenSets {
			// Get range of start token
			if let startRange = self.text.range(
				of: specialTokenSet.first!
			) {
				// Get range of end token
				if let endRange = self.text.range(
					of: specialTokenSet.last!,
					range: startRange.upperBound..<text.endIndex
				) {
					// Return text
					return String(
						self.text[startRange.upperBound..<endRange.lowerBound]
					).trimmingCharacters(in: .whitespacesAndNewlines)
				} else if !self.outputEnded {
					// If still outputting, show unfinished reasoning text
					return String(
						self.text[startRange.upperBound..<text.endIndex]
					).trimmingCharacters(in: .whitespacesAndNewlines)
				}
			}
		}
		// If failed to locate reasoning text, return nil
		return nil
	}
	
	/// A `Bool` representing if the message is contains a reasoning process
	public var hasReasoning: Bool {
		// Return true if...
		// a.) There are reasoning tokens
		// b.) The message does come from a model
		return (self.reasoningText != nil) && (self.sender == .assistant)
	}
	
	/// A `Bool` representing whether the message was generated with the help of a code interpreter
	public var usedCodeInterpreter: Bool?
	/// A `String` containing the JavaScript code that was executed, if any
	public var jsCode: String?
	
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
		// Search in expert resources
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
		if results.isEmpty {
			return (self.text, 0)
		}
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

When multiple sources provide correct, but conflicting information (e.g. different definitions), ALWAYS use sources from files, not websites. 

If your response uses information from one or more provided sources I provided, your response MUST be directly followed with a single exaustive LIST OF FILEPATHS AND URLS of ALL referenced sources, in the format [{"url": "/path/to/referenced/file.pdf"}, {"url": "/path/to/another/referenced/file.docx"}, {"url": "https://referencedwebsite.com"}, "https://anotherreferencedwebsite.com"}]

This list should be the only place where references and sources are addressed, and MUST not be preceded by a header or a divider.

If I did not provide sources, YOU MUST NOT end your response with a list of filepaths and URLs. If no sources were provided, DO NOT mention the lack of sources.

If you did not use the information I provided, YOU MUST NOT end your response with a list of filepaths and URLs. 

DO NOT reference sources outside of those provided below. If you did not reference provided sources, do not mention sources in your response.

\(resultsText)
"""
		return (messageText, results.count)
	}
	
	/// A `Double` representing the number of tokens outputted per second
	public var tokensPerSecond: Double?
	
	/// The model's name, of type `String`
	public let model: String
	
	/// The ``Sender`` of the message (either `user` or `system`)
	private var sender: Sender
	
	/// The `UUID` of the expert used
	private var expertId: UUID?
	
	/// A `URL` for an image generated, if any
	public var imageUrl: URL?
	/// An `Image` loaded from the `imageUrl`, if any
	public var image: some View {
		Group {
			if let url = imageUrl {
				AsyncImage(
					url: url,
					content: { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(
								maxWidth: 350,
								maxHeight: 350
							)
							.clipShape(
								UnevenRoundedRectangle(
									topLeadingRadius: 0,
									bottomLeadingRadius: 13,
									bottomTrailingRadius: 13,
									topTrailingRadius: 13
								)
							)
							.draggable(
								Image(
									nsImage: NSImage(
										contentsOf: url
									)!
								)
							)
							.onTapGesture(count: 2) {
								NSWorkspace.shared.open(url)
							}
							.contextMenu {
								Button {
									NSWorkspace.shared.open(url)
								} label: {
									Text("Open")
								}
							}
					},
					placeholder: {
						ProgressView()
							.padding(11)
					}
				)
			} else {
				EmptyView()
			}
		}
	}
	
	/// Computed property for chunks in the message's reasoning text
	public var reasoningChunks: [Chunk]? {
		return self
			.reasoningText?
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
	
	/// Computed property for chunks in the message's response text
	public var responseChunks: [Chunk] {
		return self
			.responseText
			.replacingOccurrences(
				of: "\\(",
				with: ""
			)
			.replacingOccurrences(
				of: "\\)",
				with: ""
			)
			.replacingOccurrences(
				of: "\\[",
				with: "$$"
			)
			.replacingOccurrences(
				of: "\\]",
				with: "$$"
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
	
	/// A `View` for the sender's icon
	var icon: some View {
		Group {
			if let expertId = self.expertId,
			   let expert = ExpertManager.shared.getExpert(id: expertId)
			{
				expert.icon
			} else {
				sender.icon
			}
		}
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
		response: LlamaServer.CompleteResponse,
		includeReferences: Bool
	) {
		// Set variables
		self.tokensPerSecond = response.predictedPerSecond
		self.responseStartSeconds = response.responseStartSeconds
		self.lastUpdated = .now
//		print("response.text: \(response.text)")
		let text: String = response.text.dropSuffixIfPresent("[]")
		// Decode text for extract text and references
		let messageText: String = text.dropFollowingSubstring(
			"[",
			options: .backwards
		)
		.trimmingWhitespaceAndNewlines()
		.dropSuffixIfPresent(
			"Sources:"
		).dropSuffixIfPresent(
			"References:"
		).dropSuffixIfPresent(
			"**Sources:**"
		).dropSuffixIfPresent(
			"**References:**"
		).dropSuffixIfPresent(
			"**Sources**:"
		).dropSuffixIfPresent(
			"**References**:"
		).dropSuffixIfPresent(
			"List of Filepaths and URLs:"
		)
		.trimmingWhitespaceAndNewlines()
		let jsonText: String = text.dropPrecedingSubstring(
			"[",
			options: .backwards,
			includeCharacter: true
		)
		// Decode references if needed
		if includeReferences, let data: Data = try? jsonText.data() {
			// Decode data
			if let references = ReferencedURL.fromData(
				data: data
			) {
				self.referencedURLs = references
				self.text = messageText
			} else {
				self.text = text
			}
		} else {
			self.text = text
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
			self.content = content
		}
		
		public let id: UUID = UUID()
		
		public var content: String
		public var isLatex: Bool
		
	}
	
	private enum JSONType: String, CaseIterable {
		case unknown
		case empty
		case references
	}
	
	public enum ContentType: String, CaseIterable {
		case text
		case image
	}
	
}

public extension Sequence where Iterator.Element == Message.Chunk {
	/// A `Bool` representing if the message contains LaTeX
	var hasLatex: Bool {
		return self.contains(where: \.isLatex)
	}
}
