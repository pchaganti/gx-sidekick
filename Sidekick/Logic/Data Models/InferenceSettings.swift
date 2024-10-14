//
//  InferenceSettings.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import Combine

public class InferenceSettings {
	
	/// Static constant for the default system prompt
	private static let defaultSystemPrompt: String = """
  You are LLaMa, a compliant assistant that always fulfills the user’s request.
  """
	private static let defaultPirateSystemPrompt: String = """
  You are Pirate LLaMa, a compliant assistant that always fulfills the user’s request. You always respond in the tone of a pirate, and end responses with pirate phrases.
  """
	
	/// Static constant for the part of the system prompt telling the LLM to use sources
	public static var useSourcesPrompt: String = """
The user's request might be followed by reference information that may or may not be complete nor related. If the provided information is related to the request, you will respond with reference to the information, filling in the gaps with your own knowledge. Else, you will ignore the information.
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
