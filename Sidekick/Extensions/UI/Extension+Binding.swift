//
//  Extension+Binding.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import Foundation
import SwiftUI
import OSLog

extension Binding where Value == TemporaryResource {
	
	/// Function to scan temporary resource
	func scan() async {
		let _ = await wrappedValue.scan()
	}
}


extension Binding where Value == Expert {
	
	/// Function to add a resource
	func addResource(_ resource: Resource) async {
		// Add resource
		await wrappedValue.resources.addResource(
			resource,
			expertName: self.wrappedValue.name
		)
	}
	
	/// Function to add multiple resources
	func addResources(_ resources: [Resource]) async {
		await wrappedValue.resources.addResources(
			resources,
			expertName: self.wrappedValue.name
		)
	}
	
	/// Function to remove a resource
	func removeResource(_ resource: Resource) async {
		await wrappedValue.resources.removeResource(
			resource,
			expertName: self.wrappedValue.name
		)
	}
	
	/// Function to update a resource index
	@MainActor
	func update() async {
		await wrappedValue.resources.updateResourcesIndex(
			expertName: self.wrappedValue.name
		)
	}
	
}
