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
	}
	
	/// Init for chat
	init(
		messages: [Message.MessageSubset],
		systemPrompt: String,
		similarityIndex: SimilarityIndex?
	) async {
		// Formulate messages
		let fullSystemPrompt: String = """
\(systemPrompt)

\(InferenceSettings.useJsonSchemaPrompt)

\(InferenceSettings.useSourcesPrompt)
"""
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
		// Set grammar
		let schemaUrl: URL = Bundle.main.url(
			forResource: "chatResponse",
			withExtension: "gbnf"
		)!
		let grammar: String = (try? String(
			contentsOf: schemaUrl
		)) ?? ""
		self.grammar = grammar
	}
	
	var messages: [Message.MessageSubset]
	
	var stream: Bool = true
	var temperature = InferenceSettings.temperature
	var grammar: String? = nil
	
	/// Function to convert chat parameters to JSON
	public func toJSON() -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let jsonData = try? encoder.encode(self)
		return String(data: jsonData!, encoding: .utf8)!
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
	
}
