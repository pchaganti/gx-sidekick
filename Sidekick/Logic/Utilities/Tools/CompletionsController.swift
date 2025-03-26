//
//  CompletionsController.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import AppKit
import ApplicationServices
import AXSwift
import Carbon
import Foundation
import OSLog
import SwiftUI

public class CompletionsController: ObservableObject {
	
	/// A `Logger` object for the `Model` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: Model.self)
	)
	
	/// Initializes the ``CompletionsController`` object
	init() {
		// Assign variables
		self.completion = nil
		// Start server
		self.server = LlamaServer(
			modelUrl: InferenceSettings.completionsModelUrl,
			port: self.port
		)
		Task {
			try await self.server.startServer()
		}
		self.setupObservers()
	}
	
	/// Static constant for the global ``CompletionsController`` object
	static public let shared: CompletionsController = .init()
	
	/// The global key monitor
	private var monitors: [Any?] = []
	
	/// A `String` for the completion content
	@Published var completion: String? = nil {
		didSet {
			// If the completion is not blank, set shortcut
			ShortcutController.refreshCompletionsShortcuts(
				isEnabled: completion != nil
			)
		}
	}
	/// A list of `NSPanel` to display the content
	private var panels: [NSPanel] = []
	
	/// An `Observer` for accessibility events
	private var observer: Observer?
	
	/// A `LlamaServer` object for an instance of `llama-server`
	private var server: LlamaServer
	/// An `Int` representing the port on which the server responds
	private var port: Int = 9020
	
	/// Function to generate and display the next completion
	private func generateAndDisplayCompletion() async {
		// Check app
		if let currentId: String = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
		   Settings.completionsExcludedApps.contains(currentId) {
			return
		}
		// Get rid of current displayed completions
		self.reset()
		// Fetch text
		guard var text = fetchText() else {
			return
		}
		// Check if text is long enough
		let lengthThreshold: Int = 10
		guard text.count >= lengthThreshold else {
			return
		}
		// Append instructions
		text = """
My name is \(Settings.username). I usually write in English and Chinese.

Write in a friendly, professional and empathetic voice. Keep your sentences short, concise and readable.

\(text)
"""
		// Generate
		guard let tokens: [LlamaServer.Token] = await self.server.getCompletion(
			text: text,
			maxTokenNumber: 3
		) else {
			return
		}
		// Filter tokens
		let confidenceThreshold: Double = -0.8
		let specialCharacterThreshold: Double = 0.7
		var failCount: Int = tokens.count
		for token in tokens {
			// Check
			let logprobPass: Bool = token.logprob > confidenceThreshold
			let charPass: Bool = token.token.nonSpecialCharactersPercent() > specialCharacterThreshold
			// If they pass, increment count by minus one
			if logprobPass || charPass {
				failCount -= 1
			}
		}
		// Put content together
		let content: String = tokens.map({ token in
			return token.token
		}).dropLast(failCount).joined()
		// Check length of content
		guard content.count > 3 else { return }
		self.completion = content
		// Display
		self.displayCompletion(
			text: content
		)
	}
	
	/// Function to generate the completion text
	private func fetchText() -> String? {
		// Get the text in the focused field
		guard var text = try? ActiveApplicationInspector.getFocusedElementText() else {
			return nil
		}
		// Get the focused field's size
		if let focusedElementRef = ActiveApplicationInspector.getFocusedElement() {
			let properties: [String: Any] = ActiveApplicationInspector.getAllProperties(
				for: focusedElementRef
			)
			let markedRange = properties["AXSelectedTextRange"]
			if let location = ActiveApplicationInspector.getEditingLocation(
				from: markedRange
			) {
				text = String(text.dropLast(max(text.count - location, 0)))
			}
		}
		return text
	}
	
	/// Function to get the rect of the focused field
	private func getRect() -> CGRect? {
		// Get the focused field's size and position
		if let focusedElementRef = ActiveApplicationInspector.getFocusedElement() {
			let properties: [String: Any] = ActiveApplicationInspector.getAllProperties(
				for: focusedElementRef
			)
			// Retrieve the "AXFrame" property using a forced cast.
			if let axFrame = properties["AXFrame"] {
				let axFrameValue = axFrame as! AXValue
				var rect = CGRect.zero
				// Use AXValueGetValue to extract the CGRect.
				if AXValueGetValue(axFrameValue, .cgRect, &rect) {
					return rect
				}
			}
		}
		return nil
	}
	
	/// Function to display the generated completion
	private func displayCompletion(
		text: String
	) {
		// Get the focused field's size and position
		guard let rect: CGRect = self.getRect() else {
			print("Failed to get focused field rect")
			return
		}
		let size: CGSize = rect.size
		let position: CGPoint = rect.origin
		// Get text caret position
		let cursorBounds = CursorBounds()
		let topLeading: Origin? = cursorBounds.getOrigin(
			xCorner: .minX,
			yCorner: .minY
		)
		let bottomTrailing: Origin? = cursorBounds.getOrigin(
			xCorner: .maxX,
			yCorner: .maxY
		)
		guard let topLeading, let bottomTrailing else {
			return
		}
		// Put together same row rect
		let height: CGFloat = topLeading.NSPoint.y - bottomTrailing.NSPoint.y
		let sameRowRect: CGRect = CGRect(
			origin: NSPoint(
				x: bottomTrailing.NSPoint.x,
				y: bottomTrailing.NSPoint.y - height
			),
			size: CGSize(
				width: (position.x + size.width) - topLeading.NSPoint.x,
				height: height
			)
		)
		// Reset and create panels
		self.removePanels()
		Task { @MainActor in
			let panel = self.createFloatingPanel(
				with: sameRowRect,
				text: text
			)
			self.panels.append(panel)
		}
	}
	
	func createFloatingPanel(
		with rect: CGRect,
		text: String
	) -> NSPanel {
		// Create an NSPanel with the borderless style
		let panel = NSPanel(
			contentRect: rect,
			styleMask: [.nonactivatingPanel, .borderless],
			backing: .buffered,
			defer: false
		)
		// Set the panel to be non-activating (clicking on the panel does not steal focus from the app)
		panel.isFloatingPanel = true
		// Ensure the panel appears above other apps by setting a high window level
		panel.level = .modalPanel
		// Allow the panel to appear on all Spaces
		panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
		// Set the background to clear
		panel.backgroundColor = NSColor.clear
		// Set text view
		let textField = NSTextField(labelWithString: text)
		textField.frame = panel.contentView?.bounds ?? rect
		textField.alignment = .left
		textField.font = NSFont.systemFont(ofSize: panel.frame.height * 0.8)
		textField.textColor = .textColor.withAlphaComponent(0.5)
		textField.backgroundColor = .clear
		textField.autoresizingMask = [.width, .height]
		panel.contentView = textField
		// Remove shadow
		panel.hasShadow = false
		// Display the panel
		panel.orderFrontRegardless()
		return panel
	}
	
	/// Function to set the `AXObserver`
	@objc private func refreshObserver(note: NSNotification) {
		self.reset()
		// Refresh Observer
		self.refreshObserver()
	}
	
	/// Function to reset the completion
	private func reset() {
		self.removePanels()
		// Reset completion
		self.completion = nil
	}
	
	/// Function to remove all panels
	private func removePanels() {
		// Remove panels
		Task { @MainActor in
			self.panels.forEach { panel in
				panel.close()
			}
			self.panels.removeAll()
		}
	}
	
	/// Function to setup event observers
	private func setupObservers() {
		// Setup NSWorkspace notifications
		[
			NSWorkspace.didDeactivateApplicationNotification: #selector(refreshObserver(note:)),
			NSWorkspace.didLaunchApplicationNotification: #selector(refreshObserver(note:)),
			NSWorkspace.didTerminateApplicationNotification: #selector(refreshObserver(note:)),
			NSWorkspace.activeSpaceDidChangeNotification: #selector(refreshObserver(note:))
		].forEach { notification, sel in
			NSWorkspace.shared.notificationCenter.addObserver(
				self,
				selector: sel,
				name: notification,
				object: nil
			)
		}
		// Start watcher
		let keyMonitor = NSEvent.addGlobalMonitorForEvents(
			matching: .keyUp
		) { _ in
			// Generate and show completion
			Task {
				await self.generateAndDisplayCompletion()
			}
		}
		let scrollMonitor = NSEvent.addGlobalMonitorForEvents(
			matching: .scrollWheel
		) { _ in
			// Reset
			self.reset()
		}
		let clickMonitor = NSEvent.addGlobalMonitorForEvents(
			matching: .leftMouseDown
		) { _ in
			// Reset
			self.reset()
		}
		self.monitors += [
			keyMonitor,
			scrollMonitor,
			clickMonitor
		]
	}
	
	/// Function to refresh the `Observer`
	private func refreshObserver() {
		// Get active app
		guard let appId = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
			print("No frontmost application")
			return
		}
		if let app: Application = Application(forProcessID: appId) {
			// Create and add observers
			self.observer = app.createObserver {
				(observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in
				self.reset()
			}
			let observedEvents: [AXNotification] = [
				.focusedWindowChanged,
				.focusedUIElementChanged,
				.windowMoved
			]
			for observedEvent in observedEvents {
				try? self.observer?.addNotification(
					observedEvent,
					forElement: app
				)
			}
		}
	}
	
}

extension NSAccessibility.Notification {
	var name: Notification.Name { .init(self.rawValue) }
}
