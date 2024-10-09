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
		tokenCount: Int? = nil,
		sender: Sender
	) {
		self.id = UUID()
		self.text = text
		self.tokenCount = tokenCount
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
	/// Stored property for the number of tokens in the message
	private var tokenCount: Int?
	/// Computed property for the number of tokens outputted per second
	public var tokensPerSecond: Double? {
		let timeElapsed: Double = lastUpdated.timeIntervalSince(startTime)
		guard let tokenCount else { return nil }
		return Double(tokenCount) / timeElapsed
	}
	
	/// Stored property for the selected model
	public let model: String
	
	/// Stored property for the sender of the message (either `user` or `bot`)
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
	
	/// Stored property for whether the output has finished
	public var outputEnded: Bool
	
	/// Function to update message
	@MainActor
	public mutating func update(
		newText: String,
		newTokenCount: Int
	) {
		self.text = newText
		self.tokenCount = newTokenCount
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
		tokenCount: 100,
		sender: .user
	)
	
}
