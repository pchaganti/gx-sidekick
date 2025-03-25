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
		ShortcutController.setup()
//		do {
//			let draft: String = try ActiveApplicationInspector.getFocusedElementText()
//			let draftLength: Int = draft.count
//			print("Draft length: \(draftLength)")
//			let properties = try ActiveApplicationInspector.getFocusedElementProperties()
//			let markedRange = properties["AXSelectedTextRange"]
//			if let location = ActiveApplicationInspector.getEditingLocation(
//				from: markedRange
//			) {
//				print("Editing location: \(location)")
//			}
//		} catch {
//			print("Error: \(error)")
//		}
	}
	
	/// Function that runs before the app is terminated
	public func applicationShouldTerminate(
		_ sender: NSApplication
	) -> NSApplication.TerminateReply {
		// Stop server
		Task {
			await Model.shared.llama.stopServer()
		}
		// Remove stale sources
		SourcesManager.shared.removeStaleSources()
		// Remove non-persisted resources
		ExpertManager.shared.removeUnpersistedResources()
		return .terminateNow
	}
	
}
