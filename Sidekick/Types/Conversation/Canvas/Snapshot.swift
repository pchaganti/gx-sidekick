//
//  Snapshot.swift
//  Sidekick
//
//  Created by John Bean on 3/19/25.
//

import Foundation
import OSLog

public struct Snapshot: Identifiable, Codable, Equatable, Hashable {
	
	init(
		text: String = "",
		site: Site? = nil
	) {
		self.text = text
		self.site = site
	}
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The `Date` on which the ``Snapshot`` was created
	public var createdAt: Date = Date.now
	
	/// The ``Type`` of the ``Snapshot``
	public var type: `Type` {
		if self.site != nil {
			return .site
		}
		return .text
	}
	
	/// The `String` of text in the snapshot, if available
	public var text: String = "" {
		willSet {
			// Save original text
			if originalText == nil {
				originalText = self.text
			}
		}
	}
	
	/// The `String` of the original text
	public var originalText: String? = nil
	
	/// The ``Site`` in the snapshot, if available
	public var site: Site?
	
	public struct Site: Identifiable, Codable, Hashable {
		
		/// A `Logger` object for the ``Site`` object
		private static let logger: Logger = .init(
			subsystem: Bundle.main.bundleIdentifier!,
			category: String(describing: Site.self)
		)
		
		/// Stored property for `Identifiable` conformance
		public var id: UUID = UUID()
		
		/// The site's `HTML` code in a `String`
		var html: String
		/// The site's `CSS` code in a `String`
		var css: String?
		/// The site's `JavaScript` code in a `String`
		var js: String?
		
		/// The ``Site``'s directory URL in the `Cache` directory
		public var directoryUrl: URL {
			let canvasDirectoryUrl: URL = Settings
				.cacheUrl
				.appendingPathComponent("Canvas")
			return canvasDirectoryUrl
				.appendingPathComponent(self.id.uuidString)
		}
		
		/// The ``Site``'s URL
		public var url: URL {
			return self.directoryUrl.appendingPathComponent("index.html")
		}
		
		/// Function to save the site to the `Cache` directory
		public func saveToCache() {
			// Make directories if unavailable
			if !self.directoryUrl.fileExists {
				try? FileManager.default.createDirectory(
					at: self.directoryUrl,
					withIntermediateDirectories: true
				)
			}
			// Save to file
			var contents: [String] = [self.html]
			if let css = self.css {
				contents.append(css)
			}
			if let js = self.js {
				contents.append(js)
			}
			let filenames: [String] = ["index.html", "styles.css", "script.js"]
			for index in contents.indices {
				// Formulate url
				let filename: String = filenames[index]
				let fileUrl: URL = self.directoryUrl.appendingPathComponent(
					filename
				)
				// Write to url
				let content: String = contents[index]
				if !content.isEmpty {
					do {
						try content.write(
							to: fileUrl,
							atomically: true,
							encoding: .utf8
						)
					} catch {
						Self.logger.error("Failed to save \"\(filename)\" to cache directory for snapshot: \(error)")
					}
				}
			}
		}
		
		/// Function to export the site
		public func export(
			name: String,
			outputDirUrl: URL
		) throws {
			// Create cache if it does not exist
			if !self.directoryUrl.fileExists {
				self.saveToCache()
			}
			// Make a copy
			let destinationUrl: URL = outputDirUrl.appendingPathComponent(name)
			try FileManager.default.copyItem(
				at: self.directoryUrl,
				to: destinationUrl
			)
		}
		
	}
	
	/// Possible types of the ``Snapshot``
	public enum `Type`: String, Codable, CaseIterable {
		case text
		case site
	}
	
	/// Static function for equatable conformance
	public static func == (lhs: Snapshot, rhs: Snapshot) -> Bool {
		return lhs.id == rhs.id
	}
	
	public enum ExtractionError: Error {
		case noSelectedConversation
		case noAssistantMessages
		case couldNotLocateUserMessage
		case alreadyExtractedSnapshot
		case failedToExtractSnapshot
	}
	
}

public extension Snapshot {
	
