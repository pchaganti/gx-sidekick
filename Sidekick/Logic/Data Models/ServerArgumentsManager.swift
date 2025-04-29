//
//  ServerArgumentsManager.swift
//  Sidekick
//
//  Created by John Bean on 4/29/25.
//

import Foundation
import os.log
import SwiftUI

public class ServerArgumentsManager: ObservableObject {
    
    init() {
        self.patchFileIntegrity()
        self.load()
    }
    
    /// Static constant for the global `ServerArgumentsManager` object
    static public let shared: ServerArgumentsManager = .init()
    
    /// Published property for all serverArguments
    @Published public var serverArguments: [ServerArgument] = ServerArgument.defaultServerArguments {
        didSet {
            self.save()
        }
    }
    
    /// A list of active arguments
    public var activeArguments: [ServerArgument] {
        return self.serverArguments
            .filter(\.isActive)
            .filter { argument in
                return !argument.flag.isEmpty
            }
    }
    /// A `String` for all the arguments that need to be appended
    public var allArguments: [String] {
        return self.activeArguments.map(keyPath: \.arguments).reduce([], +)
    }
    
    /// Function to save serverArguments to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.serverArguments
            )
            try rawData.write(
                to: self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Function to load serverArguments from disk
    public func load() {
        do {
            // Load data
            let rawData: Data = try Data(
                contentsOf: self.datastoreUrl
            )
            let decoder: JSONDecoder = JSONDecoder()
            self.serverArguments = try decoder.decode(
                [ServerArgument].self,
                from: rawData
            )
        } catch {
            // Indicate error
            print("Failed to load serverArguments: \(error)")
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to delete a serverArguments
    public func delete(_ serverArguments: Binding<ServerArgument>) {
        withAnimation(.spring()) {
            self.serverArguments = self.serverArguments.filter {
                $0.id != serverArguments.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a serverArguments
    public func delete(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            self.serverArguments = self.serverArguments.filter {
                $0.id != serverArguments.id
            }
        }
    }
    
    /// Function to add a serverArguments
    public func add(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            self.serverArguments.append(serverArguments)
        }
    }
    
    /// Function to update a serverArguments
    public func update(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            for serverArgumentsIndex in self.serverArguments.indices {
                if serverArguments.id == self.serverArguments[serverArgumentsIndex].id {
                    self.serverArguments[serverArgumentsIndex] = serverArguments
                    break
                }
            }
        }
    }
    
    /// Function to update a serverArguments
    public func update(_ serverArguments: Binding<ServerArgument>) {
        withAnimation(.spring()) {
            let targetId: UUID = serverArguments.wrappedValue.id
            for index in self.serverArguments.indices {
                if targetId == self.serverArguments[index].id {
                    self.serverArguments[index] = serverArguments.wrappedValue
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
        self.serverArguments = ServerArgument.defaultServerArguments
        self.save()
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        // Present confirmation modal
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Server Arguments"),
            message: String(localized: "Are you sure you want to delete all server arguments?")
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
            try! FileManager.default.createDirectory(
                at: datastoreDirUrl,
                withIntermediateDirectories: true
            )
        }
    }
    
    /// Computed property returning the datastore's directory's url
    public var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Server Arguments"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "serverArguments.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
}

