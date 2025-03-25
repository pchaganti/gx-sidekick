//
//  ShortcutController.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import KeyboardShortcuts

public class ShortcutController {
	
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
			print("Accept next token")
		}
		ShortcutController.setupShortcut(
			name: .acceptAllTokens
		) {
			print("Accept all tokens")
		}
		// Refresh completions shortcuts status
		ShortcutController.refreshCompletionsShortcuts()
	}
	
	/// Function to refresh completions shortcuts
	public static func refreshCompletionsShortcuts() {
		let shortcuts: [KeyboardShortcuts.Name] = [
			.acceptNextToken,
			.acceptAllTokens
		]
		// If completions are not enabled or ready
		if !Settings.useCompletions || !Settings.didSetUpCompletions {
			ShortcutController.disableShortcuts(
				names: shortcuts
			)
		} else {
			// Else, make sure they are active
			ShortcutController.enableShortcuts(
				names: shortcuts
			)
		}
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
			// Set to "Tab"
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
	
	/// Function to disable keyboard shortcuts
	public static func disableShortcuts(
		names: [KeyboardShortcuts.Name]
	) {
		KeyboardShortcuts.disable(names)
	}
	
	/// Function to enable keyboard shortcuts
	public static func enableShortcuts(
		names: [KeyboardShortcuts.Name]
	) {
		KeyboardShortcuts.enable(names)
	}
	
}
