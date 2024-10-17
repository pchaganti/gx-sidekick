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
	
	/// Static computed property for the default LLM
	static var defaultModelUrl: URL {
		let memoryGb: Int = Self.unifiedMemorySize
		if memoryGb <= 8 {
			return URL(string: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q6_K_L.gguf")!
		} else if memoryGb <= 16 {
			return URL(string: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q8_0.gguf")!
		} else if memoryGb <= 18 {
			return URL(string:"https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K_L.gguf")!
		} else {
			return URL(string: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q8_0.gguf")!
		}
	}
	
	/// Static constant for the default system prompt
	public static let defaultSystemPrompt: String = """
  You are LLaMa, a compliant assistant that always fulfills the user’s request.
  """
	private static let defaultPirateSystemPrompt: String = """
  You are Pirate LLaMa, a compliant assistant that always fulfills the user’s request. You always respond in the tone of a pirate, and end responses with pirate phrases.
  """
	
	/// Static constant for the part of the system prompt telling the LLM to use sources
	public static var useSourcesPrompt: String = """
The user's request might be followed by reference information, organized by source, that may or may not be complete nor related. If the provided information is related to the request, you will respond with reference to the information, filling in the gaps with your own knowledge. If the reference information provided is irrelavant, your response will ignore and avoid mentioning the existence of reference information.
"""
	
	/// Static constant for the default context length
	private static let defaultContextLength: Int = 16_384
	
	/// Static constant for the default temperature
	private static let defaultTemperature: Double = 0.8
	
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

	/// Function to switch to piratel system prompt
	public static func setPirateSystemPrompt() {
		systemPrompt = defaultPirateSystemPrompt
	}
	
}
