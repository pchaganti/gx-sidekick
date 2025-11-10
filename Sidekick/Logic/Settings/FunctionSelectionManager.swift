//
//  FunctionSelectionManager.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation
import OSLog

/// Manager class for persisting and managing function selection state
@MainActor
public class FunctionSelectionManager: ObservableObject {
    
    /// Logger for the manager
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FunctionSelectionManager.self)
    )
    
    /// Shared singleton instance
    public static let shared = FunctionSelectionManager()
    
    /// Set of enabled function categories
    @Published public var enabledCategories: Set<FunctionCategory> = []
    
    /// Path to the JSON file storing the selection state
    private var storageURL: URL {
        let cacheDirectory = Settings.containerUrl
            .appendingPathComponent("Cache")
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return cacheDirectory.appendingPathComponent("function_selection.json")
    }

    
    private init() {
        self.loadSelection()
    }
    
    /// Load the function selection from disk
    private func loadSelection() {
        do {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: storageURL.path) else {
                // If file doesn't exist, enable all categories by default
                self.enabledCategories = Set(FunctionCategory.allCases)
                self.saveSelection()
                return
            }
            
            // Read and decode the JSON file
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            let categories = try decoder.decode([FunctionCategory].self, from: data)
            self.enabledCategories = Set(categories)
            
            Self.logger.info("Loaded function selection: \(categories.map { $0.rawValue })")
        } catch {
            Self.logger.error("Failed to load function selection: \(error.localizedDescription)")
            // On error, enable all categories
            self.enabledCategories = Set(FunctionCategory.allCases)
        }
    }
    
    /// Save the function selection to disk
    public func saveSelection() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let categories = Array(enabledCategories).sorted { $0.rawValue < $1.rawValue }
            let data = try encoder.encode(categories)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            Self.logger.error("Failed to save function selection: \(error.localizedDescription)")
        }
    }
    
    /// Toggle a function category on/off
    public func toggleCategory(_ category: FunctionCategory) {
        if enabledCategories.contains(category) {
            enabledCategories.remove(category)
        } else {
            enabledCategories.insert(category)
        }
        saveSelection()
    }
    
    /// Check if a category is enabled
    public func isEnabled(_ category: FunctionCategory) -> Bool {
        return enabledCategories.contains(category)
    }
    
    /// Get all enabled functions based on current selection
    public func getEnabledFunctions() -> [AnyFunctionBox] {
        return enabledCategories.flatMap { $0.functions }
    }
    
    /// Enable all categories
    public func enableAll() {
        enabledCategories = Set(FunctionCategory.allCases)
        saveSelection()
    }
    
    /// Disable all categories
    public func disableAll() {
        enabledCategories = []
        saveSelection()
    }
}

