//
//  AppDelegate.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import FSKit_macOS
import OSLog
import SwiftUI
import TipKit

/// The app's delegate which handles life cycle events
public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	
	/// A object of type  `InlineAssistantController` controller
	let inlineAssistantController: InlineAssistantController = .shared
	
	/// Function that runs after the app is initialized
	public func applicationDidFinishLaunching(
		_ notification: Notification
	) {
		// Relocate legacy resources if setup finished
		if Settings.setupComplete {
			ContainerRefactorer.refactor()
		}
		// Configure Tip's data container
		try? Tips.configure(
			[
				.datastoreLocation(.applicationDefault),
				.displayFrequency(.daily)
			]
		)
		// Configure keyboard shortcuts
		ShortcutController.setDefaultShortcuts()
		ShortcutController.setupShortcut(
			name: .toggleInlineAssistant
		) {
			self.inlineAssistantController.toggleInlineAssistant()
		}
	}
	
	/// Function that runs before the app is terminated
	public func applicationShouldTerminate(
		_ sender: NSApplication
	) -> NSApplication.TerminateReply {
		// Remove stale sources
		SourcesManager.shared.removeStaleSources()
		// Remove non-persisted resources
		ExpertManager.shared.removeUnpersistedResources()
		return .terminateNow
	}
	
}
