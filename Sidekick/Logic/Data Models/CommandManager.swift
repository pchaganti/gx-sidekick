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
		self.patchFileIntegrity()
		self.load()
	}
	
	/// Static constant for the global ``CommandManager`` object
	static public let shared: CommandManager = .init()
	
	/// Published property for all commands
	@Published public var commands: [Command] = [] {
		didSet {
			self.save()
		}
	}
	
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
	
	/// Function to load commands from disk
	public func load() {
		do {
			// Load data
			let rawData: Data = try Data(
				contentsOf: self.datastoreUrl
			)
			let decoder: JSONDecoder = JSONDecoder()
			self.commands = try decoder.decode(
				[Command].self,
				from: rawData
			)
		} catch {
			// Indicate error
			print("Failed to load commands: \(error)")
			// Make new datastore
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
		return URL.applicationSupportDirectory.appendingPathComponent(
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

