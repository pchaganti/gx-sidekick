//
//  ShortcutController.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import KeyboardShortcuts

public class ShortcutController {
	
	/// Function to set default keyboard shortcuts
	public static func setDefaultShortcuts() {
		// Set default shortcut if no value
		if KeyboardShortcuts.getShortcut(
			for: .toggleInlineAssistant
		) == nil {
			// Set to "Function + t"
			KeyboardShortcuts.setShortcut(
				.init(.i, modifiers: [.command, .control]),
				for: .toggleInlineAssistant
			)
		}
	}
	
	/// Function to setup keyboard shortcuts
	public static func setupShortcut(
		name: KeyboardShortcuts.Name,
		show: @escaping () -> Void
	) {
		KeyboardShortcuts.onKeyDown(
			for: name
		) {
			// Display annotation windows
			show()
		}
	}
	
}
