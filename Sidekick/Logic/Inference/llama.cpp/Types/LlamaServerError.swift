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
            case .networkError:
                return String(localized: "Network Connection Lost")
            default:
                return String(localized: "Inference Server Error")
        }
    }
    
    var recoverySuggestion: String {
        switch self {
            case .modelError:
                return String(localized: "The local AI model couldn't be found, and Sidekick could not connect to a remote server. Please verify that the local and server models are configured correctly in Settings.")
            case .errorResponse(let message):
                return String(localized: "Fix the error according to the server's error message below, then try again.\n\n\(message)")
            case .networkError(let message):
                return String(localized: "The network connection was lost. The request will be automatically retried.\n\n\(message)")
            default:
                return String(localized: "Restart Sidekick")
        }
    }
    
    /// A `Bool` indicating if the error is retryable
    var isRetryable: Bool {
        switch self {
            case .networkError:
                return true
            default:
                return false
        }
    }
    
    case pipeFail
    case jsonEncodingError
    case modelError
    case errorResponse(String)
    case networkError(String)
    case cancelled
    
}
