//
//  QuickPrompt.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import Foundation
import SwiftUI

public struct QuickPrompt: Identifiable {
	
	public init(
		text: String,
		description: String,
		icon: String,
		color: Color
	) {
		self.text = text
		self.description = description
		self.icon = icon
		self.color = color
	}
	
	/// Conform to identifiable
	public let id: UUID = UUID()
	
	/// String containing the text of the prompt
	public var text: String
	
	/// String containing a short description of the prompt
	private var description: String
	/// The identifier used for the prompt's icon's image
	private var icon: String
	/// The color used for the prompt's icon's image
	private var color: Color = Color.secondary
	
	/// This prompt's label
	var label: some View {
		HStack(
			alignment: .center
		) {
			Image(systemName: icon)
				.symbolRenderingMode(.multicolor)
				.foregroundStyle(color)
			Text(description)
				.foregroundStyle(.secondary)
		}
	}
	
	/// Static constant containing all quick prompts
	static let quickPrompts = [
		QuickPrompt(
			text: String(localized: "Hi there! Please introduce yourself."),
			description: String(localized: "Say hi"),
			icon: "hand.wave.fill",
			color: .yellow
		),
		QuickPrompt(
			text: String(localized: "Teach me how to "),
			description: String(localized: "Teach me"),
			icon: "graduationcap.fill",
			color: .blue
		),
		QuickPrompt(
			text: String(localized: "Paraphrase the text below:\n\n\"\""),
			description: String(localized: "Paraphrase"),
			icon: "text.chevron.left",
			color: .teal
		),
		QuickPrompt(
			text: String(localized: "Rewrite the text below into bullet points:\n\n\"\""),
			description: String(localized: "Make bullet points"),
			icon: "list.bullet.rectangle.portrait.fill",
			color: .red
		),
		QuickPrompt(
			text: String(localized: "Summarize the text below:\n\n\"\""),
			description: String(localized: "Summarize"),
			icon: "doc.plaintext.fill",
			color: .orange
		),
		QuickPrompt(
			text: String(localized: "Explain how "),
			description: String(localized: "Explain how"),
			icon: "person.fill.questionmark",
			color: .green
		),
		QuickPrompt(
			text: String(localized: "Brainstorm ideas for "),
			description: String(localized: "Brainstorm"),
			icon: "brain.fill",
			color: .pink
		),
		QuickPrompt(
			text: String(localized: "Write an email to "),
			description: String(localized: "Write email"),
			icon: "envelope.fill",
			color: .cyan
		),
		QuickPrompt(
			text: String(localized: "Write a Unix command to "),
			description: String(localized: "Write a command"),
			icon: {
				if #available (macOS 15, *) {
					return "apple.terminal.fill"
				}
				return "terminal.fill"
			}(),
			color: .purple
		)
	]
	
}
