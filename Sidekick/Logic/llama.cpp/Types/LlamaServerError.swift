//
//  LlamaServerError.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import Foundation

enum LlamaServerError: LocalizedError {
	
	var errorDescription: String? {
		switch self {
			case .modelError(let modelName):
				return "Error Loading (\(modelName))"
			default:
				return "Llama Server Error"
		}
	}
	
	var recoverySuggestion: String {
		switch self {
			case .modelError:
				return "Try selecting another model in Settings"
			default:
				return "Try again later"
		}
	}
	
	case pipeFail
	case jsonEncodingError
	case modelError(modelName: String)
	
}
