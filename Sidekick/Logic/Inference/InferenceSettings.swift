//
//  InferenceSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import Combine

public class InferenceSettings {
	
	/// Static computed property for the default LLM
	static var defaultModelUrl: URL {
		let memory: Double = Double(ProcessInfo.processInfo.physicalMemory)
		let memoryGb: Int = Int(memory / pow(2,30))
		switch memoryGb {
			case 8:
				return URL(string: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q8_0.gguf")!
			case 16:
				return URL(string:"https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q8_0.gguf")!
			case 24:
				return URL(string:"https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K_L.gguf")!
			default:
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
The user's request might be followed by reference information that may or may not be complete nor related. If the provided information is related to the request, you must end respond with reference to the information, filling in the gaps with your own knowledge, and ending your response with a list of URLs or filepaths of all provided sources referenced in the format [{"url": "https://referencedurl.com"}, {"url": "/path/to/referenced/file.pdf"}], with no duplicates. Else, you will ignore the information, avoid mentioning sources in your response, and end your response with an empty array of JSON objects: [].
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
