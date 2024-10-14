//
//  WindowCommands.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import AppKit
import SwiftUI

@MainActor
public class WindowCommands {
	
	static var commands: some Commands {
		
		CommandGroup(after: CommandGroupPlacement.windowArrangement) {
			Button("Enter Full Screen") {
				for window in NSApplication.shared.windows {
					if window.isKeyWindow {
						window.toggleFullScreen(nil)
					}
				}
			}
			.keyboardShortcut("f", modifiers: [.control, .command])
		}
		
	}
	
}
