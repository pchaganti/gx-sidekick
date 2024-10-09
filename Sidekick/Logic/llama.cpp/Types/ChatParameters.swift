//
//  ChatParameters.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import Foundation

struct ChatParameters: Codable {
	
	init(
		messages: [Message]
	) {
		self.messages = messages.map {
			Message.MessageSubset(message: $0)
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
	
}
