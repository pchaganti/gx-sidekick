//
//  ModelManager.swift
//  Sidekick
//
//  Created by Bean John on 11/8/24.
//

import Foundation
import os.log
import SwiftUI

public class ModelManager: ObservableObject {
	
	init() {
		self.patchFileIntegrity()
		self.load()
	}
	
	/// Static constant for the global ``ModelManager`` object
	static public let shared: ModelManager = .init()
	
	@Published var models: [ModelFile] = [] {
		didSet {
			self.save()
		}
	}
	
	/// Function to save models to disk
	public func save() {
		do {
			// Save data
			let rawData: Data = try JSONEncoder().encode(
				self.models
			)
			try rawData.write(
				to: self.datastoreUrl,
				options: .atomic
			)
		} catch {
			os_log("error = %@", error.localizedDescription)
		}
	}
	
	/// Function to load models from disk
	public func load() {
		do {
			// Load data
			let rawData: Data = try Data(
				contentsOf: self.datastoreUrl
			)
			let decoder: JSONDecoder = JSONDecoder()
			self.models = try decoder.decode(
				[ModelFile].self,
				from: rawData
			)
		} catch {
			// Indicate error
			print("Failed to load models: \(error)")
			// Make new datastore
			self.newDatastore()
		}
	}
	
	/// Function to delete a model
	public func delete(_ model: Binding<ModelFile>) {
		withAnimation(.spring()) {
			self.models = self.models.filter {
				$0.id != model.wrappedValue.id
			}
		}
	}
	
	/// Function to delete a model
	public func delete(_ model: ModelFile) {
		withAnimation(.spring()) {
			self.models = self.models.filter {
				$0.id != model.id
			}
		}
	}
	
	/// Function to add a model
	public func add(_ modelUrl: URL) {
		// Check for repeat
		if self.models.map(\.url).contains(modelUrl) {
			return
		}
		// Else, add to models
		let model: ModelFile = .init(url: modelUrl)
		withAnimation(.linear) {
			self.models.append(model)
			self.models.sort(by: { $0.name < $1.name })
		}
	}
	
	/// Function to make new datastore
	public func newDatastore() {
		// Setup directory
		self.patchFileIntegrity()
		// Add new datastore
		if let currentModelUrl: URL = Settings.modelUrl {
			self.models = [
				ModelFile(url: currentModelUrl)
			]
		} else {
			self.models = []
		}
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
		return URL.applicationSupportDirectory.appendingPathComponent(
			"Models"
		)
	}
	
	/// Computed property returning if datastore directory exists
	private var datastoreDirExists: Bool {
		return self.datastoreDirUrl.fileExists
	}
	
	/// Computed property returning the datastore's url
	public var datastoreUrl: URL {
		return self.datastoreDirUrl.appendingPathComponent(
			"models.json"
		)
	}
	
	/// Computed property returning if datastore exists
	private var datastoreExists: Bool {
		return self.datastoreUrl.fileExists
	}
	
	public struct ModelFile: Identifiable, Equatable, Codable {
		
		/// Stored property for `Identifiable` conformance
		public var id: UUID = UUID()
		
		/// The url of the model, of type `URL`
		public let url: URL
		/// The name of the model, of type `String`
		public var name: String {
			return url.deletingPathExtension().lastPathComponent
		}
		
	}
	
}
