//
//  ChatParameters.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import Foundation
import SimilaritySearchKit

struct ChatParameters: Codable {
	
	/// Init for non-chat
	init(
		modelType: ModelType,
		messages: [Message.MessageSubset],
		systemPrompt: String
	) async {
		let systemPromptMsg: Message = Message(
			text: systemPrompt,
			sender: .system
		)
		let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
			message: systemPromptMsg
		)
		self.messages = [systemPromptMsgSubset] + messages
		self.model = Self.getModelName(modelType: modelType) ?? ""
	}
	
	/// Init for chat & context aware agent
	init(
		modelType: ModelType,
		messages: [Message.MessageSubset],
		systemPrompt: String,
		useInterpreter: Bool = false,
		similarityIndex: SimilarityIndex?
	) async {
		// Formulate messages
		// Formulate system prompt
		var fullSystemPromptComponents: [String] = []
		fullSystemPromptComponents.append(systemPrompt)
		fullSystemPromptComponents.append(InferenceSettings.useSourcesPrompt)
		if useInterpreter && Settings.useCodeInterpreter {
			fullSystemPromptComponents.append(InferenceSettings.useInterpreterPrompt)
		}
		fullSystemPromptComponents.append(InferenceSettings.metadataPrompt)
		let fullSystemPrompt: String = fullSystemPromptComponents.joined(separator: "\n\n")
		// Formulate system prompt message
		let systemPromptMsg: Message = Message(
			text: fullSystemPrompt,
			sender: .system
		)
		let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
			message: systemPromptMsg,
			similarityIndex: nil,
			shouldAddSources: false,
			useWebSearch: false,
			temporaryResources: []
		)
		let messagesWithSystemPrompt: [Message.MessageSubset] = [systemPromptMsgSubset] + messages
		self.messages = messagesWithSystemPrompt
		self.model = Self.getModelName(modelType: modelType) ?? ""
	}
	
	var model: String = InferenceSettings.useServer ? InferenceSettings.serverModelName : ""
	var messages: [Message.MessageSubset]
	
	var temperature = InferenceSettings.temperature
	
	var stream: Bool = true
	var stream_options: StreamOptions = .init()
	
	/// Function to convert chat parameters to JSON
	public func toJSON() -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let jsonData = try? encoder.encode(self)
		return String(data: jsonData!, encoding: .utf8)!
	}
	
	/// Function to get the name of the model that will be used
	private static func getModelName(
		modelType: ModelType
	) -> String? {
		// Return nil if server is unused
		if !InferenceSettings.useServer {
			return nil
		}
		// Else, get name
		switch modelType {
			case .regular:
				return InferenceSettings.serverModelName
			case .worker:
				return InferenceSettings.serverWorkerModelName
		}
	}
	
	struct SystemPrompt: Codable {
		
		var prompt: String
		var anti_prompt : String = "user:"
		var assistant_name: String = "assistant:"
		
		var wrapper: SystemPromptWrapper {
			.init(system_prompt: self)
		}
		
		public struct SystemPromptWrapper: Codable {
			
			var system_prompt: SystemPrompt
			
			/// Function to convert chat parameters to JSON
			public func toJSON() -> String {
				let encoder = JSONEncoder()
				encoder.outputFormatting = .prettyPrinted
				let jsonData = try? encoder.encode(self)
				return String(data: jsonData!, encoding: .utf8)!
			}
			
		}
	}
	
	struct StreamOptions: Codable {
		var include_usage: Bool = true
	}
	
}
