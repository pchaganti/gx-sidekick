//
//  Accessibility.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

/// A class to abstract use of macOS's Accessibility API
public class Accessibility {
	
	/// The shared singleton ``Accessibility`` object
	@MainActor public static let shared = Accessibility()
	
	/// Check if Sidekick has the right permissions
	public func checkAccessibility() -> Bool {
		let checkOptionPrompt: String = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
		let options = [checkOptionPrompt: false]
		let isTrusted: Bool = AXIsProcessTrustedWithOptions(
			options as CFDictionary
		)
		return isTrusted
	}
	
	/// Function to get the currently selected text
	public func getSelectedText() -> String? {
		// Try getting text via Accessibility API
		if let text = getSelectedTextAX(), text.count > 1  {
			return text
		}
		// Try getting text via copy
		return getSelectedTextViaCopy()
	}
	
	/// Function to get the selected text via the accessibility API
	private func getSelectedTextAX() -> String? {
		let systemWideElement = AXUIElementCreateSystemWide()
		
		var focusedApp: AnyObject?
		var error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
		guard error == .success, let focusedAppElement = focusedApp as! AXUIElement? else { return nil }
		
		var focusedUIElement: AnyObject?
		error = AXUIElementCopyAttributeValue(focusedAppElement, kAXFocusedUIElementAttribute as CFString, &focusedUIElement)
		guard error == .success, let focusedElement = focusedUIElement as! AXUIElement? else { return nil }
		
		var selectedTextValue: AnyObject?
		error = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
		guard error == .success, let selectedText = selectedTextValue as? String else { return nil }
		
		return selectedText
	}
	
	/// Function to get the selected text via a key press
	/// - Parameter retryAttempts: The number of copy attempts before abortion
	/// - Returns: The selected text in the foreground app
	private func getSelectedTextViaCopy(retryAttempts: Int = 3) -> String? {
		// Reset variables
		let pasteboard = NSPasteboard.general
		let originalContents = pasteboard.pasteboardItems?.compactMap { $0.string(forType: .string) } ?? []
		pasteboard.clearContents()
		var attempts = 0
		var newContent: String?
		
		while attempts < retryAttempts && newContent == nil {
			self.simulateCopyKeyPress()
			usleep(100000)
			
			newContent = pasteboard.string(forType: .string)
			if let newContent = newContent, !newContent.isEmpty {
				break
			} else {
				newContent = nil
			}
			attempts += 1
		}
		
		if newContent == nil {
			pasteboard.clearContents()
			for item in originalContents {
				pasteboard.setString(item, forType: .string)
			}
		}
		
		return newContent
	}
	
	/// Function to send the `Command + C` key press
	private func simulateCopyKeyPress() {
		let source = CGEventSource(stateID: .hidSystemState)
		// Define the virtual keycode for 'C' and the command modifier
		let commandKey = CGEventFlags.maskCommand.rawValue
		let cKeyCode = CGKeyCode(8)  // Virtual keycode for 'C'
		// Create and post a key down event
		if let commandCDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true) {
			commandCDown.flags = CGEventFlags(rawValue: commandKey)
			commandCDown.post(tap: .cghidEventTap)
		}
		// Create and post a key up event
		if let commandCUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false) {
			commandCUp.flags = CGEventFlags(rawValue: commandKey)
			commandCUp.post(tap: .cghidEventTap)
		}
	}
	
	/// Function to automatically type out text into an app
	/// - Parameter string: The string typed into the app in the foreground
	public func simulateTyping(
		for string: String
	) {
		let source = CGEventSource(stateID: .combinedSessionState)
		let utf16Chars = Array(string.utf16)
		// Type characters one by one
		utf16Chars.forEach { uniChar in
			var uniChar = uniChar
			if uniChar == 0x000A {
				
				if let shiftDown = CGEvent(
					keyboardEventSource: source,
					virtualKey: CGKeyCode(0x38),
					keyDown: true
				) {
					shiftDown.post(tap: .cghidEventTap)
				}
				
				// Simulate pressing and releasing the Return key
				if let eventDown = CGEvent(
					keyboardEventSource: source,
					virtualKey: CGKeyCode(0x24),
					keyDown: true
				),
				   let eventUp = CGEvent(
					keyboardEventSource: source,
					virtualKey: CGKeyCode(0x24),
					keyDown: false
				   ) {
					eventDown.post(tap: .cghidEventTap)
					Thread.sleep(forTimeInterval: 0.005)
					eventUp.post(tap: .cghidEventTap)
				}
				
				// Simulate releasing the Shift key
				if let shiftUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(0x38), keyDown: false) {
					shiftUp.post(tap: .cghidEventTap)
				}
				
			} else {
				// Handle other characters as before
				if let eventDown = CGEvent(
					keyboardEventSource: source,
					virtualKey: 0,
					keyDown: true
				),
				   let eventUp = CGEvent(
					keyboardEventSource: source,
					virtualKey: 0,
					keyDown: false
				   ) {
					eventDown.keyboardSetUnicodeString(
						stringLength: 1,
						unicodeString: &uniChar
					)
					eventUp.keyboardSetUnicodeString(
						stringLength: 1,
						unicodeString: &uniChar
					)
					eventDown.post(tap: .cghidEventTap)
					Thread.sleep(forTimeInterval: 0.005)
					eventUp.post(tap: .cghidEventTap)
				}
			}
		}
	}
	
	/// Function to automatically paste text into an app
	public static func simulatePasteCommand() {
		// Send key down event
		let commandKey = CGEventFlags.maskCommand.rawValue
		let vKeyCode = 0x09
		let source = CGEventSource(stateID: .hidSystemState)
		if let commandVDown = CGEvent(
			keyboardEventSource: source,
			virtualKey: CGKeyCode(vKeyCode),
			keyDown: true
		) {
			commandVDown.flags = CGEventFlags(rawValue: commandKey)
			commandVDown.post(tap: .cghidEventTap)
		}
		// Wait for app to respond
		usleep(50000)
		// Send key up event
		if let commandVUp = CGEvent(
			keyboardEventSource: source,
			virtualKey: CGKeyCode(vKeyCode),
			keyDown: false
		) {
			commandVUp.flags = CGEventFlags(
				rawValue: commandKey
			)
			commandVUp.post(tap: .cghidEventTap)
		}
	}
	
}
