//
//  Extension+NSMutableAttributedString.swift
//  Sidekick
//
//  Created by John Bean on 3/17/25.
//

import Foundation
import AppKit

public extension NSMutableAttributedString {
	
	/// Function to convert all text with font "Courier" to use the Apple System font
	func convertCourierFonts() {
		let fullRange = NSRange(location: 0, length: self.length)
		self.enumerateAttribute(.font, in: fullRange, options: []) { (value, range, _) in
			guard let font = value as? NSFont else { return }
			// Check the font family name or fontName
			if font.fontName == "Courier" {
				// Replace with the Apple System font preserving the font size.
				let newFont = NSFont.systemFont(ofSize: font.pointSize)
				self.addAttribute(.font, value: newFont, range: range)
			} else if font.fontName == "Courier-Bold" {
				// Replace with the Bold Apple System font preserving the font size.
				let newFont = NSFont.boldSystemFont(ofSize: font.pointSize)
				self.addAttribute(.font, value: newFont, range: range)
			}
		}
	}
	
	/// Function to process Markdown images in the attributed string.
	/// It searches for patterns like ![alt text](URL) and replaces them with an image attachment if available,
	/// or falls back to the alt text if the image cannot be loaded.
	func processMarkdownImages() {
		// Regex pattern to match Markdown images: ![alt text](image URL)
		let markdownImagePattern = "!\\[(.*?)\\]\\((.*?)\\)"
		guard let imageRegex = try? NSRegularExpression(pattern: markdownImagePattern, options: []) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = imageRegex.matches(in: self.string, options: [], range: fullRange)
		// Process matches in reverse order to avoid range issues.
		for match in matches.reversed() {
			guard match.numberOfRanges == 3,
				  let altTextRange = Range(match.range(at: 1), in: self.string),
				  let urlRange = Range(match.range(at: 2), in: self.string)
			else { continue }
			
			let altText = String(self.string[altTextRange])
			let urlString = String(self.string[urlRange])
			var replacement: NSAttributedString
			if let url = URL(string: urlString),
			   let data = try? Data(contentsOf: url),
			   let image = NSImage(data: data) {
				// Create an attachment with the loaded image.
				let textAttachment = NSTextAttachment()
				textAttachment.image = image
				replacement = NSAttributedString(attachment: textAttachment)
			} else {
				// Fallback to using the alt text if the image cannot be loaded.
				replacement = NSAttributedString(string: altText)
			}
			self.replaceCharacters(in: match.range, with: replacement)
		}
	}
	
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
	
	/// Function to process Markdown headings in the attributed string.
	func processMarkdownHeadings() {
		// Regex pattern to match markdown headings (levels 1 to 6)
		let headingPattern = "^(\\s*#{1,6})\\s+(.*)$"
		guard let headingRegex = try? NSRegularExpression(pattern: headingPattern, options: [.anchorsMatchLines]) else {
			return
		}
		let fullRange = NSRange(location: 0, length: self.length)
		let matches = headingRegex.matches(in: self.string, options: [], range: fullRange)
		// Process matches in reverse to avoid shifting range issues
		for match in matches.reversed() {
			guard match.numberOfRanges == 3 else { continue }
			let markerRange = match.range(at: 1)
			let textRange = match.range(at: 2)
			// Retrieve the marker and heading text.
			let markerString = (self.string as NSString).substring(with: markerRange)
			let headingText = (self.string as NSString).substring(with: textRange)
			// Determine the heading level based on the number of '#' characters
			let level = markerString.trimmingCharacters(in: .whitespaces).count
			// Choose a font size based on the heading level
			let fontSize: CGFloat
			switch (level - 1) {
				case 1: fontSize = 32
				case 2: fontSize = 28
				case 3: fontSize = 24
				case 4: fontSize = 20
				case 5: fontSize = 16
				default: fontSize = 14
			}
			// Create a new attributed string for the heading text, adding a new line before and after the heading
			let formattedHeadingText = "\n" + headingText + "\n"
			let newHeadingAttributedString = NSMutableAttributedString(string: formattedHeadingText)
			newHeadingAttributedString.addAttribute(
				.font,
				value: NSFont.boldSystemFont(ofSize: fontSize),
				range: NSRange(location: 0, length: newHeadingAttributedString.length)
			)
			// Replace the entire matched heading with the new styled heading
			self.replaceCharacters(in: match.range, with: newHeadingAttributedString)
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
	
	/// Function to remove the text color of all characters in the attributed string
	func removeTextColor() {
		let fullRange = NSRange(location: 0, length: self.length)
		// Enumerate through the attributed string and set the foreground color to black for each range.
		self.removeAttribute(.foregroundColor, range: fullRange)
	}
	
}
