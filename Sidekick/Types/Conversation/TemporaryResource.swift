//
//  TemporaryResource.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import ExtractKit_macOS
import Foundation

public struct TemporaryResource: Identifiable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the resource's url
	public var url: URL
	
	/// Computed property for the resource's displayed name
	public var name: String {
		if self.url.isWebURL {
			return self.url.host(percentEncoded: false) ??
			self.url.absoluteString
		}
		return self.url.lastPathComponent
	}
	
	/// Computed property for the resource's name
	public var fullName: String {
		if self.url.isWebURL {
			return self.url.absoluteString
		}
		return self.url.posixPath
	}
	
	/// Stored property for the quick resource's text
	public var text: String? = nil
	
	/// Stored property containing the scan state
	public var state: ScanState = .notScanned
	
	/// Function to scan the resource
	@MainActor
	public mutating func scan() async -> Bool {
		let text: String? = try? await ExtractKit.shared.extractText(
			url: url
		)
		// Update state
		if let text {
			self.text = text
			self.state = .scanned
			return true
		} else {
			self.state = .failed
			return false
		}
	}
	
	/// Computed property returning text given to the model
	public var source: Source? {
		// Capture variable
		guard let text else { return nil }
		return Source(
			text: text,
			source: self.fullName
		)
	}
	
	/// Enum for scan state
	public enum ScanState: String, CaseIterable, Sendable {
		case failed
		case notScanned
		case scanned
	}
	
}
