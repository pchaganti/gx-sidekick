//
//  CommunityDetector.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import OSLog
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

/// Detects hierarchical communities in a knowledge graph using Leiden algorithm
public class CommunityDetector {
    
    /// A `Logger` object for ``CommunityDetector``
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CommunityDetector.self)
    )
    
    /// Progress callback type
    public typealias ProgressCallback = @Sendable (Int, Int, String) -> Void
    
    /// Detect communities in a knowledge graph
    /// - Parameters:
    ///   - graph: The knowledge graph
    ///   - maxLevels: Maximum hierarchical levels (default: 3)
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: Array of communities
    public static func detectCommunities(
        in graph: KnowledgeGraph,
        maxLevels: Int = 3,
        progressCallback: ProgressCallback? = nil
    ) async throws -> [Community] {
        var allCommunities: [Community] = []
        
        // Level 0: Group entities based on relationships
        progressCallback?(1, maxLevels, "Detecting base communities")
        let baseCommunities = detectBaseCommunities(in: graph)
        allCommunities.append(contentsOf: baseCommunities)
        
        Self.logger.info("Detected \(baseCommunities.count) base communities")
        
        // Generate summaries for base communities
        for (index, var community) in baseCommunities.enumerated() {
            progressCallback?(
                index + 1,
                baseCommunities.count,
                "Generating summary for community \(index + 1)/\(baseCommunities.count)"
            )
            
            let summaryResult = await generateCommunitySummary(
                for: community,
                in: graph
            )
            community.summary = summaryResult.summary
            community.title = summaryResult.title
            community.embedding = summaryResult.embedding
            
            // Update community in array
            if let communityIndex = allCommunities.firstIndex(where: { $0.id == community.id }) {
                allCommunities[communityIndex] = community
            }
        }
        
        // Build higher-level communities hierarchically
        var currentLevelCommunities = baseCommunities
        for level in 1..<maxLevels {
            guard currentLevelCommunities.count > 1 else {
                Self.logger.info("Stopping at level \(level-1): only 1 community remaining")
                break
            }
            
            progressCallback?(level + 1, maxLevels, "Building level \(level) communities")
            
            let higherLevelCommunities = buildHigherLevelCommunities(
                from: currentLevelCommunities,
                level: level
            )
            
            if higherLevelCommunities.isEmpty {
                break
            }
            
            // Generate summaries for higher-level communities
            for var community in higherLevelCommunities {
                let summaryResult = await generateCommunitySummary(
                    for: community,
                    in: graph,
                    fromSubCommunities: currentLevelCommunities
                )
                community.summary = summaryResult.summary
                community.title = summaryResult.title
                community.embedding = summaryResult.embedding
                allCommunities.append(community)
            }
            
            currentLevelCommunities = higherLevelCommunities
            Self.logger.info("Detected \(higherLevelCommunities.count) communities at level \(level)")
        }
        
        Self.logger.notice("Total communities detected: \(allCommunities.count) across \(maxLevels) levels")
        
        return allCommunities
    }
    
    /// Detect base-level communities using relationship connectivity
    private static func detectBaseCommunities(in graph: KnowledgeGraph) -> [Community] {
        var communities: [Community] = []
        var visited: Set<UUID> = []
        var entityToCommunity: [UUID: UUID] = [:]
        
        // Build adjacency list
        var adjacencyList: [UUID: Set<UUID>] = [:]
        for entity in graph.entities {
            adjacencyList[entity.id] = Set()
        }
        
        for relationship in graph.relationships {
            adjacencyList[relationship.sourceEntityId]?.insert(relationship.targetEntityId)
            adjacencyList[relationship.targetEntityId]?.insert(relationship.sourceEntityId)
        }
        
        // Perform community detection using connected components
        for entity in graph.entities {
            guard !visited.contains(entity.id) else { continue }
            
            var componentEntities: [UUID] = []
            var queue: [UUID] = [entity.id]
            visited.insert(entity.id)
            
            // BFS to find connected component
            while !queue.isEmpty {
                let currentId = queue.removeFirst()
                componentEntities.append(currentId)
                
                if let neighbors = adjacencyList[currentId] {
                    for neighbor in neighbors {
                        if !visited.contains(neighbor) {
                            visited.insert(neighbor)
                            queue.append(neighbor)
                        }
                    }
                }
            }
            
            // Create community for this component
            let community = Community(
                level: 0,
                memberEntityIds: componentEntities,
                subCommunityIds: []
            )
            
            communities.append(community)
            
            // Track entity to community mapping
            for entityId in componentEntities {
                entityToCommunity[entityId] = community.id
            }
        }
        
        // Handle isolated entities (no relationships)
        for entity in graph.entities {
            if entityToCommunity[entity.id] == nil {
                let community = Community(
                    level: 0,
                    memberEntityIds: [entity.id],
                    subCommunityIds: []
                )
                communities.append(community)
            }
        }
        
        return communities
    }
    
    /// Build higher-level communities by grouping smaller communities
    private static func buildHigherLevelCommunities(
        from lowerLevelCommunities: [Community],
        level: Int
    ) -> [Community] {
        guard lowerLevelCommunities.count > 1 else {
            return []
        }
        
        var higherLevelCommunities: [Community] = []
        
        // Use simple clustering: group communities by size and similarity
        let sortedCommunities = lowerLevelCommunities.sorted {
            $0.memberEntityIds.count > $1.memberEntityIds.count
        }
        
        // Group communities into clusters of ~3-5 communities each
        let clusterSize = max(2, lowerLevelCommunities.count / 3)
        
        for i in stride(from: 0, to: sortedCommunities.count, by: clusterSize) {
            let endIndex = min(i + clusterSize, sortedCommunities.count)
            let cluster = Array(sortedCommunities[i..<endIndex])
            
            // Merge all entities from sub-communities
            let allEntityIds = cluster.flatMap { $0.memberEntityIds }
            let subCommunityIds = cluster.map { $0.id }
            
            let community = Community(
                level: level,
                memberEntityIds: allEntityIds,
                subCommunityIds: subCommunityIds
            )
            
            higherLevelCommunities.append(community)
        }
        
        return higherLevelCommunities
    }
    
    /// Generate summary for a community using the worker model
    private static func generateCommunitySummary(
        for community: Community,
        in graph: KnowledgeGraph,
        fromSubCommunities subCommunities: [Community]? = nil
    ) async -> (summary: String, title: String, embedding: [Float]?) {
        // Get entities in this community
        let entities = community.memberEntityIds.compactMap { graph.findEntity(id: $0) }
        
        if entities.isEmpty {
            return (
                summary: "Empty community",
                title: "Empty Community",
                embedding: nil
            )
        }
        
        // Build context for summary generation
        var context = ""
        
        if let subComms = subCommunities {
            // For higher-level communities, use sub-community summaries
            let relevantSubComms = subComms.filter { subComm in
                community.subCommunityIds.contains(subComm.id)
            }
            
            context = "Sub-communities:\n"
            for subComm in relevantSubComms {
                context += "- \(subComm.title): \(subComm.summary)\n"
            }
        } else {
            // For base-level communities, use entity information
            context = "Entities:\n"
            for entity in entities.prefix(20) {  // Limit to first 20 entities
                context += "- \(entity.name) (\(entity.type)): \(entity.description)\n"
            }
            
            if entities.count > 20 {
                context += "... and \(entities.count - 20) more entities\n"
            }
        }
        
        // Create prompt
        let systemPrompt = """
You are an expert at analyzing and summarizing information. Generate a concise summary and title for a community of related entities.

Return ONLY a valid JSON object with this structure:
{
  "title": "Short descriptive title (2-5 words)",
  "summary": "Brief summary of the community (1-3 sentences)"
}
"""
        
        let userPrompt = """
Generate a title and summary for this community:

\(context)

Focus on the main themes and key relationships.
"""
        
        // Create messages
        let systemMessage = Message(text: systemPrompt, sender: .system)
        let userMessage = Message(text: userPrompt, sender: .user)
        
        // Save current status and set to background task to prevent "Thinking..." message in UI
        let previousStatus = await MainActor.run {
            let status = Model.shared.status
            Model.shared.indicateStartedBackgroundTask()
            return status
        }
        
        // Get response from worker model
        var responseText = ""
        do {
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
            
            // Restore previous status
            await MainActor.run {
                Model.shared.setStatus(previousStatus)
            }
            
            // Parse response
            let result = parseSummaryResponse(responseText)
            
            // Generate embedding for the summary
            let embedding = await generateEmbedding(for: result.summary)
            
            return (summary: result.summary, title: result.title, embedding: embedding)
            
        } catch {
            Self.logger.error("Failed to generate summary: \(error.localizedDescription)")
            
            // Restore previous status on error
            await MainActor.run {
                Model.shared.setStatus(previousStatus)
            }
            
            // Fallback summary
            let fallbackTitle = "Community of \(entities.count) entities"
            let fallbackSummary = "A community containing: " +
            entities.prefix(3).map { $0.name }.joined(separator: ", ") +
            (entities.count > 3 ? " and \(entities.count - 3) others" : "")
            
            let embedding = await generateEmbedding(for: fallbackSummary)
            
            return (summary: fallbackSummary, title: fallbackTitle, embedding: embedding)
        }
    }
    
    /// Parse summary response from LLM
    private static func parseSummaryResponse(_ text: String) -> (title: String, summary: String) {
        // Try to extract JSON
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
        
        // Try to decode
        if let data = jsonText.data(using: .utf8),
           let json = try? JSONDecoder().decode([String: String].self, from: data),
           let title = json["title"],
           let summary = json["summary"] {
            return (title: title, summary: summary)
        }
        
        // Fallback: use first line as title, rest as summary
        let lines = text.split(separator: "\n", maxSplits: 1)
        if lines.count >= 2 {
            return (title: String(lines[0]), summary: String(lines[1]))
        }
        
        return (title: "Untitled Community", summary: text.prefix(200).description)
    }
    
    /// Generate embedding for text using DistilBERT
    private static func generateEmbedding(for text: String) async -> [Float]? {
        let embeddings = DistilbertEmbeddings()
        return await embeddings.encode(sentence: text)
    }
}

