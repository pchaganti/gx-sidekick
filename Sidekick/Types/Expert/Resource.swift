//
//  Resource.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import ExtractKit_macOS
import Foundation
import OSLog
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SwiftUI

/// An object that manages a single resource
public struct Resource: Identifiable, Codable, Hashable, Sendable {
    
    /// A `Logger` object for ``Resource`` objects
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Resource.self)
    )
    
    /// Initializes a resource from a `URL`
    /// - Parameter url: The url of the resource (could point to a website or an item in the file system)
    init(url: URL) {
        self.url = url
    }
    
    /// Stored property for `Identifiable` conformance
    public var id: UUID = UUID()
    
    /// The resource's url of type `URL`
    public var url: URL
    
    /// A  Boolean value that indicates if the resource is a web resource
    public var isWebResource: Bool {
        return self.url.isWebURL
    }
    
    /// An Array of type ``Resource`` containing the resource's child resources
    public var children: [Resource] = []
    
    /// A Boolean value that indicates if the resource is a leaf node
    public var isLeafNode: Bool {
        return !(!self.children.isEmpty || self.url.hasDirectoryPath)
    }
    
    /// The date of previous index of type `Date`
    public var prevIndexDate: Date = .distantPast
    
    /// A Boolean values indicating whether the resource was scanned since last modified
    public var scannedSinceLastModified: Bool {
        // Get last modified date
        guard let lastModified: Date = self.url.lastModified else {
            return false
        }
        // Return result
        return self.prevIndexDate > lastModified
    }
    
    /// The resource's name of type `String`
    public var name: String {
        // If website
        if self.url.isWebURL {
            return self.url.absoluteString
        } else {
            // If file or directory
            return self.url.lastPathComponent
        }
    }
    
    /// The resource's filename of type `String`
    public var filename: String {
        // If website
        if self.url.isWebURL {
            return self.url.host(percentEncoded: false)!
        } else {
            // If file or directory
            return self.url.lastPathComponent
        }
    }
    
    /// Progress update information emitted while indexing a resource
    public struct ProgressUpdate {
        public var current: Int
        public var total: Int
        public var stage: String
        public var entities: Int
        public var fractionComplete: Double
        
        public init(
            current: Int,
            total: Int,
            stage: String,
            entities: Int = 0,
            fractionComplete: Double
        ) {
            self.current = current
            self.total = total
            self.stage = stage
            self.entities = entities
            self.fractionComplete = fractionComplete
        }
    }
    
    /// Estimated number of work units required to index this resource (used for progress calculations)
    mutating func workloadEstimate(useGraphRAG: Bool) -> Int {
        // Web resources or files count as a single unit
        if !self.url.hasDirectoryPath {
            return 1
        }
        
        // Directories: ensure children list is populated
        self.updateChildrenList()
        
        if self.children.isEmpty {
            return 1
        }
        
        var totalUnits: Int = 0
        for index in self.children.indices {
            var child = self.children[index]
            let units = child.workloadEstimate(useGraphRAG: useGraphRAG)
            totalUnits += units
            self.children[index] = child
        }
        
        return max(1, totalUnits)
    }
    
    /// A Boolean value indicating if the file is still at its last recorded path
    public var wasMoved: Bool {
        return !url.fileExists
    }
    
    
    /// Function to get URL of index items JSON file's parent directory
    /// - Parameter url: The URL of the resources's index directory
    /// - Returns: The URL of the individual resource's index directory
    private func getIndexDirUrl(
        resourcesDirUrl url: URL
    ) -> URL {
        let url: URL = url.appendingPathComponent(
            id.uuidString
        )
        return url
    }
    
    
    /// Function to get URL of index items JSON file
    /// - Parameter url: The URL of the resources's index directory
    /// - Returns: The URL of the individual resource's index's JSON file
    private func getIndexUrl(resourcesDirUrl url: URL) -> URL {
        return self.getIndexDirUrl(
            resourcesDirUrl: url
        ).appendingPathComponent(
            "\(self.name).json"
        )
    }
    
    
    /// Function to create directory that houses the JSON file
    /// - Parameter url: The URL of the resources's index directory
    public func createDirectory(
        resourcesDirUrl url: URL
    ) {
        // Get directory url
        let dirUrl: URL = self.getIndexDirUrl(resourcesDirUrl: url)
        do {
            try FileManager.default.createDirectory(
                at: dirUrl,
                withIntermediateDirectories: true
            )
        } catch {
            Self.logger.error("Failed to create directory for resource at \"\(dirUrl, privacy: .public)\": \(error, privacy: .public)")
        }
    }
    
    
    /// Function to delete directory that houses the JSON file and its contents
    /// - Parameter url: The URL of the resources's index directory
    public func deleteDirectory(resourcesDirUrl url: URL) {
        let indexUrl: URL = getIndexUrl(resourcesDirUrl: url)
        let dirUrl: URL = url.appendingPathComponent(
            "\(id.uuidString)"
        )
        do {
            try FileManager.default.removeItem(at: indexUrl)
            try FileManager.default.removeItem(at: dirUrl)
        } catch {
            print("Failed to remove resource directory at \"\(self.url)\":", error)
        }
        // Indicate change
        print("Removed item at \"\(self.url)\" from index.")
    }
    
    /// Function that returns index items in JSON file
    /// - Parameter resourcesDirUrl: The URL of the resources's index directory
    /// - Returns: An array of type `SimilarityIndex.IndexItem` containing all indexed items
    public func getIndexItems(
        resourcesDirUrl: URL
    ) async -> [SimilarityIndex.IndexItem] {
        // If leaf node
        if self.isLeafNode {
            // Get index directory url
            let indexUrl: URL = self.getIndexDirUrl(
                resourcesDirUrl: resourcesDirUrl
            )
            let jsonUrl: URL = indexUrl.appendingPathComponent("\(self.filename).json")
            // Load index items
            do {
                // Load data
                let rawData: Data = try Data(contentsOf: jsonUrl)
                let decoder: JSONDecoder = JSONDecoder()
                let indexItems: [IndexItem] = try decoder.decode(
                    [IndexItem].self,
                    from: rawData
                )
                return indexItems
            } catch {
                return []
            }
        } else {
            // Else, scan all children
            var indexItems: [IndexItem] = []
            for child in self.children {
                indexItems += await child.getIndexItems(
                    resourcesDirUrl: resourcesDirUrl
                )
            }
            return indexItems
        }
    }
    
    /// Function that saves a similarity index
    /// - Parameters:
    ///   - resourcesDirUrl: The URL of the resources's index directory
    ///   - similarityIndex: The similarity index of indexed items of type ``SimilarityIndex``
    private func saveIndex(
        resourcesDirUrl: URL,
        similarityIndex: SimilarityIndex
    ) {
        do {
            let _ = try similarityIndex.saveIndex(
                toDirectory: self.getIndexDirUrl(
                    resourcesDirUrl: resourcesDirUrl
                ),
                name: self.filename
            )
        } catch {
            Self.logger.error("Error saving index for resource \(self.url, privacy: .public): \(error, privacy: .public)")
        }
    }
    
    /// Function that re-scans the file, then saves the updated similarity index
    /// - Parameters:
    ///   - resourcesDirUrl: The URL of the resources's index directory
    ///   - useGraphRAG: Whether to build and save a knowledge graph
    ///   - progressCallback: Optional callback for graph building progress
    @MainActor
    public mutating func updateIndex(
        resourcesDirUrl: URL,
        useGraphRAG: Bool = false,
        progressCallback: ((ProgressUpdate) -> Void)? = nil
    ) async -> Bool {
        // Log
        let url: URL = self.url
        Self.logger.info("Updating index for resource \"\(url, privacy: .public)\"")
        // Create directory if needed
        if !self.getIndexDirUrl(
            resourcesDirUrl: resourcesDirUrl
        ).fileExists {
            let loggerMsg: String = "Creating directory for resource \"\(self.url)\""
            Self.logger.info("\(loggerMsg, privacy: .public)")
            self.createDirectory(resourcesDirUrl: resourcesDirUrl)
        }
        Self.logger.info("No directory needed for resource \"\(url, privacy: .public)\"")
        // Handle preprocessing (directories, moved resources, cached scans)
        let preprocessResult = await self.preprocessIndexUpdate(
            resourcesDirUrl: resourcesDirUrl,
            useGraphRAG: useGraphRAG,
            progressCallback: progressCallback
        )
        
        switch preprocessResult {
            case .skip(let success):
                return success
            case .proceed:
                break
        }
        
        // Else, start index
        // Switch flag
        await MainActor.run {
            self.indexState.startIndex()
        }
        Self.logger.info("Starting index for resource \"\(url, privacy: .public)\"")
        // Extract text from url
        let text: String
        progressCallback?(ProgressUpdate(
            current: 0,
            total: 1,
            stage: String(localized: "Indexing \"\(self.name)\""),
            fractionComplete: 0.0
        ))
        do {
            text = try await ExtractKit.shared.extractText(
                url: self.url,
                speed: .fast
            )
            Self.logger.info("Extracted text from \"\(url, privacy: .public)\"")
        } catch {
            Self.logger.error("Failed to extract text from \"\(url, privacy: .public)\": \(error, privacy: .public)")
            return false  // Failed to extract text
        }
        // Split text
        let splitTexts: [String] = text.groupIntoChunks(
            maxChunkSize: 1024
        )
        Self.logger.info("Chunked text for resource \"\(url, privacy: .public)\"")
        // Init new similarity index
        let embeddings: DistilbertEmbeddings = DistilbertEmbeddings()
        let metric: DotProduct = DotProduct()
        let similarityIndex: SimilarityIndex = await SimilarityIndex(
            model: embeddings,
            metric: metric
        )
        Self.logger.info("Initialized index for resource \"\(url, privacy: .public)\"")
        // Add texts to index
        let idString = self.id.uuidString
        let urlStrValue = self.url.isWebURL ? self.url.absoluteString : self.url.posixPath
        for (index, splitText) in splitTexts.enumerated() {
            let indexItemId = "\(idString)_\(index)"
            await similarityIndex.addItem(
                id: indexItemId,
                text: splitText,
                metadata: [
                    "source": urlStrValue,
                    "itemIndex": "\(index)"
                ]
            )
        }
        Self.logger.info("Added items to index for resource \"\(url, privacy: .public)\"")
        // Save index
        self.saveIndex(
            resourcesDirUrl: resourcesDirUrl,
            similarityIndex: similarityIndex
        )
        Self.logger.info("Saved index for resource \"\(url, privacy: .public)\"")
        
        // Build and save knowledge graph if enabled
        var graphSuccess = true
        if useGraphRAG {
            Self.logger.notice("Graph RAG is enabled, starting graph build for resource \"\(url, privacy: .public)\"")
            let graphProgressWrapper: ((Int, Int, String, Int) -> Void)?
            if let progressCallback {
                graphProgressWrapper = { current, total, stage, entities in
                    progressCallback(ProgressUpdate(
                        current: current,
                        total: total,
                        stage: stage,
                        entities: entities,
                        fractionComplete: 0.0
                    ))
                }
            } else {
                graphProgressWrapper = nil
            }
            graphSuccess = await self.buildAndSaveGraph(
                chunks: splitTexts,
                resourcesDirUrl: resourcesDirUrl,
                progressCallback: graphProgressWrapper
            )
            
            if graphSuccess {
                Self.logger.notice("Graph build succeeded for resource \"\(url, privacy: .public)\"")
            } else {
                Self.logger.error("Graph build failed for resource \"\(url, privacy: .public)\"")
            }
        } else {
            Self.logger.info("Graph RAG is disabled, skipping graph build for resource \"\(url, privacy: .public)\"")
        }
        
        // Switch flag
        await MainActor.run {
            self.indexState.finishIndex()
        }
        // Show file updated
        let loggerMsg: String = "Updated index for item \"\(self.url)\""
        Self.logger.notice("\(loggerMsg, privacy: .public)")
        
        progressCallback?(ProgressUpdate(
            current: 1,
            total: 1,
            stage: String(localized: "Completed indexing \"\(self.name)\""),
            fractionComplete: 1.0
        ))
        
        return graphSuccess
    }
    
    /// Preprocess update to handle directories, moved files, and cached resources
    @MainActor
    private mutating func preprocessIndexUpdate(
        resourcesDirUrl: URL,
        useGraphRAG: Bool,
        progressCallback: ((ProgressUpdate) -> Void)?
    ) async -> PreprocessResult {
        // Exit update if file resource was moved
        if !self.isWebResource && self.wasMoved {
            let resourceUrl: URL = self.url
            Self.logger.notice("Resource was moved, deleting index for \"\(resourceUrl, privacy: .public)\"")
            self.deleteDirectory(resourcesDirUrl: resourcesDirUrl)
            return .skip(success: true)
        }
        
        // Handle directory resources by delegating to children
        if !self.isLeafNode {
            let resourceUrl: URL = self.url
            Self.logger.info("Updating child resources for directory \"\(resourceUrl, privacy: .public)\"")
            self.updateChildrenList()
            var allChildrenSucceeded = true
            let childCount = max(self.children.count, 1)
            
            var childWorkUnits: [Int] = []
            childWorkUnits.reserveCapacity(childCount)
            for index in self.children.indices {
                var childCopy = self.children[index]
                let units = childCopy.workloadEstimate(useGraphRAG: useGraphRAG)
                childWorkUnits.append(units)
                self.children[index] = childCopy
            }
            let totalUnits = max(childWorkUnits.reduce(0, +), 1)
            var completedUnits: Double = 0
            
            for index in self.children.indices {
                let childUnits = Double(childWorkUnits[index])
                
                progressCallback?(ProgressUpdate(
                    current: index,
                    total: childCount,
                    stage: String(localized: "Processing item \(index + 1) of \(childCount) in \"\(self.name)\""),
                    fractionComplete: completedUnits / Double(totalUnits)
                ))
                
                var child = self.children[index]
                let childSuccess = await child.updateIndex(
                    resourcesDirUrl: resourcesDirUrl,
                    useGraphRAG: useGraphRAG,
                    progressCallback: { update in
                        let fraction = (
                            completedUnits + (childUnits * max(0.0, min(update.fractionComplete, 1.0)))
                        ) / Double(totalUnits)
                        progressCallback?(ProgressUpdate(
                            current: update.current,
                            total: update.total,
                            stage: update.stage,
                            entities: update.entities,
                            fractionComplete: fraction
                        ))
                    }
                )
                self.children[index] = child
                
                completedUnits += childUnits
                
                progressCallback?(ProgressUpdate(
                    current: index + 1,
                    total: childCount,
                    stage: String(localized: "Finished item \(index + 1) of \(childCount) in \"\(self.name)\""),
                    fractionComplete: completedUnits / Double(totalUnits)
                ))
                
                if !childSuccess {
                    allChildrenSucceeded = false
                }
            }
            
            self.prevIndexDate = .now
            
            if useGraphRAG {
                progressCallback?(ProgressUpdate(
                    current: childCount,
                    total: childCount,
                    stage: String(localized: "Finished processing \"\(self.name)\""),
                    fractionComplete: 1.0
                ))
            }
            
            return .skip(success: allChildrenSucceeded)
        }
        
        // Exit update if the resource was recently scanned
        if self.scannedSinceLastModified {
            let resourceUrl: URL = self.url
            Self.logger.notice("Skipping update for recently scanned resource \"\(resourceUrl, privacy: .public)\"")
            return .skip(success: true)
        }
        
        return .proceed
    }
    
    private enum PreprocessResult {
        case proceed
        case skip(success: Bool)
    }
    
    /// Function to update the list of children of a resource
    private mutating func updateChildrenList() {
        // If resource is directory
        if self.url.hasDirectoryPath {
            // Loop through files in current directory level
            let files: [URL] = self.url.getContentsOneLevelDeep() ?? []
            for file in files {
                // If missing, add to children
                if !self.children.map({
                    $0.url
                }).contains(file) {
                    self.children
                        .append(
                            Resource(
                                url: file
                            )
                        )
                }
            }
        }
    }
    
    /// The current indexing state, used to prevent duplicate indexes
    public var indexState: IndexState = .noIndex
    
    /// Enum of all possible index states
    public enum IndexState: CaseIterable, Codable, Sendable {
        
        case noIndex, indexing, indexed // New index item always starts with IndexState of .noIndex
        
        /// Function to indicate that indexing is in progress
        mutating func startIndex() {
            self = .indexing
        }
        
        /// Function to indicate that indexing has finished
        mutating func finishIndex() {
            self = .indexed
        }
        
    }
    
    // MARK: - Graph RAG Methods
    
    /// Build and save a knowledge graph for this resource
    /// - Parameters:
    ///   - chunks: The text chunks
    ///   - resourcesDirUrl: The URL of the resources's index directory
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: True if successful, false if failed
    private func buildAndSaveGraph(
        chunks: [String],
        resourcesDirUrl: URL,
        progressCallback: ((Int, Int, String, Int) -> Void)?
    ) async -> Bool {
        Self.logger.notice("Building knowledge graph for resource \"\(self.url, privacy: .public)\" with \(chunks.count) chunks")
        
        guard !chunks.isEmpty else {
            Self.logger.warning("No chunks available for graph building")
            return false
        }
        
        do {
            // Extract entities and relationships
            let extractionResult = try await EntityExtractor.extractEntitiesAndRelationships(
                from: chunks,
                progressCallback: progressCallback
            )
            
            Self.logger.info("Extracted \(extractionResult.entities.count) entities and \(extractionResult.relationships.count) relationships")
            
            // Create knowledge graph
            let graph = KnowledgeGraph(resourceId: self.id)
            
            // Convert EntityData to GraphEntity
            var entityMapping: [String: UUID] = [:]  // name -> id
            for entityData in extractionResult.entities {
                let entity = GraphEntity(
                    name: entityData.name,
                    type: entityData.type,
                    description: entityData.description,
                    sourceChunks: entityData.sourceChunks,
                    embedding: nil  // Will be generated by CommunityDetector if needed
                )
                graph.addEntity(entity)
                entityMapping[entityData.name.lowercased()] = entity.id
            }
            
            // Convert RelationshipData to GraphRelationship
            for relationshipData in extractionResult.relationships {
                guard let sourceId = entityMapping[relationshipData.sourceEntity.lowercased()],
                      let targetId = entityMapping[relationshipData.targetEntity.lowercased()] else {
                    continue
                }
                
                let relationship = GraphRelationship(
                    sourceEntityId: sourceId,
                    targetEntityId: targetId,
                    relationshipType: relationshipData.relationshipType,
                    description: relationshipData.description,
                    strength: 1.0,
                    sourceChunks: relationshipData.sourceChunks
                )
                graph.addRelationship(relationship)
            }
            
            // Detect communities
            let communities = try await CommunityDetector.detectCommunities(
                in: graph,
                progressCallback: { current, total, stage in
                    progressCallback?(current, total, stage, graph.entityCount)
                }
            )
            
            graph.addCommunities(communities)
            
            Self.logger.info("Detected \(communities.count) communities")
            
            // Save graph to database
            let dbPath = getGraphDatabasePath(resourcesDirUrl: resourcesDirUrl)
            let database = try GraphDatabase(dbPath: dbPath)
            try database.saveGraph(graph)
            
            Self.logger.notice("Successfully saved knowledge graph for resource \"\(self.url, privacy: .public)\"")
            return true
            
        } catch {
            Self.logger.error("Failed to build/save knowledge graph: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    /// Get the path to the graph database for this resource
    /// - Parameter resourcesDirUrl: The URL of the resources's index directory
    /// - Returns: Path to the SQLite database
    private func getGraphDatabasePath(resourcesDirUrl: URL) -> String {
        return resourcesDirUrl.appendingPathComponent("graph.sqlite").path
    }
    
}
