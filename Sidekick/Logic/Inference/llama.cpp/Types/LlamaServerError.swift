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
			case .modelError:
				return String(localized: "Error Loading Model")
			default:
				return String(localized: "Inference Server Error")
		}
	}
	
	var recoverySuggestion: String {
		switch self {
			case .modelError:
				return String(localized: "Try reselecting the model in Settings. If speculative decoding is enabled, also try reselecting the model used for speculative decoding.")
			default:
				return String(localized: "Restart Sidekick")
		}
	}
	
	case pipeFail
	case jsonEncodingError
	case modelError
	
}
