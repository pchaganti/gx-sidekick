//
//  TemporaryResource.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import ExtractKit_macOS
import Foundation

public struct TemporaryResource: Identifiable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the resource's url
	public var url: URL
	
	/// Stored property for the quick resource's text
	public var text: String?
	
	/// Stored property containing the scan state
	public var state: ScanState = .notScanned
	
	/// Function to scan the resource
	public mutating func scan() async throws -> Bool {
		let text: String? = try? await ExtractKit.shared.extractText(
			url: url
		)
		if let text {
			self.text = text
			self.state = .scanned
			return true
		} else {
			self.state = .failed
			return false
		}
	}
	
	/// Enum for scan state
	public enum ScanState: String, CaseIterable {
		case failed
		case notScanned
		case scanned
	}
	
}
