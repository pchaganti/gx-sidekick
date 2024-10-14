//
//  Conversation.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import LLM

public struct Conversation: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for conversation title
	public var title: String
	
	/// Stored property for the selected profile's ID
	public var profileId: UUID? = ProfileManager.shared.firstProfile?.id
	
	/// Computed property returning the selected profile
	public var profile: Profile? {
		guard let profileId else { return nil }
		return ProfileManager.shared.getProfile(id: profileId)
	}
	
	/// Computed property returning the system prompt used
	public var systemPrompt: String? {
		return profile?.systemPrompt
	}
	
	/// Stored property for creation date
	public var createdAt: Date = .now
	
	/// Stored property for messages
	public var messages: [Message] = []
	
	/// Computed property for most recent update
	public var lastUpdated: Date {
		if let lastUpdate: Date = self.messages.map({
			$0.lastUpdated
		}).max() {
			return lastUpdate
		} else {
			return self.createdAt
		}
	}
	
	/// Function to add a new message, returns `true` if successful
	public mutating func addMessage(_ message: Message) -> Bool {
		// Check if different sender
		let lastSender: Sender? = self.messages.last?.getSender()
		if lastSender != nil {
			let differentSender: Bool = lastSender != message.getSender()
			if !differentSender {
				return false
			}
		}
		// Check if blank if user
		if message.text.isEmpty && message.getSender() == .user {
			return false
		}
		// Make new message
		self.messages.append(message)
		// Set title if needed
		if self.messages.isEmpty {
			self.title = message.text
		}
		return true
	}
	
	/// Function to update an existing message
	public mutating func updateMessage(_ message: Message) {
		for index in self.messages.indices {
			if self.messages[index].id == message.id {
				self.messages[index] = message
				return
			}
		}
	}
	
	/// Static function for equatable conformance
	public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
		return lhs.id == rhs.id
	}
	
}
