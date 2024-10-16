//
//  Tavily.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation

public class Tavily {
	
	public struct Request: Codable {
		
		var api_key: String
		var query: String
		var max_results: Int = 3
		var include_answer: Bool = true
		var include_raw_content: Bool = false
		var include_domains: [String] = []
		var exclude_domains: [String] = []
		
		/// Function to convert chat parameters to JSON
		public func toJSON() -> String {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let jsonData = try? encoder.encode(self)
			return String(data: jsonData!, encoding: .utf8)!
		}
		
	}
	
	public struct Response: Codable {
		
		var answer: String
		var query: String
		var response_time: Float
		var results: [Result]
		
		public struct Result: Codable {
			
			var title: String
			var url: String
			var content: String
			var score: Float
			
		}
		
	}
	
}
