//
//  Message.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

public struct Message: Identifiable, Codable, Hashable {
	
	init(
		text: String,
		sender: Sender
	) {
		self.id = UUID()
		self.text = text
		self.sender = sender
		self.startTime = .now
		self.lastUpdated = .now
		self.outputEnded = false
		self.model = Settings.modelUrl?.lastPathComponent ?? "Unknown"
	}
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the message text
	public var text: String
	/// Computed property for the number of tokens outputted per second
	public var tokensPerSecond: Double?
	
	/// Stored property for the selected model
	public let model: String
	
	/// Stored property for the sender of the message (either `user` or `system`)
	private var sender: Sender
	
	/// Function to get the sender
	public func getSender() -> Sender {
		return self.sender
	}
	
	/// Computed property for the sender's icon
	var icon: some View {
		sender.icon
	}
	
	/// Stored property for the start time of interaction
	public var startTime: Date
	/// Stored property for the most recent update time
	public var lastUpdated: Date
	
	/// Stored property for the time taken for a response to start
	public var responseStartSeconds: Double?
	
	/// Stored property for whether the output has finished
	public var outputEnded: Bool
	
	/// Function to update message
	@MainActor
	public mutating func update(
		newText: String,
		tokensPerSecond: Double?,
		responseStartSeconds: Double
	) {
		self.text = newText
		self.tokensPerSecond = tokensPerSecond
		self.responseStartSeconds = responseStartSeconds
		self.lastUpdated = .now
	}
	
	/// Function to end a message
	public mutating func end() {
		self.lastUpdated = .now
		self.outputEnded = true
	}
	
	/// Static constant for testing a MessageView
	static let test: Message = Message(
		text: "Hi there! I'm an artificial intelligence model known as **Llama**, a [**LLM** (Large Language Model)](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://en.wikipedia.org/wiki/Large_language_model&ved=2ahUKEwjTvLKIt_6IAxWVulYBHb09CFUQFnoECBkQAQ&usg=AOvVaw3ojBiy1-Rxlxl5lO1-SI8F) from Meta.",
		sender: .user
	)
	
	/// Function to convert the message to JSON for chat parameters
	public func toJSON() -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let jsonData = try? encoder.encode(
			MessageSubset(message: self)
		)
		return String(data: jsonData!, encoding: .utf8)!
	}
	
	public struct MessageSubset: Codable {
		
		init(message: Message) {
			self.role = message.sender
			self.content = message.text
		}
		
		var role: Sender
		var content: String
		
	}
	
}
