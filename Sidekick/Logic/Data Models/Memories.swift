//
//  Memories.swift
//  Sidekick
//
//  Created by John Bean on 4/22/25.
//

import Foundation
import OSLog
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SwiftUI

@MainActor
public class Memories: ObservableObject {
    
    /// A `Logger` object for the ``Memories`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Memories.self)
    )
    
    init() {
        let signpost = StartupMetrics.begin("Memories.init")
        self.patchFileIntegrity()
        self.loadAsync()
        StartupMetrics.end("Memories.init", signpost)
    }
    
    /// Static constant for the global ``Memories`` object
    static public let shared: Memories = .init()
    
    /// Computed property returning the datastore's directory's url
    public static var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Memory"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private static var datastoreDirExists: Bool {
        return Self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public static var datastoreUrl: URL {
        return Self.datastoreDirUrl.appendingPathComponent(
            "memories.json"
        )
    }
    
    /// All memories
    @Published public var memories: [Memory] = []
    /// Whether the datastore has been loaded
    @Published private(set) var isLoaded: Bool = false
    /// Task handling asynchronous datastore loading
    private var loadTask: Task<Void, Never>?
    /// The memories similarity index
    private var similarityIndex: SimilarityIndex?
    /// Function to initialize similarity index
    private func initSimilarityIndex() async {
        if self.similarityIndex != nil {
            return
        }
        guard RetrievalSettings.useMemory else {
            return
        }
        let signpost = StartupMetrics.begin("Memories.initSimilarityIndex")
        self.similarityIndex = await SimilarityIndex(
            model: DistilbertEmbeddings(),
            metric: CosineSimilarity()
        )
        StartupMetrics.end("Memories.initSimilarityIndex", signpost)
    }
    
    /// Function to make new datastore
    public func newDatastore() {
        // Setup directory
        self.patchFileIntegrity()
        // Add new datastore
        self.memories = []
        self.isLoaded = true
        self.save()
    }
    
    /// Loads memories asynchronously to avoid blocking startup
    private func loadAsync() {
        if let loadTask = self.loadTask, !loadTask.isCancelled {
            return
        }
        let targetUrl: URL = Self.datastoreUrl
        self.loadTask = Task.detached(priority: .userInitiated) { [weak self] in
            let signpost = StartupMetrics.begin("Memories.loadDatastore")
            defer { StartupMetrics.end("Memories.loadDatastore", signpost) }
            let rawData: Data
            do {
                rawData = try Data(contentsOf: targetUrl)
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.newDatastore()
                    self.loadTask = nil
                }
                return
            }
            let decoder: JSONDecoder = JSONDecoder()
            let memories = (try? decoder.decode([Memory].self, from: rawData)) ?? []
            await MainActor.run {
                guard let self else { return }
                self.memories = memories
                self.isLoaded = true
                self.loadTask = nil
            }
        }
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        // Present confirmation modal
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Memories"),
            message: String(localized: "Are you sure you want to delete all memories?")
        ) {
            // If yes, delete datastore
            FileManager.removeItem(at: Self.datastoreUrl)
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to load memories
    private func load() {
        do {
            let rawData: Data = try Data(contentsOf: Self.datastoreUrl)
            let decoder: JSONDecoder = JSONDecoder()
            self.memories = try decoder.decode(
                [Memory].self,
                from: rawData
            )
            self.isLoaded = true
        } catch {
            print("Failed to load memories: \(error)")
            self.newDatastore()
        }
    }
    
    /// Function to save memories to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.memories
            )
            try rawData.write(
                to: Self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Function to patch file integrity
    public func patchFileIntegrity() {
        // Setup directory if needed
        if !Self.datastoreDirExists {
            do {
                try FileManager.default.createDirectory(
                    at: Self.datastoreDirUrl,
                    withIntermediateDirectories: true
                )
            } catch {
                Self.logger.error("Failed to create directory for datastore: \(error, privacy: .public)")
            }
        }
    }
    
    /// Function to recall related memory
    public func recall(
        prompt: String,
        maxResults: Int = 5
    ) async -> [String]? {
        // If similarity index is nil, load
        if self.similarityIndex == nil {
            await self.initSimilarityIndex()
        }
        // Conduct search
        if let similarityIndex = self.similarityIndex {
            // Add items
            similarityIndex.indexItems = memories.map(
                keyPath: \.indexItem
            )
            // Search
            let threshold: Float = 0.6
            let results = await similarityIndex.search(
                prompt,
                top: maxResults,
                metric: CosineSimilarity()
            ).filter { result in
                result.score >= threshold
            }
            // Return
            return results.map { result in
                return result.text
            }
        } else {
            return nil
        }
    }
    
    /// Function to delete a memory
    public func forget(_ memory: Memory) {
        withAnimation(.linear) {
            self.memories = self.memories.filter {
                $0.id != memory.id
            }
        }
        self.save()
    }
    
    /// Function to add a memory
    public func remember(_ memory: Memory) {
        withAnimation(.linear) {
            self.memories.append(memory)
        }
        self.save()
    }
    
    /// Function to update a memory
    public func update(_ memory: Memory) {
        withAnimation(.linear) {
            for memoryIndex in self.memories.indices {
                if memory.id == self.memories[memoryIndex].id {
                    self.memories[memoryIndex] = memory
                    break
                }
            }
        }
        self.save()
    }
    
    /// Function to update a memory
    public func update(_ memory: Binding<Memory>) {
        withAnimation(.spring()) {
            let targetId: UUID = memory.wrappedValue.id
            for index in self.memories.indices {
                if targetId == self.memories[index].id {
                    self.memories[index] = memory.wrappedValue
                    break
                }
            }
        }
        self.save()
    }
    
    /// Function to remember if needed
    public func rememberIfNeeded(
        messageId: UUID,
        text: String
    ) async {
        // Exit if memory is off
        if !RetrievalSettings.useMemory {
            return
        }
        // Prompt worker model
        let messageText: String = """
The user sent the message below. What personal information / opinion does this reveal about the user? Do not extract the information if it is very message specific, such as a specific request. 

Respond in the format `The user [verb] [information]`. If there is no personal information / opinion, respond with the word "nil".

Example responses:
1. The user has a dog named Biscuit.
2. The user thinks Hollywood peaked in the 90s
3. nil

"\(text)"
"""
        // Formulate message
        let systemPromptMessage: Message = Message(
            text: InferenceSettings.systemPrompt,
            sender: .system
        )
        let commandMessage: Message = Message(
            text: messageText,
            sender: .user
        )
        // Indicate background task begun
        Model.shared.indicateStartedBackgroundTask()
        // Get response
        if let response: String = (try? await Model.shared.listenThinkRespond(
            messages: [
                systemPromptMessage,
                commandMessage
            ],
            modelType: .worker,
            mode: .default
        ))?.text {
            // Check if format is correct & length is acceptable
            let formatPass: Bool = response.hasPrefix(
                "The user"
            ) && (15...400).contains(response.count)
            // If format passes, remember
            if formatPass,
               let memory: Memory = await Memory(
                messageId: messageId,
                text: response
               ) {
                self.remember(memory)
            }
        }
    }
    
    /// Function to find memories related to a message
    public func getMemories(
        id messageId: UUID
    ) -> Memory? {
        return self.memories.filter({
            $0.messageId == messageId
        }).first
    }
    
}
