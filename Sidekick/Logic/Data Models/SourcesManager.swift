//
//  SourcesManager.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import Foundation
import os.log
import SwiftUI

public class SourcesManager: ObservableObject {
	
	init() {
		self.patchFileIntegrity()
		self.load()
	}
	
	/// Static constant for the global `SourcesManager` object
	static public let shared: SourcesManager = .init()
	
	/// Published property for all sources
	@Published public var sources: [Sources] = [] {
		didSet {
			self.save()
		}
	}
	
	/// Function to add a new sources
	public func newSources(
		sources: Sources
	) async {
		// Add to sources
		self.sources.append(sources)
	}

	/// Function returning sources with the given message ID
	public func getSources(
		id messageId: UUID
	) -> Sources? {
		return self.sources.filter({
			$0.messageId == messageId
		}).first
	}
	
	/// Function to save sources to disk
	public func save() {
		do {
			// Save data
			let rawData: Data = try JSONEncoder().encode(
				self.sources
			)
			try rawData.write(
				to: self.datastoreUrl,
				options: .atomic
			)
		} catch {
			os_log("error = %@", error.localizedDescription)
		}
	}
	
	/// Function to load sources from disk
	public func load() {
		do {
			// Load data
			let rawData: Data = try Data(
				contentsOf: self.datastoreUrl
			)
			let decoder: JSONDecoder = JSONDecoder()
			self.sources = try decoder.decode(
				[Sources].self,
				from: rawData
			)
		} catch {
			// Indicate error
			print("Failed to load sources: \(error)")
			// Make new datastore
			self.newDatastore()
		}
	}
	
	/// Function to delete a sources
	public func delete(_ sources: Binding<Sources>) {
		withAnimation(.spring()) {
			self.sources = self.sources.filter {
				$0.id != sources.wrappedValue.id
			}
		}
	}
	
	/// Function to delete a sources
	public func delete(_ sources: Sources) {
		withAnimation(.spring()) {
			self.sources = self.sources.filter {
				$0.id != sources.id
			}
		}
	}
	
	/// Function to add a sources
	public func add(_ sources: Sources) {
		withAnimation(.spring()) {
			self.sources.append(sources)
		}
	}
	
	/// Function to update a sources
	public func update(_ sources: Sources) {
		withAnimation(.spring()) {
			for sourcesIndex in self.sources.indices {
				if sources.id == self.sources[sourcesIndex].id {
					self.sources[sourcesIndex] = sources
					break
				}
			}
		}
	}
	
	/// Function to update a sources
	public func update(_ sources: Binding<Sources>) {
		withAnimation(.spring()) {
			let targetId: UUID = sources.wrappedValue.id
			for index in self.sources.indices {
				if targetId == self.sources[index].id {
					self.sources[index] = sources.wrappedValue
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
		self.sources = []
		self.save()
	}
	
	/// Function to reset datastore
	@MainActor
	public func resetDatastore() {
		// Present confirmation modal
		let _ = Dialogs.showConfirmation(
			title: String(localized: "Delete All Sources"),
			message: String(localized: "Are you sure you want to delete all sources?")
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
		return URL.applicationSupportDirectory.appendingPathComponent(
			"Sources"
		)
	}
	
	/// Computed property returning if datastore directory exists
	private var datastoreDirExists: Bool {
		return self.datastoreDirUrl.fileExists
	}
	
	/// Computed property returning the datastore's url
	public var datastoreUrl: URL {
		return self.datastoreDirUrl.appendingPathComponent(
			"sources.json"
		)
	}
	
	/// Computed property returning if datastore exists
	private var datastoreExists: Bool {
		return self.datastoreUrl.fileExists
	}
	
	/// Function to remove sources with no message
	public func removeStaleSources() async {
		// Get all message IDs
		let allMessageIds: [UUID] = await ConversationManager.shared.allMessagesIds
		var staleSources: [Int] = []
		// Locate stale sources
		for index in self.sources.indices {
			let messageId: UUID = self.sources[index].messageId
			// Set to remove if not found
			if !allMessageIds.contains(messageId) {
				staleSources.append(index)
			}
		}
		// Remove
		staleSources.forEach { index in
			self.sources.remove(at: index)
		}
		// Save
		self.save()
	}

}

