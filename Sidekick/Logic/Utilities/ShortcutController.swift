//
//  ShortcutController.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import KeyboardShortcuts

public class ShortcutController {
	
	/// Static constant for the global ``ShortcutController`` object
	static public let shared: ShortcutController = .init()
	
	/// A `Bool` indicating if completion shortcuts are registered
	public var completionsShortcutsEnabled: Bool = true
	
	/// Function to setup global keyboard shortcuts
	@MainActor
	public static func setup() {
		ShortcutController.setDefaultShortcuts()
		ShortcutController.setupShortcut(
			name: .toggleInlineAssistant
		) {
			InlineAssistantController.shared.toggleInlineAssistant()
		}
		ShortcutController.setupShortcut(
			name: .acceptNextToken
		) {
			CompletionsController.shared.typeNextWord()
		}
		ShortcutController.setupShortcut(
			name: .acceptAllTokens
		) {
			CompletionsController.shared.typeCompletion()
		}
		// Disable completions shortcuts until a suggestion is ready
		ShortcutController.refreshCompletionsShortcuts(
			isEnabled: false
		)
	}
	
	/// Function to refresh completions shortcuts
	@MainActor
	public static func refreshCompletionsShortcuts(
		isEnabled: Bool? = nil
	) {
		let shortcuts: [KeyboardShortcuts.Name] = [
			.acceptNextToken,
			.acceptAllTokens
		]
		let isEnabled: Bool = isEnabled ?? (Settings.useCompletions && Settings.didSetUpCompletions)
		// If no change, exit
		if isEnabled == Self.shared.completionsShortcutsEnabled {
			return
		}
		// If completions are not enabled or ready, or if specified
		if !isEnabled {
			// Check if enabled
			KeyboardShortcuts.disable(shortcuts)
		} else {
			// Else, make sure they are active
			KeyboardShortcuts.enable(shortcuts)
		}
		// Log state
		Self.shared.completionsShortcutsEnabled = isEnabled
	}
	
	/// Function to set default keyboard shortcuts
	private static func setDefaultShortcuts() {
		// Set default shortcuts if no value
		if KeyboardShortcuts.getShortcut(
			for: .toggleInlineAssistant
		) == nil {
			// Set to "Command + Control + i"
			KeyboardShortcuts.setShortcut(
				.init(.i, modifiers: [.command, .control]),
				for: .toggleInlineAssistant
			)
		}
		if KeyboardShortcuts.getShortcut(
			for: .acceptNextToken
		) == nil {
			// Set to "Tab"
			KeyboardShortcuts.setShortcut(
				.init(.tab),
				for: .acceptNextToken
			)
		}
		if KeyboardShortcuts.getShortcut(
			for: .acceptAllTokens
		) == nil {
			// Set to "Shift + Tab"
			KeyboardShortcuts.setShortcut(
				.init(.tab, modifiers: .shift),
				for: .acceptAllTokens
			)
		}
	}
	
	/// Function to setup keyboard shortcuts
	private static func setupShortcut(
		name: KeyboardShortcuts.Name,
		show: @escaping () -> Void
	) {
		KeyboardShortcuts.onKeyDown(
			for: name
		) {
			show()
		}
	}
	
}
