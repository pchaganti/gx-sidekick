//
//  Extension+String.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import AppKit
import Foundation
import Highlightr

public extension String {
	
	func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
		var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
		hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
		
		var rgb: UInt64 = 0
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var a: CGFloat = 1.0
		
		Scanner(string: hexSanitized).scanHexInt64(&rgb)
		
		r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
		g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
		b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
		a = CGFloat(rgb & 0x000000FF) / 255.0
		
		return (r, g, b, a)
	}
	
	/// Splits a string into groups of `every` n characters, grouping from left-to-right by default. If `backwards` is true, right-to-left.
	func split(every: Int, backwards: Bool = false) -> [String] {
		var result = [String]()
		for i in stride(from: 0, to: self.count, by: every) {
			switch backwards {
				case true:
					let endIndex = self.index(self.endIndex, offsetBy: -i)
					let startIndex = self.index(endIndex, offsetBy: -every, limitedBy: self.startIndex) ?? self.startIndex
					result.insert(String(self[startIndex..<endIndex]), at: 0)
				case false:
					let startIndex = self.index(self.startIndex, offsetBy: i)
					let endIndex = self.index(startIndex, offsetBy: every, limitedBy: self.endIndex) ?? self.endIndex
					result.append(String(self[startIndex..<endIndex]))
			}
		}
		
		return result
	}
	
	
	func slice(from: String, to: String) -> String? {
		return (range(of: from)?.upperBound).flatMap { substringFrom in
			(range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
				String(self[substringFrom..<substringTo])
			}
		}
	}
	
	/// Function to copy the string to the clipboard
	func copy() {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.declareTypes([.string], owner: nil)
		pasteboard.setString(self, forType: .string)
	}
	
	/// Function to copy the string to the clipboard while preserving formatting
	func copyWithFormatting() {
		if let highlightr: Highlightr = Highlightr() {
			highlightr.setTheme(to: "purebasic.min")
			// Convert the string to an attributed string with Markdown highlighting
			if let attributedString: NSAttributedString = highlightr.highlight(
				self,
				as: "markdown"
			) {
				// Create a mutable copy to perform modifications
				let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
				// Process markdown elements using dedicated NSAttributedString extensions
				mutableAttributedString.convertCourierFonts()
				mutableAttributedString.removeTextColor()
				mutableAttributedString.processMarkdownImages()
				mutableAttributedString.processMarkdownLinks()
				mutableAttributedString.processMarkdownHeadings()
				mutableAttributedString.removeMarkdownBlockCodes()
				mutableAttributedString.removeMarkdownDividers()
				mutableAttributedString.stripMarkdownSymbols()
				// Copy the processed attributed string to the pasteboard
				mutableAttributedString.copyToPasteboard()
				return
			}
		}
		// If failed, just copy plain text
		self.copy()
	}
	
	/// Function to add a trailing quote or space if needed
	func removeUnmatchedTrailingQuote() -> String {
		var outputString = self
		if self.last != "\"" { return outputString }
		
		// Count the number of quotes in the string
		let countOfQuotes = outputString.reduce(
			0,
			{ (count, character) -> Int in
				return character == "\"" ? count + 1 : count
			})
		
		// If there is an odd number of quotes, remove the last one
		if countOfQuotes % 2 != 0 {
			if let indexOfLastQuote = outputString.lastIndex(of: "\"") {
				outputString.remove(at: indexOfLastQuote)
			}
		}
		
		return outputString
	}
	
	/// Function to split a string by sentence
	func splitBySentence() -> [String] {
		var sentences: [String] = []
		self.enumerateSubstrings(in: self.startIndex..., options: [.localized, .bySentences]) { (tag, _, _, _) in
			let sentence: String = tag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			sentences.append(sentence)
		}
		return sentences
	}
	
	/// Function to group sentences into chunks
	func groupIntoChunks(maxChunkSize: Int) -> [String] {
		// Split into sentences
		let sentences: [String] = self.splitBySentence()
		// Group
		var chunks: [String] = []
		var chunk: [String] = []
		for (index, sentence) in sentences.enumerated() {
			// Calculate length accounting for spaces
			let chunkLength: Int = chunk.map(\.count).reduce(0,+) + sentence.count - 1
			let islastSentence: Bool = index == (sentences.count - 1)
			if chunkLength < maxChunkSize || islastSentence {
				chunk.append(sentence)
			} else {
				chunks.append(chunk.joined(separator: " "))
				chunk.removeAll()
			}
		}
		// Return result
		return chunks
	}
	
	subscript (i: Int) -> String {
		return self[i ..< i + 1]
	}
	
	func substring(fromIndex: Int) -> String {
		return self[min(fromIndex, count)..<count]
	}
	
	func substring(toIndex: Int) -> String {
		return self[0 ..< max(0, toIndex)]
	}
	
	subscript (r: Range<Int>) -> String {
		let range = Range(
			uncheckedBounds: (
				lower: max(
					0,
					min(count, r.lowerBound)
				),
				upper: min(count, max(0, r.upperBound))
			)
		)
		let start = index(startIndex, offsetBy: range.lowerBound)
		let end = index(start, offsetBy: range.upperBound - range.lowerBound)
		return String(self[start ..< end])
	}
	
	/// An `NSString` derived from the string
	private var nsString: NSString {
		return NSString(string: self)
	}
	
	/// Function to split the string into LaTeX and non-LaTeX sections
	func splitByLatex() -> [(string: String, isLatex: Bool)] {
		// Regex pattern to match LaTeX
		let latexPattern: String = "(\\\\\\[(.*?)\\\\\\])|(\\$\\$(.*?)\\$\\$)"
		let regex = try! NSRegularExpression(
			pattern: latexPattern,
			options: [.dotMatchesLineSeparators]
		)
		
		// Define variables
		var sections: [(string: String, isLatex: Bool)] = []
		var lastIndex = 0
		
		// Get matches
		let matches = regex.matches(
			in: self,
			options: [],
			range: NSRange(location: 0, length: self.utf16.count)
		)
		
		// Loop through matches
		for match in matches {
			let matchRange = match.range
			
			// Add text before LaTeX if any
			if matchRange.location > lastIndex {
				let textRange = NSRange(location: lastIndex, length: matchRange.location - lastIndex)
				let textSection = nsString.substring(with: textRange)
				if !textSection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					sections.append((textSection, false))
				}
			}
			
			// Add LaTeX section
			let latexSection = nsString.substring(with: matchRange)
			sections.append((latexSection, true))
			
			lastIndex = matchRange.location + matchRange.length
		}
		
		// Add remaining text if any
		if lastIndex < self.utf16.count {
			let textSection = nsString.substring(from: lastIndex)
			if !textSection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				sections.append((textSection, false))
			}
		}
		
		return sections
	}
	
	/// Function to replace the suffix in a `String`
	func replacingSuffix(_ suffix: String, with newSuffix: String) -> String {
		if self.hasSuffix(suffix) {
			return self.dropLast(suffix.count) + newSuffix
		}
		return self
	}
	
	/// Function to drop all characters preceding a substring
	func dropPrecedingSubstring(
		_ substring: String,
		options: String.CompareOptions = [],
		includeCharacter: Bool = false
	) -> String {
		// Find the range of the substring
		guard let range = self.range(
			of: substring,
			options: options
		) else {
			// Return the original string if the substring is not found
			return self
		}
		// Drop substring
		if !includeCharacter {
			return String(self[range.upperBound...])
		} else {
			return String(self[range.lowerBound...])
		}
	}
	
	/// Function to drop all characters following a substring
	func dropFollowingSubstring(
		_ substring: String,
		options: String.CompareOptions = [],
		includeCharacter: Bool = false
	) -> String {
		// Find the range of the substring
		guard let range = self.range(
			of: substring,
			options: options
		) else {
			// Return the original string if the substring is not found
			return self
		}
		// Drop substring
		if !includeCharacter {
			return String(self[..<range.lowerBound])
		} else {
			return String(self[...range.lowerBound])
		}
	}
	
	/// Function to remove enclosing characters
	func removeEnclosingCharacters(
		character: Character
	) -> String {
		guard self.hasPrefix(String(character)) && self
			.hasSuffix(String(character)) else {
			return self
		}
		return String(self.dropFirst().dropLast())
	}
	
	/// Computed property returning text with the resoning process removed
	var reasoningRemoved: String {
		// List special reasoning tokens
		let specialTokenSets: [[String]] = [
			["<think>", "</think>"],
			["<thought>", "</thought>"]
		]
		// Init variable for stripped text
		var processedResponse: String = self
		// Extract text
		for tokenSet in specialTokenSets {
			// If only the first token is found, return empty response
			if self.contains(tokenSet.first!) && !self.contains(tokenSet.last!) {
				return ""
			}
			// Extract text between tokens
			if let startRange = processedResponse.range(of: tokenSet.first!),
			   let endRange = processedResponse.range(
				of: tokenSet.last!,
				range: startRange.upperBound..<processedResponse.endIndex
			   ) {
				// Remove reasoning tokens and the text inside them
				processedResponse.removeSubrange(startRange.lowerBound..<endRange.upperBound)
			}
		}
		// Return clean result
		return processedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	/// Function to convert LaTeX within a string into a Markdown image block containing a URL-encoded version
	func convertLaTeX() -> String {
		// Updated regex pattern:
		//   • Block LaTeX using \[ ... \] or $$ ... $$
		//   • Inline LaTeX using \( ... \)
		//   • Inline LaTeX using $...$, where the content is any character except '$'
		let pattern: String = "(\\\\\\[(?:.|\\s)*?\\\\\\])|(\\$\\$(?:.|\\s)*?\\$\\$)|(\\\\\\((?:.|\\s)*?\\\\\\))|(\\$(?!\\$)([^$]|\\$(?=[^$]))+\\$)"
		guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
			return self
		}
		let mutableText: NSMutableString = NSMutableString(string: self)
		let matches: [NSTextCheckingResult] = regex.matches(
			in: self,
			options: [],
			range: NSRange(location: 0, length: mutableText.length)
		)
		// Iterate backwards so that range replacements don't affect upcoming ranges.
		for match in matches.reversed() {
			let fullRange = match.range(at: 0)
			guard let range = Range(fullRange, in: self) else { continue }
			// Capture the entire LaTeX string (including delimiters).
			let rawLaTeX = String(self[range])
			// Determine if this is a block LaTeX expression.
			// Considering only block LaTeX using \[ and $$.
			let isBlock: Bool = rawLaTeX.hasPrefix("\\[") || rawLaTeX.hasPrefix("$$")
			// Check for new lines in inline LaTeX, which is not allowed
			if rawLaTeX.contains("\n") && !isBlock {
				continue
			}
			// Remove newlines and extra spaces.
			let stripped = rawLaTeX
				.replacingOccurrences(of: "\n", with: " ")
				.trimmingCharacters(in: .whitespacesAndNewlines)
			// Percent-encode the full, stripped LaTeX expression.
			var allowed = CharacterSet.alphanumerics
			allowed.insert(charactersIn: ".-_~")
			let encoded = stripped.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
			// Compose the Markdown image. Block LaTeX gets newlines before and after.
			let replacement = (isBlock ? "\n" : "") + "![](latex://\(encoded))" + (isBlock ? "\n" : "")
			regex.replaceMatches(in: mutableText, options: [], range: fullRange, withTemplate: replacement)
		}
		return mutableText as String
	}
	
	/// Functions to extract email addresses from a `String`
	func extractEmailAddresses() -> [String] {
		var results = [String]()
		let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
		let nsText = self as NSString
		do {
			let regExp = try NSRegularExpression(pattern: emailRegex, options: .caseInsensitive)
			let range = NSMakeRange(0, self.count)
			let matches = regExp.matches(in: self, options: .reportProgress, range: range)
			
			for match in matches {
				let matchRange = match.range
				results.append(nsText.substring(with: matchRange))
			}
		} catch (let error) {
			print(error)
		}
		return results
	}
	
	/// Returns a string with each word capitalized
	var capitalizeEachWord: String {
		let words: [String] = self.split(separator: " ").map { String($0) }
		let capitalizedWords: [String] = words.map { word in
			if word.uppercased() != word {
				return word.capitalized
			}
			return word
		}
		return capitalizedWords.joined(separator: " ")
	}
	
}
