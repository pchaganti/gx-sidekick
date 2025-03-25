//
//  ActiveApplicationInspector.swift
//  Sidekick
//
//  Created by John Bean on 3/24/25.
//

import ApplicationServices
import Cocoa
import Foundation

class ActiveApplicationInspector {
	
	enum InspectorError: Error {
		case noActiveApp
		case permissionDenied
		case invalidParentElement
		case accessibilityError(String)
	}
	
	/// Function to get the currently active application
	public static func getActiveApplication() throws -> AXUIElement {
		// Get foreground app
		guard let app = NSWorkspace.shared.frontmostApplication else {
			throw InspectorError.noActiveApp
		}
		let pid = app.processIdentifier
		let appRef = AXUIElementCreateApplication(pid)
		// Verify we can access the application
		var value: CFTypeRef?
		let result = AXUIElementCopyAttributeValue(appRef, kAXRoleAttribute as CFString, &value)
		if result != .success {
			throw InspectorError.accessibilityError("""
				Cannot access application '\(app.localizedName ?? "Unknown")'.
				Error code: \(result.rawValue)
				""")
		}
		return appRef
	}
	
	/// Function to get the focused window of the current application
	private static func getFocusedWindow(
		appRef: AXUIElement
	) throws -> AXUIElement {
		var windowRef: CFTypeRef?
		let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
		guard result == .success else {
			throw InspectorError.accessibilityError("Could not get focused window")
		}
		// Direct force cast is safe here since we checked result == .success
		return windowRef as! AXUIElement
	}
	
	/// Function to get the focused element in the app window
	private static func getFocusedElement(
		appRef: AXUIElement
	) throws -> AXUIElement {
		var focusedRef: CFTypeRef?
		let result = AXUIElementCopyAttributeValue(
			appRef,
			kAXFocusedUIElementAttribute as CFString,
			&focusedRef
		)
		guard result == .success else {
			throw InspectorError.accessibilityError("Could not get focused element")
		}
		// Direct force cast is safe here since we checked result == .success
		return focusedRef as! AXUIElement
	}
	
	/// Function to get all properties of an Accessibility UI element
	public static func getAllProperties(
		for element: AXUIElement
	) -> [String: Any] {
		var properties: [String: Any] = [:]
		var arrayRef: CFArray?
		// Get list of supported attributes
		guard AXUIElementCopyAttributeNames(element, &arrayRef) == .success,
			  let attributeNames = arrayRef as? [String] else {
			return properties
		}
		// Get value for each attribute
		for attrName in attributeNames {
			var valueRef: CFTypeRef?
			if AXUIElementCopyAttributeValue(element, attrName as CFString, &valueRef) == .success,
			   let value = valueRef {
				properties[attrName] = value
			}
		}
		return properties
	}
	
	/// Function to get the value of the currently focused UI element
	public static func getFocusedElementValue(
		for focusedUIElement: AXUIElement
	) throws -> String {
		var value: AnyObject?
		let valueResult = AXUIElementCopyAttributeValue(
			focusedUIElement,
			kAXValueAttribute as CFString,
			&value
		)
		if valueResult == .success, let textValue = value as? String {
			return textValue
		} else {
			throw InspectorError.accessibilityError(
				"Failed to get value from focused element"
			)
		}
	}
	
	/// Function to get the focused element in the foreground application
	public static func getFocusedElement() -> AXUIElement? {
		// Check accessibility permissions
		if !Accessibility.checkAccessibility() {
			return nil
		}
		// Get element properties
		guard let appRef = try? Self.getActiveApplication() else {
			return nil
		}
		let focusedElementRef = try? Self.getFocusedElement(
			appRef: appRef
		)
		return focusedElementRef
	}
	
	
	/// Function to get properties of the focused element in the foreground application
	public static func getFocusedElementProperties() throws -> [String: Any] {
		// Check accessibility permissions
		if !Accessibility.checkAccessibility() {
			throw InspectorError.permissionDenied
		}
		// Get element properties
		let appRef = try Self.getActiveApplication()
		let focusedElementRef = try Self.getFocusedElement(
			appRef: appRef
		)
		return Self.getAllProperties(for: focusedElementRef)
	}
	
	/// Function to get properties of the focused element in the foreground application
	public static func getFocusedElementText() throws -> String {
		// Check accessibility permissions
		if !Accessibility.checkAccessibility() {
			throw InspectorError.permissionDenied
		}
		// Get element properties
		let appRef = try Self.getActiveApplication()
		let focusedElementRef = try Self.getFocusedElement(
			appRef: appRef
		)
			return try Self.getFocusedElementValue(for: focusedElementRef)
	}
	
	/// Function to extract the editing location from an AXValue
	public static func getEditingLocation(
		from anyValue: Any?
	) -> Int? {
		guard let cfValue = anyValue else {
			print("Value is nil")
			return nil
		}
		// Convert it to CFTypeRef (AnyObject works too)
		let cfType = cfValue as AnyObject
		// Check if it's actually an AXValue type using CFGetTypeID
		if CFGetTypeID(cfType) != AXValueGetTypeID() {
			print("Value is not an AXValue")
			return nil
		}
		// Now it's safe to treat it as an AXValue
		let axValue = cfType as! AXValue
		// Verify the AXValue type is a CFRange
		let axValueType = AXValueGetType(axValue)
		guard axValueType == .cfRange else {
			print("AXValue is not a CFRange, it's \(axValueType.rawValue)")
			return nil
		}
		// Extract the CFRange
		var range = CFRange()
		if AXValueGetValue(axValue, .cfRange, &range) {
			return range.location
		} else {
			print("Failed to extract CFRange from AXValue")
			return nil
		}
	}
	
	public static func printFocusedElementFontInfo() {
		// Create a system-wide accessibility element.
		let systemWideElement = AXUIElementCreateSystemWide()
		// Try to get the currently focused element.
		var focusedElement: AnyObject?
		let result = AXUIElementCopyAttributeValue(systemWideElement,
												   kAXFocusedUIElementAttribute as CFString,
												   &focusedElement)
		guard result == .success, let focused = focusedElement else {
			print("Error: Could not retrieve the focused UI element.")
			return
		}
		// Convert the focused element to AXUIElement using unsafeBitCast.
		let element = unsafeBitCast(focused, to: AXUIElement.self)
		// Access the font attributes. Note that not all apps expose these.
		var fontFamilyValue: CFTypeRef?
		let familyResult = AXUIElementCopyAttributeValue(element,
														 "AXFontFamily" as CFString,
														 &fontFamilyValue)
		
		var fontSizeValue: CFTypeRef?
		let sizeResult = AXUIElementCopyAttributeValue(element,
													   "AXFontSize" as CFString,
													   &fontSizeValue)
		if familyResult == .success, sizeResult == .success,
		   let fontFamily = fontFamilyValue as? String,
		   let fontSize = fontSizeValue as? CGFloat {
			print("Font: \(fontFamily), Size: \(fontSize)")
		} else {
			print("Focused element does not expose font information.")
		}
	}
	
}
