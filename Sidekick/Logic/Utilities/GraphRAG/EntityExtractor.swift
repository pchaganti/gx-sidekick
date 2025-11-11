//
//  EntityExtractor.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import OSLog

/// Extracts entities and relationships from text using the worker model
public class EntityExtractor {
	
	/// A `Logger` object for ``EntityExtractor``
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: EntityExtractor.self)
	)
	
	/// Progress callback type
	public typealias ProgressCallback = @Sendable (Int, Int, String, Int) -> Void
	
	/// Result from entity extraction
	public struct ExtractionResult {
		public var entities: [EntityData]
		public var relationships: [RelationshipData]
	}
	
	/// Intermediate entity data
	public struct EntityData: Codable {
		public var name: String
		public var type: String
		public var description: String
		public var sourceChunks: [Int]
	}
	
	/// Intermediate relationship data
	public struct RelationshipData: Codable {
		public var sourceEntity: String
		public var targetEntity: String
		public var relationshipType: String
		public var description: String
		public var sourceChunks: [Int]
	}
	
	/// JSON structure for LLM response
	private struct LLMResponse: Codable {
		var entities: [LLMEntity]?
		var relationships: [LLMRelationship]?
	}
	
	private struct LLMEntity: Codable {
		var name: String
		var type: String
		var description: String
	}
	
	private struct LLMRelationship: Codable {
		var source: String
		var target: String
		var type: String
		var description: String
	}
	
	/// Extract entities and relationships from text chunks
	/// - Parameters:
	///   - chunks: Array of text chunks
	///   - batchSize: Number of chunks to process at once (default: 15)
	///   - progressCallback: Optional callback for progress updates
	/// - Returns: Extraction result with entities and relationships
	public static func extractEntitiesAndRelationships(
		from chunks: [String],
		batchSize: Int = 15,
		progressCallback: ProgressCallback? = nil
	) async throws -> ExtractionResult {
		var allEntities: [EntityData] = []
		var allRelationships: [RelationshipData] = []
		
		let totalChunks = chunks.count
		let batches = stride(from: 0, to: totalChunks, by: batchSize).map {
			Array(chunks[$0..<min($0 + batchSize, totalChunks)])
		}
		
		for (batchIndex, batch) in batches.enumerated() {
			let chunkStartIndex = batchIndex * batchSize
			
			// Update progress
			progressCallback?(
				batchIndex + 1,
				batches.count,
				"Extracting entities (batch \(batchIndex + 1)/\(batches.count))",
				allEntities.count
			)
			
			// Process batch
			do {
				let result = try await extractFromBatch(
					batch: batch,
					startIndex: chunkStartIndex
				)
				allEntities.append(contentsOf: result.entities)
				allRelationships.append(contentsOf: result.relationships)
				
				Self.logger.info("Extracted \(result.entities.count) entities and \(result.relationships.count) relationships from batch \(batchIndex + 1)")
			} catch {
				Self.logger.error("Failed to extract from batch \(batchIndex + 1): \(error.localizedDescription)")
				// Continue processing other batches
				continue
			}
		}
		
		// Merge duplicate entities
		let mergedEntities = mergeDuplicateEntities(allEntities)
		let mergedRelationships = deduplicateRelationships(allRelationships)
		
		Self.logger.notice("Total extracted: \(mergedEntities.count) entities, \(mergedRelationships.count) relationships")
		
		return ExtractionResult(
			entities: mergedEntities,
			relationships: mergedRelationships
		)
	}
	
	/// Extract entities from a batch of chunks
	private static func extractFromBatch(
		batch: [String],
		startIndex: Int
	) async throws -> ExtractionResult {
		// Combine batch into single text
		let combinedText = batch.enumerated().map { index, chunk in
			"[Chunk \(startIndex + index)]:\n\(chunk)"
		}.joined(separator: "\n\n")
		
		// Create prompt
		let systemPrompt = """
You are an expert at extracting entities and relationships from text. Extract key entities (people, organizations, concepts, locations, events, etc.) and their relationships.

Return ONLY a valid JSON object with this exact structure:
{
  "entities": [
    {
      "name": "Entity name",
      "type": "Entity type (e.g., Person, Organization, Concept, Location, Event)",
      "description": "Brief description of the entity"
    }
  ],
  "relationships": [
    {
      "source": "Source entity name",
      "target": "Target entity name",
      "type": "Relationship type (e.g., works_at, located_in, related_to, part_of)",
      "description": "Description of the relationship"
    }
  ]
}

Focus on:
- Important entities mentioned in the text
- Clear relationships between entities
- Use consistent entity names
- Keep descriptions concise
"""
		
		let userPrompt = """
Extract entities and relationships from the following text:

\(combinedText)
"""
		
		// Create messages
		let systemMessage = Message(text: systemPrompt, sender: .system)
		let userMessage = Message(text: userPrompt, sender: .user)
		
		// Get response from worker model
		var responseText = ""
		let response = try await Model.shared.listenThinkRespond(
			messages: [systemMessage, userMessage],
			modelType: .worker,
			mode: .default,
			handleResponseUpdate: { _, _ in },
			handleResponseFinish: { fullMessage, _, _ in
				responseText = fullMessage
			}
		)
		
		responseText = response.text
		
		// Parse JSON response
		let llmResponse = try parseJSONResponse(responseText)
		
		// Convert to EntityData and RelationshipData
		var entities: [EntityData] = []
		var relationships: [RelationshipData] = []
		
		for llmEntity in llmResponse.entities ?? [] {
			// Determine which chunks mention this entity
			let sourceChunks = batch.enumerated().compactMap { index, chunk in
				chunk.localizedCaseInsensitiveContains(llmEntity.name) ? startIndex + index : nil
			}
			
			entities.append(EntityData(
				name: llmEntity.name,
				type: llmEntity.type,
				description: llmEntity.description,
				sourceChunks: sourceChunks
			))
		}
		
		for llmRel in llmResponse.relationships ?? [] {
			// Determine which chunks mention this relationship
			let sourceChunks = batch.enumerated().compactMap { index, chunk in
				(chunk.localizedCaseInsensitiveContains(llmRel.source) &&
				 chunk.localizedCaseInsensitiveContains(llmRel.target)) ? startIndex + index : nil
			}
			
			relationships.append(RelationshipData(
				sourceEntity: llmRel.source,
				targetEntity: llmRel.target,
				relationshipType: llmRel.type,
				description: llmRel.description,
				sourceChunks: sourceChunks
			))
		}
		
		return ExtractionResult(entities: entities, relationships: relationships)
	}
	
	/// Parse JSON response from LLM
	private static func parseJSONResponse(_ text: String) throws -> LLMResponse {
		// Try to extract JSON from markdown code blocks if present
		var jsonText = text
		
		if let jsonRange = text.range(of: "```json", options: .caseInsensitive) {
			let startIndex = text.index(jsonRange.upperBound, offsetBy: 1)
			if let endRange = text.range(of: "```", range: startIndex..<text.endIndex) {
				jsonText = String(text[startIndex..<endRange.lowerBound])
			}
		} else if let jsonRange = text.range(of: "```") {
			let startIndex = text.index(jsonRange.upperBound, offsetBy: 1)
			if let endRange = text.range(of: "```", range: startIndex..<text.endIndex) {
				jsonText = String(text[startIndex..<endRange.lowerBound])
			}
		}
		
		// Find JSON object boundaries
		if let startBrace = jsonText.firstIndex(of: "{"),
		   let endBrace = jsonText.lastIndex(of: "}") {
			jsonText = String(jsonText[startBrace...endBrace])
		}
		
		let decoder = JSONDecoder()
		guard let data = jsonText.data(using: .utf8) else {
			throw ExtractionError.invalidJSON("Failed to convert text to data")
		}
		
		do {
			return try decoder.decode(LLMResponse.self, from: data)
		} catch {
			Self.logger.error("Failed to parse JSON: \(error.localizedDescription)")
			Self.logger.error("JSON text was: \(jsonText)")
			throw ExtractionError.invalidJSON("Failed to decode JSON: \(error.localizedDescription)")
		}
	}
	
	/// Merge duplicate entities with the same name
	private static func mergeDuplicateEntities(_ entities: [EntityData]) -> [EntityData] {
		var entityDict: [String: EntityData] = [:]
		
		for entity in entities {
			let key = entity.name.lowercased()
			if var existing = entityDict[key] {
				// Merge source chunks
				existing.sourceChunks = Array(Set(existing.sourceChunks + entity.sourceChunks))
				// Use longer description
				if entity.description.count > existing.description.count {
					existing.description = entity.description
				}
				entityDict[key] = existing
			} else {
				entityDict[key] = entity
			}
		}
		
		return Array(entityDict.values)
	}
	
	/// Remove duplicate relationships
	private static func deduplicateRelationships(_ relationships: [RelationshipData]) -> [RelationshipData] {
		var seen: Set<String> = []
		var unique: [RelationshipData] = []
		
		for rel in relationships {
			let key = "\(rel.sourceEntity.lowercased())_\(rel.targetEntity.lowercased())_\(rel.relationshipType.lowercased())"
			if !seen.contains(key) {
				seen.insert(key)
				unique.append(rel)
			}
		}
		
		return unique
	}
	
	/// Error types
	public enum ExtractionError: Error {
		case invalidJSON(String)
		case extractionFailed(String)
	}
}

