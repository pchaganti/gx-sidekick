//
//  Extension+Tavily.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation

public extension Tavily {
	
    struct SearchRequest: Codable {
		
		var query: String
		var max_results: Int = 3
        var time_range: Tavily.TimeRange? = nil
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
	
	struct SearchResponse: Codable {
		
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
    
    struct ExtractRequest: Codable {
        
        var urls: String
        var include_images: Bool = false
        var extract_depth: ExtractDepth = .advanced
        
        public enum ExtractDepth: String, Codable {
            case basic
            case advanced
        }
        
        /// Function to convert chat parameters to JSON
        public func toJSON() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try? encoder.encode(self)
            return String(data: jsonData!, encoding: .utf8)!
        }
        
    }
    
    struct ExtractResponse: Codable {
        
        var results: [Result]
        var response_time: Float
        
        public struct Result: Codable {
        
            var url: String
            var raw_content: String
            
        }
        
    }
	
}
