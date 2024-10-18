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
			Button {
				for window in NSApplication.shared.windows {
					if window.isKeyWindow {
						window.toggleFullScreen(nil)
					}
				}
			} label: {
				Text("Enter Full Screen")
			}
			.keyboardShortcut("f", modifiers: [.control, .command])
		}
		
	}
	
}
