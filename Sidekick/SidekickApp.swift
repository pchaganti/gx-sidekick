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

@main
struct SidekickApp: App {
	
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	@StateObject private var downloadManager: DownloadManager = .shared
	@StateObject private var conversationManager: ConversationManager = .shared
	@StateObject private var profileManager: ProfileManager = .shared
	
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
		.environmentObject(downloadManager)
		.environmentObject(conversationManager)
		.environmentObject(profileManager)
		.commands {
			ConversationCommands.commands
			WindowCommands.commands
#if DEBUG
			DebugCommands.commands 
#endif
		}
    }
	
}
