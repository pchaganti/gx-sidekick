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
		guard let context: JSContext = JSContext() else {
			throw JSError.failedToInitContext
		}
		// Create log function
		var logString: String? = nil
		let logFunction: @convention(block) (String) -> Void = { string in
			logString = string
		}
		// Bind to context
		if let console = context.objectForKeyedSubscript("console") {
			console.setObject(logFunction, forKeyedSubscript: "log")
		}
		// Check for errors
		var exceptionMsg: String? = nil
		context.exceptionHandler = { context, exception in
			exceptionMsg = exception?.toString()
		}
		// Evaluate the JavaScript code
		if let result = context.evaluateScript(code) {
			// Throw error if JS string failed to evaluate
			if exceptionMsg != nil {
				throw JSError.exception(error: exceptionMsg!)
			}
			if let resultStr = result.toString() {
				// Throw error if empty and no log output
				if resultStr.isEmpty && logString == nil {
					throw JSError.exception(error: "Unknown error")
				} else if !resultStr.isEmpty && resultStr != "undefined" {
					return resultStr
				} else if let logString = logString {
					return logString
				} else if resultStr == "undefined" {
					throw JSError.exception(error: "undefined")
				}
			}
			throw JSError.couldNotObtainResult
		} else {
			// Throw error if JS string failed to evaluate
			if exceptionMsg != nil {
				throw JSError.exception(error: exceptionMsg!)
			}
			throw JSError.executionFailed
		}
	}
	
	/// Enum for possible errors during JavaScript execution
	public enum JSError: Error {
		case failedToInitContext
		case exception(error: String)
		case executionFailed
		case couldNotObtainResult
	}
	
}
