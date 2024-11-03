//
//  ProfileManager.swift
//  Sidekick
//
//  Created by Bean John on 10/6/24.
//

import Foundation
import os.log
import SwiftUI

public class ProfileManager: ObservableObject {
	
	init() {
		self.patchFileIntegrity()
		self.load()
	}
	
	/// Static constant for the global `ProfileManager` object
	static public let shared: ProfileManager = .init()
	
	/// Published property for all profiles
	@Published public var profiles: [Profile] = [] {
		didSet {
			self.save()
		}
	}
	
	/// Computed property returning the first profile
	var firstProfile: Profile? {
		if self.profiles.first == nil {
			self.newDatastore()
		}
		return self.profiles.first
	}
	
	/// Computed property returning the last profile
	var lastProfile: Profile? {
		if self.profiles.last == nil {
			self.newDatastore()
		}
		return self.profiles.last
	}
	
	/// Computed property returning the default profile
	var `default`: Profile? {
		if self.profiles.filter({ $0.name == String(localized: "Default") }).isEmpty {
			self.profiles = [.default] + self.profiles
		}
		return self.profiles.filter({ $0.name == String(localized: "Default") }).first
	}
	
	/// Function to create a new profile
	public func newProfile(
		name: String,
		symbolName: String,
		color: Color,
		resources: [Resource]
	) async {
		var profile: Profile = Profile(
			name: name,
			symbolName: symbolName,
			color: color
		)
		// Run setup function
		await profile.resources.setup()
		// Add resources
		await profile.resources.addResources(
			resources,
			profileName: name
		)
		// Add to profiles
		self.profiles.append(profile)
	}
	
	/// Function to add resources to a profile
	public func addResources(
		profileId: UUID,
		resources: [Resource]
	) async {
		for index in self.profiles.indices {
			if profileId == self.profiles[index].id {
				await self.profiles[index].resources.addResources(
					resources,
					profileName: self.profiles[index].name
				)
				break
			}
		}
	}
	
	/// Function returning a profile with the given ID
	public func getProfile(
		id profileId: UUID
	) -> Profile? {
		return self.profiles.filter({ $0.id == profileId }).first
	}
	
	/// Function to save profiles to disk
	public func save() {
		do {
			// Save data
			let rawData: Data = try JSONEncoder().encode(
				self.profiles
			)
			try rawData.write(
				to: self.datastoreUrl,
				options: .atomic
			)
		} catch {
			os_log("error = %@", error.localizedDescription)
		}
	}
	
	/// Function to load profiles from disk
	public func load() {
		do {
			// Load data
			let rawData: Data = try Data(
				contentsOf: self.datastoreUrl
			)
			let decoder: JSONDecoder = JSONDecoder()
			self.profiles = try decoder.decode(
				[Profile].self,
				from: rawData
			)
		} catch {
			// Indicate error
			print("Failed to load profiles: \(error)")
			// Make new datastore
			self.newDatastore()
		}
	}
	
	/// Function to delete a profile
	public func delete(_ profile: Binding<Profile>) {
		withAnimation(.spring()) {
			self.profiles = self.profiles.filter {
				$0.id != profile.wrappedValue.id
			}
		}
	}
	
	/// Function to delete a profile
	public func delete(_ profile: Profile) {
		withAnimation(.spring()) {
			self.profiles = self.profiles.filter {
				$0.id != profile.id
			}
		}
	}
	
	/// Function to add a profile
	public func add(_ profile: Profile) {
		withAnimation(.linear) {
			self.profiles.append(profile)
		}
	}
	
	/// Function to update a profile
	public func update(_ profile: Profile) {
		withAnimation(.spring()) {
			for profileIndex in self.profiles.indices {
				if profile.id == self.profiles[profileIndex].id {
					self.profiles[profileIndex] = profile
					break
				}
			}
		}
	}
	
	/// Function to update a profile
	public func update(_ profile: Binding<Profile>) {
		withAnimation(.spring()) {
			let targetId: UUID = profile.wrappedValue.id
			for index in self.profiles.indices {
				if targetId == self.profiles[index].id {
					self.profiles[index] = profile.wrappedValue
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
		self.profiles = Self.defaultProfiles
		self.save()
	}
	
	/// Function to reset datastore
	@MainActor
	public func resetDatastore() {
		// Present confirmation modal
		let _ = Dialogs.showConfirmation(
			title: String(localized: "Delete All Profiles"),
			message: String(localized: "Are you sure you want to delete all profiles?")
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
		for index in self.profiles.indices {
			if !self.profiles[index].persistResources {
				let dirUrl: URL = profiles[index].resources.indexUrl
				self.profiles[index].resources.resources.forEach { resource in
					resource.deleteDirectory(resourcesDirUrl: dirUrl)
				}
				self.profiles[index].resources.resources.removeAll()
				print("Removed resources for profile \(profiles[index].name).")
			}
		}
	}
	
	/// Static constant for default profiles
	public static var defaultProfiles: [Profile] {
		return [
			Profile.default
		]
	}
	
}
