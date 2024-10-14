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
		sender: Sender
	) {
		self.id = UUID()
		self.text = text
		self.sender = sender
		self.startTime = .now
		self.lastUpdated = .now
		self.outputEnded = false
		self.model = Settings.modelUrl?.lastPathComponent ?? "Unknown"
	}
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the message text
	public var text: String
	
	/// Computed property returning the displayed text
	public var displayedText: String {
		// Return original text if sender is not assistant
		if self.sender != .assistant { return self.text }
		// Remove urls
		guard let jsonRange = text.range(of: "[", options: .backwards) else {
			return text // If no JSON found, return the whole text
		}
		// Extract the text up to the start of the JSON string
		let extractedText = text[..<jsonRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
		return extractedText
	}
	
	/// Function returning the message text that is submitted to the LLM
	public func submittedText(
		similarityIndex: SimilarityIndex?
	) async -> String {
		if similarityIndex == nil || self.sender != .user {
			return self.text
		}
		let results: [Sidekick.SearchResult] = await similarityIndex!.search(
			query: text
		)
		// Skip if no results
		if results.isEmpty { return self.text }
		let resultsTexts: [String] = results.enumerated().map { index, result in
			return """
{
	"text": "\(result.text)",
	"url": "\(result.sourceUrlText!)"
}
"""
		}
		let resultText: String = resultsTexts.joined(separator: ",\n")
		let sourceText: String = """
Below is information that may or may not be relevant to my request in JSON format. If your response uses text from sources provided below, please end your response with a list of URLs or filepaths of all provided sources referenced in the format [{"url": "https://referencedurl.com"}, {"url": "/path/to/referenced/file.pdf"}]. If no provided sources were referenced, do not mention sources in your response, and end your response with an empty array of JSON objects: []. No section headers, labels or numbering are needed in this list of referenced sources.

\(resultText)
"""
		return "\(self.text)\n\n\(sourceText)"
	}
	
	/// Computed property for the number of tokens outputted per second
	public var tokensPerSecond: Double?
	
	/// Stored property for the selected model
	public let model: String
	
	/// Stored property for the sender of the message (either `user` or `system`)
	private var sender: Sender
	
	/// Computed property for URLs of sources referenced in a response
	public var referencedURLs: [ReferencedURL] {
		// Get string with JSON
		guard let jsonRange = text.range(of: "[", options: .backwards) else {
			return []
		}
		guard let jsonString: NSString = text[jsonRange.lowerBound...].trimmingCharacters(
			in: .whitespacesAndNewlines
		) as NSString? else {
			return []
		}
		// Decode string
		guard let data: Data = try? jsonString.data() else {
			return []
		}
		guard let urls: [ReferencedURL] = try? JSONDecoder().decode(
			[ReferencedURL].self,
			from: data
		) else {
			return []
		}
		// Return sorted, unique urls
		return Array(Set(urls)).sorted(by: \.displayName)
	}
	
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
		newText: String,
		tokensPerSecond: Double?,
		responseStartSeconds: Double
	) {
		self.text = newText
		self.tokensPerSecond = tokensPerSecond
		self.responseStartSeconds = responseStartSeconds
		self.lastUpdated = .now
	}
	
	/// Function to end a message
	public mutating func end() {
		self.lastUpdated = .now
		self.outputEnded = true
	}
	
	/// Static constant for testing a MessageView
	static let test: Message = Message(
		text: "Hi there! I'm an artificial intelligence model known as **Llama**, a [**LLM** (Large Language Model)](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://en.wikipedia.org/wiki/Large_language_model&ved=2ahUKEwjTvLKIt_6IAxWVulYBHb09CFUQFnoECBkQAQ&usg=AOvVaw3ojBiy1-Rxlxl5lO1-SI8F) from Meta.",
		sender: .user
	)
	
	/// Function to convert the message to JSON for chat parameters
	public func toJSON(
		similarityIndex: SimilarityIndex
	) async -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let jsonData = try? encoder.encode(
			await MessageSubset(
				message: self,
				similarityIndex: similarityIndex
			)
		)
		return String(data: jsonData!, encoding: .utf8)!
	}
	
	public struct MessageSubset: Codable {
		
		init(
			message: Message,
			similarityIndex: SimilarityIndex?
		) async {
			self.role = message.sender
			if let similarityIndex {
				self.content = await message.submittedText(
					similarityIndex: similarityIndex
				)
			} else {
				self.content = message.text
			}
		}
		
		var role: Sender
		var content: String
		
	}
	
}
