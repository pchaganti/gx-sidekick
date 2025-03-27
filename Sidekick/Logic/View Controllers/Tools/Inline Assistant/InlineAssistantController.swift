//
//  InlineAssistantController.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import AppKit
import Foundation
import SwiftUI

public class InlineAssistantController: ObservableObject {
	
	/// Static constant for the global `InlineAssistantController` object
	static public let shared: InlineAssistantController = .init()
	
	/// A `NSPanel` for the assistant's panel
	private var panel: NSPanel?
	
	/// A `Bool` representing if the assistant panel is being shown
	public var isShowing: Bool {
		return panel != nil
	}
	
	/// Function to toggle inline assistant
	@MainActor
	public func toggleInlineAssistant() {
		if self.isShowing {
			self.hideInlineAssistant()
		} else {
			self.showInlineAssistant()
		}
	}
	
	/// Function to show inline assistant window
	@MainActor
	private func showInlineAssistant() {
		// Get selected text
		guard let selectedText: String = Accessibility.shared.getSelectedText() else {
			// If no text is selected, show alert, then exit
			Dialogs.showAlert(
				title: String(localized: "No Text Selected"),
				message: String(localized: "Please select text before invoking Sidekick's Inline Writing Assistant")
			)
			return
		}
		// If no model is chosed, exit
		if Settings.showSetup {
			return
		}
		// Set window view
		let view: NSView = NSHostingView(
			rootView: InlineAssistantView(
				selectedText: selectedText
			)
		)
		// Init panel
		let panel: NSPanel = NSPanel.getOverlayPanel()
		view.translatesAutoresizingMaskIntoConstraints = false
		panel.contentView = view
		panel.minSize = view.fittingSize
		panel.backgroundColor = .clear
		// Get screen with pointer
		let mouseLocation: CGPoint = NSEvent.mouseLocation
		let screens: [NSScreen] = NSScreen.screens
		let screenWithMouse: NSScreen = screens.first(where: {
			NSMouseInRect(mouseLocation, $0.frame, false)
		}) ??  NSScreen.main!
		// Position screen
		panel.setPosition(
			vertical: .center,
			horizontal: .center,
			offset: CGSize(width: 0, height: 200),
			padding: 0,
			screen: screenWithMouse
		)
		panel.orderFront(nil)
		// Persist current window
		self.panel = panel
	}
	
	/// Function to hide inline assistant window
	private func hideInlineAssistant() {
		self.panel?.close()
		self.panel = nil
	}
	
}
