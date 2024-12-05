//
//  FileToSort.swift
//  Sidekick
//
//  Created by Bean John on 12/3/24.
//

import ExtractKit_macOS
import Foundation

public struct FileToSort: Identifiable {
	
	init(
		url: URL,
		content: String? = nil,
		newUrl: URL? = nil
	) {
		self.url = url
		self.content = content
		self.newUrl = newUrl
	}
	
	/// A `id` property containing a `UUID` for `Identifiable` conformance
	public let id: UUID = UUID()
	
	/// A `URL` pointing to the file's location
	public var url: URL
	
	/// A `String` containing the file's contents
	public var content: String? = nil
	
	/// A `String` a summary of the file's contents
	public var contentSummary: String? = nil
	
	/// Function to scrape content in file
	public mutating func scrapeContent() async {
		// Check if scraped
		if self.content != nil {
			return
		}
		// Else, scrape
		if let content = try? await ExtractKit.shared.extractText(
			url: url
		) {
			self.content = String(
				content.prefix(
					InferenceSettings.contextLength * 3
				)
			)
		}
	}
	
	/// A `URL` pointing to the file's new location
	public var newUrl: URL? = nil
	
}

public extension FileToSort {
	
	/// Function to generate a summary of the file's content
	private mutating func generateSummary() async {
		// Check content
		if self.content == nil {
			await self.scrapeContent()
		}
		guard let content else {
			return
		}
		// Construct messages
		let generationPrompt: String = """
Considering a file's contents, write a summary with 3-4 bullet points. Respond with ONLY the summary.

In the first bullet point, explain what the document is, perhaps a book report, or a news article analysis.  

{
"content": "\(content)"
}
"""
		// Generate summary
		do {
			// Generate summary
			let summary: String = try await Self.generate(
				prompt: generationPrompt
			)
			// Save filename
			self.contentSummary = summary
		} catch {  }
	}
	
	/// Function to start text generation
	static func generate(
		prompt: String
	) async throws -> String {
		// Formulate messages
		let systemPromptMessage: Message = Message(
			text: InferenceSettings.systemPrompt,
			sender: .system
		)
		let filenameMessage: Message = Message(
			text: prompt,
			sender: .user
		)
		let messages: [Message] = [
			systemPromptMessage,
			filenameMessage
		]
		// Generate
		return try await Model.shared.listenThinkRespond(
			messages: messages,
			mode: .default
		).text
	}
	
	/// Function to get file summary
	mutating func getFileSummary() async -> FileSummary {
		// Generate summary if needed
		if self.contentSummary == nil {
			await self.generateSummary()
		}
		// Convert to `FileSummary`
		let summary: FileSummary = FileSummary(file: self)
		return summary
	}
	
	/// ``FileSummary`` struct to easily pass file summary to bot as text
	struct FileSummary: Codable, Sendable {
		
		init(file: FileToSort) {
			self.filename = file.url.lastPathComponent
			self.contentSummary = file.contentSummary
		}
		
		public var filename: String
		public var contentSummary: String?
		
	}
	
}
