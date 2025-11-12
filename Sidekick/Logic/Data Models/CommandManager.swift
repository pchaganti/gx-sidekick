//
//  CommandManager.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import os.log
import SwiftUI

public class CommandManager: ObservableObject {
    
    init() {
        let signpost = StartupMetrics.begin("CommandManager.init")
        self.patchFileIntegrity()
        self.loadAsync()
        StartupMetrics.end("CommandManager.init", signpost)
    }
    
    /// Static constant for the global ``CommandManager`` object
    static public let shared: CommandManager = .init()
    
    /// Published property for all commands
    @Published public var commands: [Command] = [] {
        didSet {
            self.save()
        }
    }
    
    /// Published state tracking whether the datastore has been loaded
    @Published private(set) var isLoaded: Bool = false
    
    /// Task handling asynchronous datastore loading
    private var loadTask: Task<Void, Never>?
    
    /// Computed property returning the first command
    var firstCommand: Command? {
        if self.commands.first == nil {
            self.newDatastore()
        }
        return self.commands.first
    }
    
    /// Computed property returning the last command
    var lastCommand: Command? {
        if self.commands.last == nil {
            self.newDatastore()
        }
        return self.commands.last
    }
    
    /// Function to create a new command
    public func addCommand(
        command: Command
    ) {
        // Add to commands
        self.commands.append(command)
    }
    
    /// Function returning a command with the given ID
    public func getCommand(
        id commandId: UUID
    ) -> Command? {
        return self.commands.filter({ $0.id == commandId }).first
    }
    
    /// Function to save commands to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.commands
            )
            try rawData.write(
                to: self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Loads commands in the background to avoid blocking startup
    private func loadAsync() {
        if let loadTask = self.loadTask, !loadTask.isCancelled {
            return
        }
        let targetUrl: URL = self.datastoreUrl
        self.loadTask = Task.detached(priority: .userInitiated) { [weak self] in
            let signpost = StartupMetrics.begin("CommandManager.loadDatastore")
            defer { StartupMetrics.end("CommandManager.loadDatastore", signpost) }
            let rawData: Data
            do {
                rawData = try Data(contentsOf: targetUrl)
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.newDatastore()
                    self.isLoaded = true
                    self.loadTask = nil
                }
                return
            }
            let decoder: JSONDecoder = JSONDecoder()
            let commands = (try? decoder.decode([Command].self, from: rawData)) ?? []
            await MainActor.run {
                guard let self else { return }
                self.commands = commands
                self.isLoaded = true
                self.loadTask = nil
            }
        }
    }
    
    /// Function to load commands from disk
    public func load() {
        do {
            let rawData: Data = try Data(
                contentsOf: self.datastoreUrl
            )
            let decoder: JSONDecoder = JSONDecoder()
            self.commands = try decoder.decode(
                [Command].self,
                from: rawData
            )
            self.isLoaded = true
        } catch {
            print("Failed to load commands: \(error)")
            self.newDatastore()
        }
    }
    
    /// Function to delete a command
    public func delete(_ command: Binding<Command>) {
        withAnimation(.spring()) {
            self.commands = self.commands.filter {
                $0.id != command.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a command
    public func delete(_ command: Command) {
        withAnimation(.spring()) {
            self.commands = self.commands.filter {
                $0.id != command.id
            }
        }
    }
    
    /// Function to add a command
    public func add(_ command: Command) {
        withAnimation(.linear) {
            self.commands.append(command)
            self.commands = self.commands.sorted(by: \.name)
        }
    }
    
    /// Function to update a command
    public func update(_ command: Command) {
        withAnimation(.spring()) {
            for commandIndex in self.commands.indices {
                if command.id == self.commands[commandIndex].id {
                    self.commands[commandIndex] = command
                    break
                }
            }
        }
    }
    
    /// Function to update a command
    public func update(_ command: Binding<Command>) {
        withAnimation(.spring()) {
            let targetId: UUID = command.wrappedValue.id
            for index in self.commands.indices {
                if targetId == self.commands[index].id {
                    self.commands[index] = command.wrappedValue
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
        self.commands = Command.defaults
        self.isLoaded = true
        self.save()
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        // Present confirmation modal
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Commands"),
            message: String(localized: "Are you sure you want to delete all commands?")
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
            "Commands"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "commands.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
}

