//
//  Extension+NSMutableAttributedString.swift
//  Sidekick
//
//  Created by John Bean on 3/17/25.
//

import Foundation

public extension NSMutableAttributedString {
	
	/// Function to process Markdown links in the attributed string.
	/// It searches for patterns like [link text](URL) and replaces them with
	/// the link text while adding the appropriate `.link` attribute.
	func processMarkdownLinks() {
		// Regex pattern to match Markdown links.
		let markdownLinkPattern = "\\[(.*?)\\]\\((.*?)\\)"
		guard let linkRegex = try? NSRegularExpression(pattern: markdownLinkPattern, options: []) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = linkRegex.matches(in: self.string, options: [], range: fullRange)
		
		// Replace matches in reverse order to avoid range conflicts.
		for match in matches.reversed() {
			guard match.numberOfRanges == 3,
				  let textRange = Range(match.range(at: 1), in: self.string),
				  let urlRange = Range(match.range(at: 2), in: self.string)
			else { continue }
			
			let linkText = String(self.string[textRange])
			let urlString = String(self.string[urlRange])
			
			// Create a replacement with the link text.
			let replacement = NSMutableAttributedString(string: linkText)
			if let url = URL(string: urlString) {
				replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: replacement.length))
			}
			
			self.replaceCharacters(in: match.range, with: replacement)
		}
	}
	
	/// Function to remove Markdown block code markers (e.g., lines that contain only ``` or ``\`swift)
	func removeMarkdownBlockCodes() {
		let blockCodePattern = "^(\\s*```.*\\s*)$"
		guard let blockCodeRegex = try? NSRegularExpression(pattern: blockCodePattern, options: [.anchorsMatchLines]) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = blockCodeRegex.matches(in: self.string, options: [], range: fullRange)
		
		// Remove each block code marker, processing matches in reverse.
		for match in matches.reversed() {
			self.deleteCharacters(in: match.range)
		}
	}
	
	/// Function to remove Markdown dividers (e.g., --- or *** on a line by themselves)
	func removeMarkdownDividers() {
		let dividerPattern = "^(\\s*[-*]{3,}\\s*)$"
		guard let dividerRegex = try? NSRegularExpression(pattern: dividerPattern, options: [.anchorsMatchLines]) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = dividerRegex.matches(in: self.string, options: [], range: fullRange)
		
		// Remove each divider line by processing matches in reverse.
		for match in matches.reversed() {
			self.deleteCharacters(in: match.range)
		}
	}
	
	/// Function to strip common Markdown symbols (e.g., **, __, *, _, #, >, `)
	func stripMarkdownSymbols() {
		let markdownSymbolsPattern = "(\\*\\*|__|\\*|_|\\#|\\>|\\`)"
		guard let symbolRegex = try? NSRegularExpression(pattern: markdownSymbolsPattern, options: []) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = symbolRegex.matches(in: self.string, options: [], range: fullRange)
		
		// Remove all markdown symbols, processing in reverse to preserve correct indices.
		for match in matches.reversed() {
			self.deleteCharacters(in: match.range)
		}
	}
	
}
