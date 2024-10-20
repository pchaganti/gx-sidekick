//
//  Source.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import Foundation

public struct Source: Identifiable, Codable, Hashable {
	
	public var id: UUID = UUID()
	
	public var text: String
	public var source: String
	
}

public struct Sources: Identifiable, Codable, Hashable {
	
	public var id: UUID = UUID()
	
	public var messageId: UUID
	public var sources: [Source]
	
}
