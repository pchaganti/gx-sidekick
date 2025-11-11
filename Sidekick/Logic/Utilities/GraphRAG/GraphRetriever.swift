//
//  GraphRetriever.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import OSLog
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

/// Retrieves relevant information from a knowledge graph using multi-stage strategy
public class GraphRetriever {
    
    /// A `Logger` object for ``GraphRetriever``
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: GraphRetriever.self)
    )
    
    /// Enhanced search result combining vector and graph information
    public struct EnhancedResult {
        public var text: String
        public var score: Float
        public var source: String
        public var entityContext: [String]  // Names of related entities
        public var communitySummary: String?  // Relevant community summary
    }
    
    /// Retrieve relevant information using graph-enhanced RAG
    /// - Parameters:
    ///   - query: The search query
    ///   - vectorResults: Initial vector search results
    ///   - graph: The knowledge graph
    ///   - maxResults: Maximum number of results to return
    /// - Returns: Array of enhanced results
    public static func retrieve(
        query: String,
        vectorResults: [SearchResult],
        graph: KnowledgeGraph,
        maxResults: Int = 5
    ) async -> [EnhancedResult] {
        var enhancedResults: [EnhancedResult] = []
        
        Self.logger.info("Starting graph-enhanced retrieval with \(vectorResults.count) initial results")
        
        // Stage 1: Process vector results and expand with graph context
        var chunkIndices = Set<Int>()
        for result in vectorResults {
            if let chunkIndex = result.itemIndex {
                chunkIndices.insert(chunkIndex)
            }
        }
        Self.logger.debug("Initial chunk indices from vector search: \(chunkIndices.sorted())")
        
        // Stage 2: Get entities from relevant chunks
        let relevantEntities = graph.getEntities(inChunks: Array(chunkIndices))
        Self.logger.info("Found \(relevantEntities.count) entities in relevant chunks")
        
        // Stage 3: Expand to related entities via graph traversal
        var expandedEntityIds = Set(relevantEntities.map { $0.id })
        for entity in relevantEntities {
            let relatedEntities = graph.getRelatedEntities(for: entity.id)
            if !relatedEntities.isEmpty {
                let relatedNames = relatedEntities.map { $0.name }.joined(separator: ", ")
                Self.logger.debug("Traversing from entity \"\(entity.name, privacy: .public)\" to related entities: \(relatedNames, privacy: .public)")
            } else {
                Self.logger.debug("Entity \"\(entity.name, privacy: .public)\" has no related entities")
            }
            for related in relatedEntities {
                expandedEntityIds.insert(related.id)
            }
        }
        
        let expandedEntities = Array(expandedEntityIds).compactMap { graph.findEntity(id: $0) }
        Self.logger.info("Expanded to \(expandedEntities.count) entities via relationships")
        
        // Stage 4: Get additional chunks from expanded entities
        var expandedChunkIndices = chunkIndices
        for entity in expandedEntities {
            expandedChunkIndices.formUnion(entity.sourceChunks)
            if !entity.sourceChunks.isEmpty {
                Self.logger.debug("Entity \"\(entity.name, privacy: .public)\" contributes chunks \(entity.sourceChunks.sorted())")
            }
        }
        
        Self.logger.info("Expanded to \(expandedChunkIndices.count) total chunks")
        
        // Stage 5: Find relevant community summaries
        let relevantCommunities = findRelevantCommunities(
            entities: expandedEntities,
            graph: graph,
            query: query
        )
        
        // Stage 6: Build enhanced results
        for result in vectorResults.prefix(maxResults) {
            guard let chunkIndex = result.itemIndex else { continue }
            
            Self.logger.debug("Constructing enhanced result for chunk \(chunkIndex)")
            
            // Get entities in this chunk
            let chunkEntities = graph.getEntities(inChunk: chunkIndex)
            let entityNames = chunkEntities.map { $0.name }
            if !entityNames.isEmpty {
                let entityList = entityNames.joined(separator: ", ")
                Self.logger.debug("Chunk \(chunkIndex) entities: \(entityList, privacy: .public)")
            }
            
            // Find most relevant community for this chunk
            let relevantCommunity = relevantCommunities.first { community in
                let communityEntityIds = Set(community.memberEntityIds)
                return chunkEntities.contains { communityEntityIds.contains($0.id) }
            }
            if let community = relevantCommunity {
                Self.logger.debug("Chunk \(chunkIndex) aligned with community level \(community.level)")
            }
            
            let enhanced = EnhancedResult(
                text: result.text,
                score: result.score,
                source: result.sourceUrlText ?? "Unknown",
                entityContext: entityNames,
                communitySummary: relevantCommunity?.summary
            )
            
            enhancedResults.append(enhanced)
        }
        
        // Stage 7: Add results from expanded entities (up to maxResults)
        if enhancedResults.count < maxResults {
            let additionalChunks = expandedChunkIndices.subtracting(chunkIndices)
            let additionalResults = await getResultsForChunks(
                Array(additionalChunks).prefix(maxResults - enhancedResults.count),
                graph: graph,
                query: query,
                communities: relevantCommunities
            )
            if !additionalResults.isEmpty {
                Self.logger.debug("Adding \(additionalResults.count) results from expanded chunks: \(additionalChunks.sorted())")
            }
            enhancedResults.append(contentsOf: additionalResults)
        }
        
        // Stage 8: Rank results by combining vector similarity and graph connectivity
        let rankedResults = rankResults(enhancedResults)
        
        Self.logger.notice("Returning \(rankedResults.count) graph-enhanced results")
        
        return Array(rankedResults.prefix(maxResults))
    }
    
    /// Find communities relevant to the query and entities
    private static func findRelevantCommunities(
        entities: [GraphEntity],
        graph: KnowledgeGraph,
        query: String
    ) -> [Community] {
        let entityIds = Set(entities.map { $0.id })
        
        // Find communities that contain these entities
        var relevantCommunities = graph.communities.filter { community in
            let communityEntityIds = Set(community.memberEntityIds)
            return !communityEntityIds.intersection(entityIds).isEmpty
        }
        
        // Sort by level (prefer higher-level for broader context)
        relevantCommunities.sort { $0.level > $1.level }
        
        // If we have community embeddings, rank by similarity to query
        Task {
            if let queryEmbedding = await generateEmbedding(for: query) {
                relevantCommunities = relevantCommunities.compactMap { community in
                    guard let communityEmbedding = community.embedding else {
                        return (community, 0.0)
                    }
                    let similarity = cosineSimilarity(
                        queryEmbedding,
                        communityEmbedding
                    )
                    return (community, Double(similarity))
                }
                .sorted { $0.1 > $1.1 }  // Sort by similarity descending
                .map { $0.0 }
            }
        }
        
        return Array(relevantCommunities.prefix(3))  // Top 3 communities
    }
    
    /// Get results for additional chunk indices
    private static func getResultsForChunks(
        _ chunkIndices: ArraySlice<Int>,
        graph: KnowledgeGraph,
        query: String,
        communities: [Community]
    ) async -> [EnhancedResult] {
        var results: [EnhancedResult] = []
        
        for chunkIndex in chunkIndices {
            let chunkEntities = graph.getEntities(inChunk: chunkIndex)
            let entityNames = chunkEntities.map { $0.name }
            
            // Find relevant community
            let relevantCommunity = communities.first { community in
                let communityEntityIds = Set(community.memberEntityIds)
                return chunkEntities.contains { communityEntityIds.contains($0.id) }
            }
            
            // Get chunk text (placeholder - would need to be passed from vector index)
            let text = chunkEntities.map { "\($0.name): \($0.description)" }
                .joined(separator: "; ")
            
            if !text.isEmpty {
                results.append(EnhancedResult(
                    text: text,
                    score: 0.5,  // Default score for expanded results
                    source: "Graph expansion",
                    entityContext: entityNames,
                    communitySummary: relevantCommunity?.summary
                ))
            }
        }
        
        return results
    }
    
    /// Rank results by combining multiple signals
    private static func rankResults(_ results: [EnhancedResult]) -> [EnhancedResult] {
        return results.sorted { result1, result2 in
            // Primary: vector similarity score
            var score1 = result1.score
            var score2 = result2.score
            
            // Boost score if has entity context
            if !result1.entityContext.isEmpty {
                score1 += 0.1
            }
            if !result2.entityContext.isEmpty {
                score2 += 0.1
            }
            
            // Boost score if has community summary
            if result1.communitySummary != nil {
                score1 += 0.05
            }
            if result2.communitySummary != nil {
                score2 += 0.05
            }
            
            return score1 > score2
        }
    }
    
    /// Generate embedding for text
    private static func generateEmbedding(for text: String) async -> [Float]? {
        let embeddings = DistilbertEmbeddings()
        return await embeddings.encode(sentence: text)
    }
    
    /// Calculate cosine similarity between two vectors
    private static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var magnitudeA: Float = 0.0
        var magnitudeB: Float = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }
        
        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        return magnitude > 0 ? dotProduct / magnitude : 0.0
    }
}

