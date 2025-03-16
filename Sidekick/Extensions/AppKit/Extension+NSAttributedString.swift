//
//  Extension+NSAttributedString.swift
//  Sidekick
//
//  Created by John Bean on 3/16/25.
//

import Foundation
import AppKit

public extension NSAttributedString {
	
	/// Function to copy an `NSAttributedString` to the clipboard
	func copyToPasteboard() {
		// Declare and reset the clipboard
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		// Declare the types we'll be providing
		pasteboard.declareTypes([.rtf, .string], owner: nil)
		do {
			// Try to get RTF data
			let rtfData = try self.data(
				from: NSRange(location: 0, length: length),
				documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]
			)
			pasteboard.setData(rtfData, forType: .rtf)
		} catch {
			// Always include plain text as a fallback
			pasteboard.setString(string, forType: .string)
		}
	}
}
