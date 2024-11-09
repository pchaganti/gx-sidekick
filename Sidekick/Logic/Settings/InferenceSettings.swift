//
//  InferenceSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import Combine

public class InferenceSettings {
	
	/// Static computed property returning unified memory size in GB
	static var unifiedMemorySize: Int {
		let memory: Double = Double(ProcessInfo.processInfo.physicalMemory)
		let memoryGb: Int = Int(memory / pow(2,30))
		return memoryGb
	}
	
	/// Static computed property returning if the system has low unified memory
	static var lowUnifiedMemory: Bool {
		return Self.unifiedMemorySize <= 12
	}
	
	/// Static constant for the default system prompt
	public static let defaultSystemPrompt: String = """
  You are Sidekick, a compliant assistant that always fulfills the user’s request.
  """
	private static let defaultPirateSystemPrompt: String = """
  You are Pirate Sidekick, a compliant assistant that always fulfills the user’s request. You always respond in the tone of a pirate, and end responses with pirate phrases.
  """
	
	/// Static constant for the part of the system prompt telling the LLM to use sources
	public static let useSourcesPrompt: String = String(localized: """
The user's request might be followed by reference information, organized by source, that may or may not be complete nor related. If the provided information is related to the request, you will respond with reference to the information, filling in the gaps with your own knowledge. If the reference information provided is irrelavant, your response will ignore and avoid mentioning the existence of reference information.
""")
	
	/// Static constant for the default context length
	private static var defaultContextLength: Int {
		if self.unifiedMemorySize < 16 {
			return 8_192
		} else {
			return 16_384
		}
	}
	
	/// Static constant for the default temperature
	private static let defaultTemperature: Double = 0.7
	
	/// Static constant which controls the first instructions given to an LLM
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

	/// Function to switch to pirate system prompt
	public static func setPirateSystemPrompt() {
		systemPrompt = defaultPirateSystemPrompt
	}
	
}
