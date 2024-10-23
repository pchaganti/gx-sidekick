//
//  QuickPrompt.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import Foundation

struct QuickPrompt: Identifiable {
	
	/// Conform to identifiable
	let id: UUID = UUID()
	
	/// String containing the title of the prompt
	var title: String
	/// String containing the rest of the prompt
	var rest: String
	
	/// Computed property that returns the full prompt
	var text: String {
		return "\(self.title) \(self.rest)"
	}
	
	/// Static constant containing all quick prompts
	static var quickPrompts = [
		QuickPrompt(
			title: "Hi there!",
			rest: "Please introduce yourself."
		),
		QuickPrompt(
			title: "Write a bullet summary",
			rest: "of the leadup and impact of the French Revolution."
		),
		QuickPrompt(
			title: "How do you",
			rest: "know when a steak is done?"
		),
		QuickPrompt(
			title: "Write a recipe",
			rest: "for the perfect martini."
		),
		QuickPrompt(
			title: "Teach me how",
			rest: "to make a pizza in 10 simple steps, with timings and portions."
		),
		QuickPrompt(
			title: "Write a Linux 1-liner",
			rest: "to count lines of code in a directory."
		),
		QuickPrompt(
			title: "Can you tell me",
			rest: "about the gate all around transistor?"
		),
		QuickPrompt(
			title: "How does",
			rest: "cache speed up processing?"
		),
		QuickPrompt(
			title: "Write an email",
			rest: "asking a colleague for a quick status update."
		)
	]
	
}
