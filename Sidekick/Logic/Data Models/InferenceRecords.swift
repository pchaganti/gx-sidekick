//
//  InferenceRecords.swift
//  Sidekick
//
//  Created by John Bean on 5/20/25.
//

import Foundation
import FSKit_macOS
import os.log
import SwiftUI
import UniformTypeIdentifiers

public class InferenceRecords: ObservableObject {
    
    init() {
        self.patchFileIntegrity()
        self.load()
    }
    
    /// Static constant for the global ``InferenceRecords`` object
    static public let shared: InferenceRecords = .init()
    
    @Published var records: [InferenceRecord] = [] {
        didSet {
            self.save()
        }
    }
    
    /// Function to save records to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.records
            )
            try rawData.write(
                to: self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Function to load records from disk
    public func load() {
        do {
            // Load data
            let rawData: Data = try Data(
                contentsOf: self.datastoreUrl
            )
            let decoder: JSONDecoder = JSONDecoder()
            self.records = try decoder.decode(
                [InferenceRecord].self,
                from: rawData
            )
        } catch {
            // Indicate error
            print("Failed to load records: \(error)")
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to delete a record
    public func delete(
        _ record: Binding<InferenceRecord>
    ) {
        withAnimation(.spring()) {
            self.records = self.records.filter {
                $0.id != record.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a record
    public func delete(
        _ record: InferenceRecord
    ) {
        withAnimation(.spring()) {
            self.records = self.records.filter {
                $0.id != record.id
            }
        }
    }
    
    /// Function to add a record
    public func add(
        _ record: InferenceRecord
    ) {
        // Add to records
        withAnimation(.linear) {
            self.records.append(record)
            self.records.sort(by: { $0.startTime < $1.startTime })
        }
    }
    
    /// Function to make new datastore
    public func newDatastore() {
        // Setup directory
        self.patchFileIntegrity()
        self.records = []
        self.save()
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
            "Inference Records"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "records.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
}
