//
//  GraphRelationship.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation

/// A relationship between two entities in the knowledge graph
public struct GraphRelationship: Identifiable, Codable, Hashable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The source entity ID
	public var sourceEntityId: UUID
	
	/// The target entity ID
	public var targetEntityId: UUID
	
	/// The type of relationship (e.g., "works_at", "located_in", "related_to")
	public var relationshipType: String
	
	/// A description of the relationship
	public var description: String
	
	/// The strength/confidence score of this relationship (0.0 to 1.0)
	public var strength: Float
	
	/// Array of source chunk indices where this relationship is evidenced
	public var sourceChunks: [Int]
	
	/// Initializer
	init(
		id: UUID = UUID(),
		sourceEntityId: UUID,
		targetEntityId: UUID,
		relationshipType: String,
		description: String,
		strength: Float = 1.0,
		sourceChunks: [Int] = []
	) {
		self.id = id
		self.sourceEntityId = sourceEntityId
		self.targetEntityId = targetEntityId
		self.relationshipType = relationshipType
		self.description = description
		self.strength = min(max(strength, 0.0), 1.0) // Clamp to 0-1
		self.sourceChunks = sourceChunks
	}
	
	/// Stub for `Equatable` conformance
	public static func == (lhs: GraphRelationship, rhs: GraphRelationship) -> Bool {
		lhs.id == rhs.id
	}
	
	/// Hash function for `Hashable` conformance
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

