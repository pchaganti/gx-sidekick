//
//  Conversation.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation

public struct Conversation: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for conversation title
	public var title: String
	
	/// Stored property for the selected expert's ID
	public var expertId: UUID? = ExpertManager.shared.firstExpert?.id
	
	/// Computed property returning the selected expert
	public var expert: Expert? {
		guard let expertId else { return nil }
		return ExpertManager.shared.getExpert(id: expertId)
	}
	
	/// Computed property returning the system prompt used
	public var systemPrompt: String? {
		return expert?.systemPrompt
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
	
	/// The length of the conversation in tokens, of type `Int`
	public var tokenCount: Int?
	
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
	
	/// Function to drop last message
	public mutating func dropLastMessage() {
		self.messages.removeLast()
	}
	
	/// Static function for equatable conformance
	public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
		return lhs.id == rhs.id
	}
	
}
