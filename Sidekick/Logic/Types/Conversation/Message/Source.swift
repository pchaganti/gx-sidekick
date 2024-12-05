//
//  Source.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import Foundation

public struct Source: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The text in the source
	public var text: String
	
	/// The name of the source
	public var source: String
	
}

public struct Sources: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The `UUID` of the message the souces are related to
	public var messageId: UUID
	/// An array of type ``Source``
	public var sources: [Source]
	
}
