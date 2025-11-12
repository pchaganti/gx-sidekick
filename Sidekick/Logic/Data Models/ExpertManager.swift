//
//  ExpertManager.swift
//  Sidekick
//
//  Created by Bean John on 10/6/24.
//

import Foundation
import os.log
import SwiftUI

public class ExpertManager: ObservableObject {
    
    init() {
        self.patchFileIntegrity()
        self.load()
    }
    
    /// Static constant for the global ``ExpertManager`` object
    static public let shared: ExpertManager = .init()
    
    /// A `Logger` object for the ``ExpertManager`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ExpertManager.self)
    )
    
    /// Published property for all experts
    @Published public var experts: [Expert] = [] {
        didSet {
            self.save()
        }
    }
    
    /// Computed property returning the first expert
    var firstExpert: Expert? {
        if self.experts.first == nil {
            self.newDatastore()
        }
        return self.experts.first
    }
    
    /// Computed property returning the last expert
    var lastExpert: Expert? {
        if self.experts.last == nil {
            self.newDatastore()
        }
        return self.experts.last
    }
    
    /// Computed property returning the default expert
    var `default`: Expert? {
        if self.experts.filter({ $0.name == String(localized: "Default") }).isEmpty {
            self.experts = [.default] + self.experts
        }
        return self.experts.filter({ $0.name == String(localized: "Default") }).first
    }
    
    /// Function to create a new expert
    public func newExpert(
        name: String,
        symbolName: String,
        color: Color,
        resources: [Resource]
    ) async {
        var expert: Expert = Expert(
            name: name,
            symbolName: symbolName,
            color: color
        )
        // Run setup function
        await expert.resources.setup()
        // Add resources (indexing can be triggered manually later)
        await MainActor.run {
            expert.resources.addResources(resources)
        }
        // Add to experts
        self.experts.append(expert)
    }
    
    /// Function to add resources to a expert
    public func addResources(
        expertId: UUID,
        resources: [Resource]
    ) async {
        for index in self.experts.indices {
            if expertId == self.experts[index].id {
                await MainActor.run {
                    self.experts[index].resources.addResources(resources)
                }
                break
            }
        }
    }
    
    /// Function returning a expert with the given ID
    public func getExpert(
        id expertId: UUID
    ) -> Expert? {
        return self.experts.filter({ $0.id == expertId }).first
    }
    
    /// Function returning a expert's index
    public func getExpertIndex(
        expert targetExpert: Expert
    ) -> Int {
        for (index, expert) in self.experts.enumerated() {
            if expert == targetExpert {
                return index
            }
        }
        return 0
    }
    
    /// Function to save experts to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.experts
            )
            try rawData.write(
                to: self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Function to load experts from disk
    public func load() {
        do {
            let rawData: Data = try Data(
                contentsOf: self.datastoreUrl
            )
            let decoder: JSONDecoder = JSONDecoder()
            self.experts = try decoder.decode(
                [Expert].self,
                from: rawData
            )
        } catch {
            print("Failed to load experts: \(error)")
            self.newDatastore()
        }
    }
    
    /// Function to delete a expert
    public func delete(_ expert: Binding<Expert>) {
        withAnimation(.linear) {
            self.experts = self.experts.filter {
                $0.id != expert.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a expert
    public func delete(_ expert: Expert) {
        withAnimation(.linear) {
            self.experts = self.experts.filter {
                $0.id != expert.id
            }
        }
    }
    
    /// Function to add a expert
    public func add(_ expert: Expert) {
        withAnimation(.linear) {
            self.experts.append(expert)
        }
    }
    
    /// Function to update a expert
    public func update(_ expert: Expert) {
        withAnimation(.linear) {
            for expertIndex in self.experts.indices {
                if expert.id == self.experts[expertIndex].id {
                    self.experts[expertIndex] = expert
                    break
                }
            }
        }
    }
    
    /// Function to update a expert
    public func update(_ expert: Binding<Expert>) {
        withAnimation(.spring()) {
            let targetId: UUID = expert.wrappedValue.id
            for index in self.experts.indices {
                if targetId == self.experts[index].id {
                    self.experts[index] = expert.wrappedValue
                    break
                }
            }
        }
    }
    
    /// Function to make new datastore
    public func newDatastore() {
        // Setup directory
        self.patchFileIntegrity()
        // Add new datastore
        self.experts = Self.defaultExperts
        self.save()
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        // Present confirmation modal
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Experts"),
            message: String(localized: "Are you sure you want to delete all experts?")
        ) {
            // If yes, delete datastore
            FileManager.removeItem(at: self.datastoreUrl)
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to patch file integrity
    public func patchFileIntegrity() {
        // Setup directory if needed
        if !self.datastoreDirExists {
            do {
                try FileManager.default.createDirectory(
                    at: datastoreDirUrl,
                    withIntermediateDirectories: true
                )
            } catch {
                Self.logger.error("Failed to create directory for datastore: \(error, privacy: .public)")
            }
        }
    }
    
    /// Computed property returning the datastore's directory's url
    public var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Profiles"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "profiles.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
    /// Function to remove unpersisted resources on app termination
    public func removeUnpersistedResources() {
        for index in self.experts.indices {
            if !self.experts[index].persistResources {
                let dirUrl: URL = experts[index].resources.indexUrl
                self.experts[index].resources.resources.forEach { resource in
                    resource.deleteDirectory(resourcesDirUrl: dirUrl)
                }
                self.experts[index].resources.resources.removeAll()
                print("Removed resources for expert \(experts[index].name).")
            }
        }
    }
    
    /// Static constant for default experts
    public static var defaultExperts: [Expert] {
        return [
            Expert.default
        ]
    }
    
}
