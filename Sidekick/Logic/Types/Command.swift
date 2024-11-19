//
//  Command.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation

public struct Command: Identifiable, Codable {
	
	public var id: UUID = UUID()
	
	public var name: String
	public var prompt: String

	public static let defaults: [Command] = [
		Command(
			name: "Answer Question",
			prompt: "Answer the question below with a short response:"
		),
		Command(
			name: "Elaborate",
			prompt: "Elaborate on the following content, providing additional insights, examples, detailed explanations, and related concepts. Dive deeper into the topic to offer a comprehensive understanding and explore various dimensions not covered in the original text."
		),
		Command(
			name: "Correct Grammar",
			prompt: "Correct grammar for the text below:"
		),
		Command(
			name: "Concise",
			prompt: "Make this paragraph shorter while retaining the most important information, removing some details when needed."
		),
		Command(
			name: "Rewrite",
			prompt: "Rewrite the text below:"
		),
		Command(
			name: "Simplify",
			prompt: "Simplify the text below for a general audience, removing techinical jargon and hard-to-grasp ideas."
		)
	].sorted(by: \.name)
	
}
