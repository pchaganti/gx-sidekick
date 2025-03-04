//
//  JavaScriptRunner.swift
//  Sidekick
//
//  Created by John Bean on 3/4/25.
//

import Foundation
import JavaScriptCore

/// A class to execute JavaScript
public class JavaScriptRunner {
	
	/// Function to execute JavaScript and return the result
	/// - Parameter code: The JavaScript code to be run
	/// - Returns: The result produced from the JavaScript code
	public static func executeJavaScript(
		_ code: String
	) throws -> String {
		// Create a JavaScript context
		let context = JSContext()
		// Check for errors
		context?.exceptionHandler = { context, exception in
			print("JavaScript Error: \(exception?.toString() ?? "Unknown error")")
		}
		// Evaluate the JavaScript code
		if let result = context?.evaluateScript(code) {
			if let resultStr = result.toString() {
				return resultStr
			}
			throw JSError.couldNotObtainResult
		} else {
			throw JSError.executionFailed
		}
	}
	
	/// Enum for possible errors during JavaScript execution
	public enum JSError: Error {
		case executionFailed
		case couldNotObtainResult
	}
	
}
