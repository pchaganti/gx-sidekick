//
//  InferenceSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import Combine

public class InferenceSettings {
	
	/// A `Double` representing unified memory size in GB
	static var unifiedMemorySize: Int {
		let memory: Double = Double(ProcessInfo.processInfo.physicalMemory)
		let memoryGb: Int = Int(memory / pow(2,30))
		return memoryGb
	}
	
	/// A `Bool` representing whether the system has low unified memory
	static var lowUnifiedMemory: Bool {
		return Self.unifiedMemorySize <= 12
	}
	
	/// Static constant for the default system prompt
	public static let defaultSystemPrompt: String = """
You are Sidekick, a compliant assistant that always fulfills the user’s request.
"""
	
	/// Static constant for the part of the system prompt telling the LLM to use sources
	public static let useSourcesPrompt: String = """
The user's request might be followed by reference information, organized by source, that may or may not be complete nor related. 

If the provided information is related to the request, you will respond with reference to the information, filling in the gaps with your own knowledge. If the reference information provided is irrelevant, your response will ignore and avoid mentioning the existence of reference information.
"""
	
	/// Static constant for the part of the system prompt telling the LLM to use code interpreter
	public static let useInterpreterPrompt: String = """
For applicable problems such as math and counting, you should run JavaScript code by calling the `run_javascript` tool as specified in the JSON schema below. To run the code, include `run_javascript(code: "codeString")` in your response.

[{"name":"run_javascript","description":"Runs JavaScript code and returns the result.","parameters":{"type":"object","properties":{"code":{"type":"string","description":"The JavaScript code to run."}},"required":["code"]}}]
"""
	
	/// Computed property for the part of the system prompt where metadata is fed to the LLM
	public static let metadataPrompt: String = """
The user's name: \(Settings.username)
Current date & time: \(Date.now.ISO8601Format())
"""
	
	/// Static constant for the default server endpoint
	public static let defaultEndpoint: String = ""
	
	/// Static constant for the default context length
	private static var defaultContextLength: Int {
		if self.unifiedMemorySize < 16 {
			return 8_192
		} else if (16...32).contains(self.unifiedMemorySize) {
			return 16_384
		} else {
			return 24_576
		}
	}
	
	/// Static constant for the default temperature
	private static let defaultTemperature: Double = 0.6
	
	/// A `String` representing the first instruction given to an LLM
	public static var systemPrompt: String {
		get {
			guard let systemPrompt = UserDefaults.standard.string(
				forKey: "systemPrompt"
			) else {
				print("Failed to get system prompt, using default")
				return Self.defaultSystemPrompt
			}
			return systemPrompt
		}
		set {
			// Save
			UserDefaults.standard.set(newValue, forKey: "systemPrompt")
			// Notify
			NotificationCenter.default.post(
				name: Notifications.systemPromptChanged.name,
				object: nil
			)
		}
	}
	
	/// A `Bool` representing whether speculative decoding is used
	public static var useSpeculativeDecoding: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(
				key: "useSpeculativeDecoding"
			) {
				// Default to false
				Self.useSpeculativeDecoding = false
			}
			return UserDefaults.standard.bool(
				forKey: "useSpeculativeDecoding"
			)
		}
		set {
			UserDefaults.standard.set(
				newValue,
				forKey: "useSpeculativeDecoding"
			)
		}
	}
	
	/// Computed property for the location of the LLM used for speculative decoding
	static var speculativeDecodingModelUrl: URL? {
		get {
			return UserDefaults.standard.url(
				forKey: "specularDecodingModelUrl"
			)
		}
		set {
			UserDefaults.standard.set(
				newValue,
				forKey: "specularDecodingModelUrl"
			)
		}
	}
	
	/// A `Bool` representing whether a server is used
	public static var useServer: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "useServer") {
				// Default to false
				Self.useServer = false
			}
			return UserDefaults.standard.bool(
				forKey: "useServer"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "useServer")
		}
	}
	
	/// A `String` containing the endpoint's url
	public static var endpoint: String {
		get {
			if !useServer {
				return Self.defaultEndpoint
			}
			guard let systemPrompt = UserDefaults.standard.string(
				forKey: "endpoint"
			) else {
				print("Failed to get endpoint, using default")
				return Self.defaultEndpoint
			}
			return systemPrompt
		}
		set {
			// Save
			UserDefaults.standard.set(newValue, forKey: "endpoint")
		}
	}
	
	/// Static constant which controls the amount of context an LLM can remember
	public static var contextLength: Int {
		get {
			return UserDefaults.standard.integer(
				forKey: "contextLength"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "contextLength")
		}
	}
	
	/// Static constant which controls how creative an LLM is
	public static var temperature: Double {
		get {
			return UserDefaults.standard.double(
				forKey: "temperature"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "temperature")
		}
	}
	
	/// Computed property for whether the LLM uses GPU acceleration
	static var useGPUAcceleration: Bool {
		get {
			// Set default
			if !UserDefaults.standard.exists(key: "useGPUAcceleration") {
				// Default to true
				Self.useGPUAcceleration = true
			}
			return UserDefaults.standard.bool(
				forKey: "useGPUAcceleration"
			)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "useGPUAcceleration")
		}
	}
	
	/// Function that sets default values
	public static func setDefaults() {
		systemPrompt = defaultSystemPrompt
		contextLength = defaultContextLength
		temperature = defaultTemperature
	}
	
	/// Function to switch to normal system prompt
	public static func setNormalSystemPrompt() {
		systemPrompt = defaultSystemPrompt
	}
	
}
