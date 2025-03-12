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
				return String(localized: "The AI is on strike!")
			default:
				return String(localized: "Inference Server Error")
		}
	}
	
	var recoverySuggestion: String {
		switch self {
			case .modelError:
				return String(localized: "The local AI model couldn’t be found, and Sidekick could not connect to a remote server. Please verify that the local and server models are configured correctly in Settings.")
			default:
				return String(localized: "Restart Sidekick")
		}
	}
	
	case pipeFail
	case jsonEncodingError
	case modelError
	
}
