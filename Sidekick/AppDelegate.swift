//
//  AppDelegate.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import SwiftUI
import TipKit

public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	
	/// Function that runs after the app is initialized
	public func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Configure Tip's data container
		try? Tips.configure(
			[
				.datastoreLocation(.applicationDefault),
				.displayFrequency(.daily)
			]
		)
		// Call function to check model reccomendations
		DefaultModels.checkModelRecommendations()
	}
	
	/// Function that runs before the app is terminated
	public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		// Remove stale sources
		SourcesManager.shared.removeStaleSources()
		// Remove non-persisted resources
		ProfileManager.shared.removeUnpersistedResources()
		return .terminateNow
	}
	
}