	/// Function to create a snapshot object by extracting code from a markdown formatted string
	static func extractCode(
		from markdown: String
	) -> Snapshot? {
		// Dictionary to group code blocks by language.
		// The key is the language (or "plaintext") and the value stores an array of code snippets.
		var codeBlocks: [String: [String]] = [:]
		// Regular expression pattern to capture code fences.
		// Group 1 captures an optional language identifier.
		// Group 2 captures the code block content.
		let pattern = "```(\\w+)?\\s*\\n(.*?)\\n```"
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
			let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
			let matches = regex.matches(in: markdown, options: [], range: range)
			
			// Iterate over each regex match.
			for match in matches {
				// Default language if not provided.
				var language = "plaintext"
				// Attempt to capture the language from group 1.
				let languageRange = match.range(at: 1)
				if languageRange.length > 0, let langRange = Range(languageRange, in: markdown) {
					language = String(markdown[langRange])
				}
				// Capture the code snippet from group 2.
				let codeRange = match.range(at: 2)
				guard let codeCaptureRange = Range(codeRange, in: markdown) else { continue }
				let codeSnippet = String(markdown[codeCaptureRange])
				
				// Group the code snippet under the identified language.
				if var snippets = codeBlocks[language] {
					snippets.append(codeSnippet)
					codeBlocks[language] = snippets
				} else {
					codeBlocks[language] = [codeSnippet]
				}
			}
			// Return nil if no code blocks were found.
			if codeBlocks.isEmpty {
				return nil
			}
			// Determine the language with the most lines of code.
			var maxLines = 0
			var selectedLanguage: String?
			for (language, snippets) in codeBlocks {
				// Count the total number of lines in all snippets for this language.
				let totalLines = snippets.reduce(0) { count, snippet in
					count + snippet.components(separatedBy: .newlines).count
				}
				if totalLines > maxLines {
					maxLines = totalLines
					selectedLanguage = language
				}
			}
			// If language has 1 line of code, return nil
			let lineThreshold: Int = 1
			if maxLines <= lineThreshold {
				return nil
			}
			// If no language was selected, return nil.
			guard let languageWithMostLines = selectedLanguage,
				  let selectedSnippets = codeBlocks[languageWithMostLines] else {
				return nil
			}
			// Combine the code snippets for the language with the most lines.
			let aggregatedCode = selectedSnippets.joined(separator: "\n\n")
			// Create and return a Snapshot with the aggregated code as its text.
			return Snapshot(text: aggregatedCode)
		} catch {
			// If regex fails or any other error occurs, return nil.
			return nil
		}
	}
	
}

public extension Snapshot.Site {
	
	/// Function to extract a Site object from a markdown formatted string
	static func extractSite(
		from markdown: String
	) -> Snapshot.Site? {
		// This regex matches code blocks with an optional language identifier.
		// Capture group 1: language (if provided)
		// Capture group 2: the actual code block content (including newlines)
		let pattern = "```(\\w+)?\\n([\\s\\S]*?)```"
		do {
			let regex = try NSRegularExpression(
				pattern: pattern, options: []
			)
			let nsRange = NSRange(
				markdown.startIndex..<markdown.endIndex, in: markdown
			)
			let matches = regex.matches(
				in: markdown, options: [], range: nsRange
			)
			// Set variables
			var htmlCode: String? = nil
			var cssCode: String? = nil
			var jsCode: String? = nil
			// Check all regex matches
			for match in matches {
				guard match.numberOfRanges >= 3 else {
					continue
				}
				let languageRange = match.range(at: 1)
				let codeRange = match.range(at: 2)
				if let languageRange = Range(languageRange, in: markdown),
				   let codeRange = Range(codeRange, in: markdown) {
					let language = String(markdown[languageRange]).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
					let code = String(markdown[codeRange])
					switch language {
						case "html":
							htmlCode = code
						case "css":
							cssCode = code
						case "js", "javascript":
							jsCode = code
						default:
							// If there's no language or an unrecognized language, ignore it.
							continue
					}
				}
			}
			// HTML code is required, so make sure it exists
			if let htmlCode = htmlCode {
				return Snapshot.Site(
					html: htmlCode,
					css: cssCode,
					js: jsCode
				)
			}
			return nil
		} catch {
			return nil
		}
	}
	
}
