//
//  KnowledgeGraph.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import SQLite
import OSLog

/// A knowledge graph containing entities, relationships, and hierarchical communities
public class KnowledgeGraph: Codable {
	
	/// A `Logger` object for ``KnowledgeGraph`` objects
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: KnowledgeGraph.self)
	)
	
	/// Dictionary mapping entity IDs to entities
	private var entitiesDict: [UUID: GraphEntity] = [:]
	
	/// Array of all relationships
	public var relationships: [GraphRelationship] = []
	
	/// Array of all communities (hierarchical)
	public var communities: [Community] = []
	
	/// Mapping from chunk index to entity IDs that appear in that chunk
	public var chunkToEntities: [Int: Set<UUID>] = [:]
	
	/// The resource ID this graph belongs to
	public var resourceId: UUID
	
	// MARK: - Computed Properties
	
	/// Computed property returning all entities as an array
	public var entities: [GraphEntity] {
		return Array(entitiesDict.values)
	}
	
	/// Computed property returning entity count
	public var entityCount: Int {
		return entitiesDict.count
	}
	
	/// Computed property returning relationship count
	public var relationshipCount: Int {
		return relationships.count
	}
	
	/// Computed property returning community count
	public var communityCount: Int {
		return communities.count
	}
	
	// MARK: - Initialization
	
	init(resourceId: UUID) {
		self.resourceId = resourceId
	}
	
	// MARK: - Entity Management
	
	/// Add an entity to the graph
	/// - Parameter entity: The entity to add
	public func addEntity(_ entity: GraphEntity) {
		entitiesDict[entity.id] = entity
		
		// Update chunk mappings
		for chunkIndex in entity.sourceChunks {
			if chunkToEntities[chunkIndex] == nil {
				chunkToEntities[chunkIndex] = Set()
			}
			chunkToEntities[chunkIndex]?.insert(entity.id)
		}
	}
	
	/// Add multiple entities to the graph
	/// - Parameter entities: The entities to add
	public func addEntities(_ entities: [GraphEntity]) {
		for entity in entities {
			addEntity(entity)
		}
	}
	
	/// Find an entity by ID
	/// - Parameter id: The entity ID
	/// - Returns: The entity if found
	public func findEntity(id: UUID) -> GraphEntity? {
		return entitiesDict[id]
	}
	
	/// Find an entity by name
	/// - Parameter name: The entity name
	/// - Returns: The entity if found
	public func findEntity(name: String) -> GraphEntity? {
		return entitiesDict.values.first { $0.name.lowercased() == name.lowercased() }
	}
	
	/// Update an existing entity
	/// - Parameter entity: The updated entity
	public func updateEntity(_ entity: GraphEntity) {
		// Remove old chunk mappings
		if let oldEntity = entitiesDict[entity.id] {
			for chunkIndex in oldEntity.sourceChunks {
				chunkToEntities[chunkIndex]?.remove(entity.id)
			}
		}
		
		// Add entity with new mappings
		addEntity(entity)
	}
	
	// MARK: - Relationship Management
	
	/// Add a relationship to the graph
	/// - Parameter relationship: The relationship to add
	public func addRelationship(_ relationship: GraphRelationship) {
		// Validate that both entities exist
		guard entitiesDict[relationship.sourceEntityId] != nil,
		      entitiesDict[relationship.targetEntityId] != nil else {
			Self.logger.warning("Attempted to add relationship with non-existent entities")
			return
		}
		
		relationships.append(relationship)
	}
	
	/// Add multiple relationships to the graph
	/// - Parameter relationships: The relationships to add
	public func addRelationships(_ relationships: [GraphRelationship]) {
		for relationship in relationships {
			addRelationship(relationship)
		}
	}
	
	/// Get all relationships for a given entity
	/// - Parameter entityId: The entity ID
	/// - Returns: Array of relationships where the entity is source or target
	public func getRelationships(for entityId: UUID) -> [GraphRelationship] {
		return relationships.filter {
			$0.sourceEntityId == entityId || $0.targetEntityId == entityId
		}
	}
	
	/// Get related entities for a given entity (entities connected by relationships)
	/// - Parameter entityId: The entity ID
	/// - Returns: Array of related entities
	public func getRelatedEntities(for entityId: UUID) -> [GraphEntity] {
		let relatedIds = relationships.filter {
			$0.sourceEntityId == entityId || $0.targetEntityId == entityId
		}.flatMap { rel in
			[rel.sourceEntityId, rel.targetEntityId]
		}.filter { $0 != entityId }
		
		return relatedIds.compactMap { entitiesDict[$0] }
	}
	
	// MARK: - Community Management
	
	/// Add a community to the graph
	/// - Parameter community: The community to add
	public func addCommunity(_ community: Community) {
		communities.append(community)
	}
	
	/// Add multiple communities to the graph
	/// - Parameter communities: The communities to add
	public func addCommunities(_ communities: [Community]) {
		self.communities.append(contentsOf: communities)
	}
	
	/// Get all communities at a specific level
	/// - Parameter level: The hierarchical level
	/// - Returns: Array of communities at that level
	public func getCommunities(at level: Int) -> [Community] {
		return communities.filter { $0.level == level }
	}
	
	// MARK: - Chunk Queries
	
	/// Get all entities that appear in a specific chunk
	/// - Parameter chunkIndex: The chunk index
	/// - Returns: Array of entities in that chunk
	public func getEntities(inChunk chunkIndex: Int) -> [GraphEntity] {
		guard let entityIds = chunkToEntities[chunkIndex] else {
			return []
		}
		return entityIds.compactMap { entitiesDict[$0] }
	}
	
	/// Get all entities that appear in any of the given chunks
	/// - Parameter chunkIndices: The chunk indices
	/// - Returns: Array of unique entities
	public func getEntities(inChunks chunkIndices: [Int]) -> [GraphEntity] {
		var entityIds = Set<UUID>()
		for chunkIndex in chunkIndices {
			if let ids = chunkToEntities[chunkIndex] {
				entityIds.formUnion(ids)
			}
		}
		return entityIds.compactMap { entitiesDict[$0] }
	}
	
	// MARK: - Graph Statistics
	
	/// Get statistics about the graph
	/// - Returns: Dictionary with statistics
	public func getStatistics() -> [String: Int] {
		return [
			"entities": entityCount,
			"relationships": relationshipCount,
			"communities": communityCount,
			"chunks_with_entities": chunkToEntities.count
		]
	}
	
	// MARK: - Merge
	
	/// Merge another knowledge graph into this one
	/// - Parameter other: The graph to merge
	public func merge(_ other: KnowledgeGraph) {
		// Merge entities
		for entity in other.entities {
			addEntity(entity)
		}
		
		// Merge relationships
		for relationship in other.relationships {
			addRelationship(relationship)
		}
		
		// Merge communities
		addCommunities(other.communities)
	}
	
	// MARK: - Codable
	
	enum CodingKeys: String, CodingKey {
		case entitiesDict
		case relationships
		case communities
		case chunkToEntities
		case resourceId
	}
	
	required public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		entitiesDict = try container.decode([UUID: GraphEntity].self, forKey: .entitiesDict)
		relationships = try container.decode([GraphRelationship].self, forKey: .relationships)
		communities = try container.decode([Community].self, forKey: .communities)
		resourceId = try container.decode(UUID.self, forKey: .resourceId)
		
		// Decode chunkToEntities with Set<UUID>
		let chunkDict = try container.decode([String: [String]].self, forKey: .chunkToEntities)
		chunkToEntities = [:]
		for (key, value) in chunkDict {
			if let chunkIndex = Int(key) {
				chunkToEntities[chunkIndex] = Set(value.compactMap { UUID(uuidString: $0) })
			}
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(entitiesDict, forKey: .entitiesDict)
		try container.encode(relationships, forKey: .relationships)
		try container.encode(communities, forKey: .communities)
		try container.encode(resourceId, forKey: .resourceId)
		
		// Encode chunkToEntities
		var chunkDict: [String: [String]] = [:]
		for (key, value) in chunkToEntities {
			chunkDict[String(key)] = value.map { $0.uuidString }
		}
		try container.encode(chunkDict, forKey: .chunkToEntities)
	}
}

