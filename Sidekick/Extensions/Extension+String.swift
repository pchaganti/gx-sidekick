//
//  Extension+String.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import AppKit

extension String {
	
	public func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
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
	public func split(every: Int, backwards: Bool = false) -> [String] {
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
	
	
	public func slice(from: String, to: String) -> String? {
		return (range(of: from)?.upperBound).flatMap { substringFrom in
			(range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
				String(self[substringFrom..<substringTo])
			}
		}
	}
	
	/// Function to copy the string to the clipboard
	public func copy() {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.declareTypes([.string], owner: nil)
		pasteboard.setString(self, forType: .string)
	}
	
}
