//
//  Extension+Binding.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import Foundation
import SwiftUI

extension Binding where Value == Profile {
	
	/// Function to add a resource
	func addResource(_ resource: Resource) async {
		await wrappedValue.resources.addResource(
			resource,
			profileName: self.wrappedValue.name
		)
	}
	
	/// Function to add multiple resources
	func addResources(_ resources: [Resource]) async {
		await wrappedValue.resources.addResources(
			resources,
			profileName: self.wrappedValue.name
		)
	}
	
	/// Function to remove a resource
	func removeResource(_ resource: Resource) async {
		await wrappedValue.resources.removeResource(
			resource,
			profileName: self.wrappedValue.name
		)
	}
	
	/// Function to update a resource index
	func update() async {
		await wrappedValue.resources.updateResourcesIndex(
			profileName: self.wrappedValue.name
		)
	}
	
}
