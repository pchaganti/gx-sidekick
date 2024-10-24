//
//  Resources.swift
//  Sidekick
//
//  Created by Bean John on 10/6/24.
//

import Foundation
import FSKit_macOS
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

public struct Resources: Identifiable, Codable, Hashable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for all resources associated with this profile
	public var resources: [Resource] = []
	
	/// Computed property retuning the URL of the profile's index directory
	public var indexUrl: URL {
		return URL
			.applicationSupportDirectory
			.appendingPathComponent("Resources")
			.appendingPathComponent(self.id.uuidString)
	}
	
	/// TODO: shareAllResources
	
	/// Function to load `SimilarityIndex`, must cache after initial load to improve performance
	public func loadIndex() async -> SimilarityIndex {
		let startTime: Date = .now
		// Init index
		let similarityIndex: SimilarityIndex = await SimilarityIndex(
			model: DistilbertEmbeddings(),
			metric: CosineSimilarity()
		)
		// Load items
		for resource in self.resources {
			let indexItems: [IndexItem] = await resource.getIndexItems(
				resourcesDirUrl: self.indexUrl
			)
			similarityIndex.indexItems += indexItems
		}
		print("Loaded index in \(Date.now.timeIntervalSince(startTime)) seconds.")
		// Return similarity index
		return similarityIndex
	}
	
	/// Function to update resources index
	@MainActor
	public mutating func updateResourcesIndex(profileName: String) async {
		// Add to task list
		let taskId: UUID = UUID()
		LengthyTasksController.shared.addTask(
			id: taskId, 
			task: "Updating resource index for profile \"\(profileName)\""
		)
		// Update for each file
		for index in self.resources.indices  {
			await self.resources[index].updateIndex(
				resourcesDirUrl: self.indexUrl
			)
		}
		// Record removed resources
		let removedResources: [Resource] = resources.filter({
			!(!$0.wasMoved || $0.isWebResource)
		})
		let removedResourcesDescription: String = removedResources.map({
			return "\"\($0.name)\""
		}).joined(separator: ", ")
		if !removedResources.isEmpty {
			Dialogs.showAlert(
				title: String(localized: "Remove Resources"),
				message: String(localized: "The resources \(removedResourcesDescription) were removed because they could not be located.")
			)
		}
		// Remove resources
		resources = resources.filter({ !$0.wasMoved || $0.isWebResource })
		// Remove from task list
		LengthyTasksController.shared.finishTask(taskId: taskId)
	}

	/// Function to initialize directory for resources
	public mutating func setup() async {
		// Make directory
		try! FileManager.default.createDirectory(
			at: self.indexUrl,
			withIntermediateDirectories: true
		)
	}
	
	/// Function to add a resource
	@MainActor
	public mutating func addResource(
		_ resource: Resource,
		profileName: String
	) async {
		// Check if exists
		if self.resources.map(\.url).contains(resource.url) { return }
		// Add to resources list
		self.resources.append(resource)
		// Reindex
		await self.updateResourcesIndex(profileName: profileName)
	}
	
	/// Function to add multiple resources
	@MainActor
	public mutating func addResources(
		_ resources: [Resource],
		profileName: String
	) async {
		// Add to resources list
		for resource in resources {
			if self.resources.map(\.url).contains(resource.url) {
				continue
			}
			self.resources.append(resource)
		}
		// Reindex
		await self.updateResourcesIndex(profileName: profileName)
	}
	
	/// Function to remove a resource
	@MainActor
	public mutating func removeResource(
		_ resource: Resource,
		profileName: String
	) async {
		// Find matching resource
		for index in self.resources.indices  {
			if self.resources[index].id == resource.id {
				// Clear index
				self.resources[index].deleteDirectory(
					resourcesDirUrl: self.indexUrl
				)
				// Remove from list
				self.resources.remove(at: index)
				// Reindex
				await self.updateResourcesIndex(
					profileName: profileName
				)
				break
			}
		}
	}
	
	/// Function to show index directory
	public func showIndexDirectory() async {
		await MainActor.run {
			FileManager.showItemInFinder(url: self.indexUrl)
		}
	}
	
}
