//
//  Extension+String.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import AppKit

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
	
	/// Function to replace escaping unicode characters
	func replaceUnicodeEscapes() -> String {
		var result: String = self
		// Replace `\n`, `\t`, etc.
		let escapeSequences: [String: String] = [
			"\\n": "\n",
			"\\t": "\t",
			"\\r": "\r",
			"\\\"": "\"",
			"\\'": "'",
			"\\\\": "\\"
		]
		for (escape, character) in escapeSequences {
			result = result.replacingOccurrences(of: escape, with: character)
		}
		// Replace `\u{...}` sequences
		let regexPattern = #"\\u\{([0-9A-Fa-f]+)\}"#
		let regex = try? NSRegularExpression(pattern: regexPattern)
		
		let matches = regex?.matches(in: result, range: NSRange(result.startIndex..., in: result)) ?? []
		
		for match in matches.reversed() {
			if let range = Range(match.range(at: 1), in: result) {
				let unicodeValue = String(result[range])
				if let unicodeScalar = UnicodeScalar(Int(unicodeValue, radix: 16)!) {
					let unicodeCharacter = String(unicodeScalar)
					if let fullRange = Range(match.range, in: result) {
						result.replaceSubrange(fullRange, with: unicodeCharacter)
					}
				}
			}
		}
		return result
	}
	
	/// Function to drop all characters preceding a substring
	func dropPrecedingSubstring(_ substring: String) -> String {
		// Find the range of the substring
		guard let range = self.range(of: substring) else {
			return self
		}
		// Drop everything up to and including the substring
		let result = self[range.upperBound...]
		return String(result)
	}
	
	/// Function to drop all characters following a substring
	func dropFollowingSubstring(_ substring: String) -> String {
		// Find the range of the substring
		guard let range = self.range(of: substring) else {
			return self // Return the original string if the substring is not found
		}
		// Remove everything from the start of the substring to the end of the string
		let result = self[..<range.lowerBound]
		return String(result)
	}
	
}
