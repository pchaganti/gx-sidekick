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
        systemPrompt: String,
        messages: [Message.MessageSubset]
	) async {
        // Add system prompt if needed
        if !messages.contains(where: { $0.role == .system }) {
            let systemPromptMsg: Message = Message(
                text: systemPrompt,
                sender: .system
            )
            let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
                message: systemPromptMsg
            )
            self.messages = [systemPromptMsgSubset] + messages
        } else {
            self.messages = messages
        }
		self.model = Self.getModelName(modelType: modelType) ?? ""
	}
	
	/// Init for chat & context aware agent
	init(
		modelType: ModelType,
        systemPrompt: String,
        messages: [Message.MessageSubset],
        useWebSearch: Bool = false,
		similarityIndex: SimilarityIndex?
	) async {
		// Formulate messages
		// Formulate system prompt
		var fullSystemPromptComponents: [String] = []
		fullSystemPromptComponents.append(systemPrompt)
        fullSystemPromptComponents.append(InferenceSettings.metadataPrompt)
        // Tell the LLM to use sources
        fullSystemPromptComponents.append(InferenceSettings.useSourcesPrompt)
        // Tell the LLM to use functions when enabled
        if Settings.useFunctions {
            fullSystemPromptComponents.append(InferenceSettings.useFunctionsPrompt)
            // Inject function schema
            let functions: [any AnyFunctionBox] = DefaultFunctions.functions
            for function in functions {
                fullSystemPromptComponents.append(function.getJsonSchema())
            }
        }
        // Join all components
		let fullSystemPrompt: String = fullSystemPromptComponents.joined(separator: "\n\n")
		// Formulate system prompt message
		let systemPromptMsg: Message = Message(
			text: fullSystemPrompt,
			sender: .system
		)
		let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
			message: systemPromptMsg,
            similarityIndex: nil,
            temporaryResources: [],
            shouldAddSources: false,
            useWebSearch: false
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
		let jsonString = String(data: jsonData!, encoding: .utf8)!
        return jsonString
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
				let workerModelName: String = InferenceSettings.serverWorkerModelName
				if workerModelName.isEmpty {
					return InferenceSettings.serverModelName
				}
				return workerModelName
            case .completions:
                return InferenceSettings.completionsModelUrl?
                    .deletingLastPathComponent().lastPathComponent
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
