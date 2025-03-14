//
//  SidekickApp.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import AppKit
import Foundation
import FSKit_macOS
import SwiftUI
import Sparkle

@main
struct SidekickApp: App {
	
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	@StateObject private var appState: AppState = .shared
	@StateObject private var downloadManager: DownloadManager = .shared
	@StateObject private var conversationManager: ConversationManager = .shared
	@StateObject private var expertManager: ExpertManager = .shared
	@StateObject private var commandManager: CommandManager = .shared
	
	@StateObject private var lengthyTasksController: LengthyTasksController = .shared
	
	// Updater object for Sparkle
	private let updaterController: SPUStandardUpdaterController = .init(
		startingUpdater: true,
		updaterDelegate: nil,
		userDriverDelegate: nil
	)
	
	var body: some Scene {
		
		// Main window
		WindowGroup {
			ContentView()
				.environmentObject(appState)
				.environmentObject(downloadManager)
				.environmentObject(conversationManager)
				.environmentObject(expertManager)
				.environmentObject(lengthyTasksController)
				.applyWindowMaterial()
		}
		.windowToolbarStyle(.unified)
		.commands {
			ConversationCommands.commands
			ConversationCommands.expertCommands
			WindowCommands.commands
			DebugCommands.commands
			HelpCommands.commands
			CommandGroup(after: .appInfo) {
				CheckForUpdatesView(updater: updaterController.updater)
			}
		}
		
		// Window for Tool: Models
		SwiftUI.Window("Models", id: "models") {
			ModelExplorerView()
		}
		
		// Window for Tool: Diagrammer
		SwiftUI.Window("Diagrammer", id: "diagrammer") {
			DiagrammerView()
		}
		
		// Window for Tool: Slide Studio
		SwiftUI.Window("Slide Studio", id: "slideStudio") {
			SlideStudioView()
		}
		
		// Window for Tool: Detector
		SwiftUI.Window("Detector", id: "detector") {
			DetectorView()
		}
		
		// Settings window
		SwiftUI.Settings {
			SettingsView()
				.environmentObject(commandManager)
		}
		
	}
	
}
