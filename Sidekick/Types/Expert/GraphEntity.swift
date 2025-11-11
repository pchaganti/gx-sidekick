//
//  GraphEntity.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation

/// An entity extracted from text in the knowledge graph
public struct GraphEntity: Identifiable, Codable, Hashable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The entity's name
	public var name: String
	
	/// The entity's type (e.g., "Person", "Organization", "Concept")
	public var type: String
	
	/// A description of the entity
	public var description: String
	
	/// Array of source chunk indices where this entity appears
	public var sourceChunks: [Int]
	
	/// The embedding vector for semantic similarity search
	public var embedding: [Float]?
	
	/// Initializer
	init(
		id: UUID = UUID(),
		name: String,
		type: String,
		description: String,
		sourceChunks: [Int] = [],
		embedding: [Float]? = nil
	) {
		self.id = id
		self.name = name
		self.type = type
		self.description = description
		self.sourceChunks = sourceChunks
		self.embedding = embedding
	}
	
	/// Stub for `Equatable` conformance
	public static func == (lhs: GraphEntity, rhs: GraphEntity) -> Bool {
		lhs.id == rhs.id
	}
	
	/// Hash function for `Hashable` conformance
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

