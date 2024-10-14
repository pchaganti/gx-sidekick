//
//  ChatParameters.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import Foundation
import SimilaritySearchKit

struct ChatParameters: Codable {
	
	init(
		messages: [Message],
		systemPrompt: String,
		similarityIndex: SimilarityIndex?
	) async {
		let systemPromptMsg: Message = Message(
			text: systemPrompt,
			sender: .system
		)
		let messagesWithSystemPrompt: [Message] = [systemPromptMsg] + messages
		let lastIndex: Int = messagesWithSystemPrompt.count - 1
		self.messages = await messagesWithSystemPrompt.enumerated().asyncMap { index, message in
			return await Message.MessageSubset(
				message: message,
				similarityIndex: index != lastIndex ? nil : similarityIndex
			)
		}
	}
	
	var messages: [Message.MessageSubset]
	
	var stream = true
	var n_threads = 6
	var n_predict = -1
	var temperature = InferenceSettings.temperature
	var repeat_last_n = 128  // 0 = disable penalty, -1 = context size
	var repeat_penalty = 1.18  // 1.0 = disabled
	var top_k = 40  // <= 0 to use vocab size
	var top_p = 0.95  // 1.0 = disabled
	var tfs_z = 1.0  // 1.0 = disabled
	var typical_p = 1.0  // 1.0 = disabled
	var presence_penalty = 0.0  // 0.0 = disabled
	var frequency_penalty = 0.0  // 0.0 = disabled
	var mirostat = 0  // 0/1/2
	var mirostat_tau = 5  // target entropy
	var mirostat_eta = 0.1  // learning rate
	var cache_prompt = true
	
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
