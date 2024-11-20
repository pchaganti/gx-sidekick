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
			name: String(localized: "Answer Question"),
			prompt: String(localized: "Answer the question below with a short response. Answer in the same language as the question below.")
		),
		Command(
			name: String(localized: "Elaborate"),
			prompt: String(localized: "Elaborate on the following content, providing additional insights, examples, detailed explanations, and related concepts. Dive deeper into the topic to offer a comprehensive understanding and explore various dimensions not covered in the original text. Respond in the same language as the original text.")
		),
		Command(
			name: String(localized: "Correct Grammar"),
			prompt: String(localized: "Correct grammar for the text below. Ensure all spelling, punctuation, and grammar are correct. Respond in the same language as the original text.")
		),
		Command(
			name: String(localized: "Concise"),
			prompt: String(localized: "Make this paragraph shorter while retaining the most important information, removing some details when needed. Respond in the same language as the original text.")
		),
		Command(
			name: String(localized: "Rewrite"),
			prompt: String(localized: "Rewrite the text below. Respond in the same language as the original text.")
		),
		Command(
			name: String(localized: "Simplify"),
			prompt: String(localized: "Simplify the text below for a general audience, removing techinical jargon and hard-to-grasp ideas. Respond in the same language as the original text.")
		)
	].sorted(by: \.name)
	
}
