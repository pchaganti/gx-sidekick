//
//  AppDelegate.swift
//  Sidekick
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
	
	/// Function that runs after the app is initialized
	public func applicationDidFinishLaunching(_ aNotification: Notification) {
	}
	
	/// Function that runs before the app is terminated
	public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		// Remove non-persisted resources
		ProfileManager.shared.removeUnpersistedResources()
		return .terminateNow
	}
	
	/// Function to setup the app's dock menu
//	public func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
//		let dockMenu: NSMenu = NSMenu()
//		dockMenu.addItem(
//			withTitle: "Test",
//			action: #selector(DockMenuCommands.test(_:)),
//			keyEquivalent: ""
//		)
//		return dockMenu
//	}
	
}
