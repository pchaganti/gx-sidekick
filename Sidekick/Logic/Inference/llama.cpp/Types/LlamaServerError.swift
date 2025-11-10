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
            case .contextWindowExceeded:
                return String(localized: "Context Window Exceeded")
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
            case .contextWindowExceeded(let message):
                return String(localized: "The context window was exceeded. Sidekick will automatically compress tool results and retry.\n\n\(message)")
            default:
                return String(localized: "Restart Sidekick")
        }
    }
    
    /// A `Bool` indicating if the error is retryable
    var isRetryable: Bool {
        switch self {
            case .networkError:
                return true
            case .contextWindowExceeded:
                return true
            default:
                return false
        }
    }
    
    /// Static function to detect if an error message indicates a context window error
    static func isContextWindowError(message: String, code: Int? = nil, metadata: [String: String]? = nil) -> Bool {
        // First check if metadata.raw contains the actual error (common with OpenRouter/proxies)
        if let metadata = metadata,
           let rawError = metadata["raw"] {
            // Recursively check the raw error string
            if isContextWindowError(message: rawError, code: code) {
                return true
            }
        }
        
        let resolvedCode: Int? = code ?? extractStatusCode(from: message)
        
        let lowercased = message.lowercased()
        
        // HTTP 413 is "Payload Too Large" - almost always a context window issue
        if let resolvedCode = resolvedCode, resolvedCode == 413 {
            return true
        }
        
        // OpenAI patterns
        if lowercased.contains("this model's maximum context length") ||
            lowercased.contains("context_length_exceeded") ||
            lowercased.contains("your input exceeds the context window") {
            return true
        }
        // Anthropic patterns
        if lowercased.contains("input length") && lowercased.contains("exceed context limit") ||
            lowercased.contains("request size exceeds model context window") ||
            lowercased.contains("request_too_large") {
            return true
        }
        // General patterns that work across multiple providers
        let hasContextKeyword = lowercased.contains("context") ||
        lowercased.contains("sequence") ||
        lowercased.contains("input") ||
        lowercased.contains("prompt")
        let hasExceedKeyword = lowercased.contains("exceed") ||
        lowercased.contains("limit") ||
        lowercased.contains("maximum") ||
        lowercased.contains("too long") ||
        lowercased.contains("too many tokens") ||
        lowercased.contains("over")
        
        if hasContextKeyword && hasExceedKeyword {
            return true
        }
        
        // Check for nested error messages in JSON strings (fallback)
        if lowercased.contains("\"message\":") && lowercased.contains("prompt") {
            // Try to extract nested message
            if let rangeStart = lowercased.range(of: "\"message\":\""),
               let messageStart = lowercased.index(rangeStart.upperBound, offsetBy: 0, limitedBy: lowercased.endIndex) {
                let remainingString = String(lowercased[messageStart...])
                if let rangeEnd = remainingString.range(of: "\"") {
                    let extractedMessage = String(remainingString[..<rangeEnd.lowerBound])
                    // Recursively check the extracted message
                    return isContextWindowError(message: extractedMessage)
                }
            }
        }
        
        return false
    }
    
    /// Attempts to extract an HTTP status code from an error message string
    static func extractStatusCode(from message: String) -> Int? {
        // Look for common patterns
        let patterns: [String] = [
            "\"code\":",
            "status code:",
            "http status:",
            "httpstatuscode:"
        ]
        for pattern in patterns {
            if let range = message.lowercased().range(of: pattern) {
                let substring = message[range.upperBound...]
                // Extract leading digits
                let digits = substring.prefix { $0.isNumber }
                if let value = Int(digits) {
                    return value
                }
            }
        }
        return nil
    }
    
    case pipeFail
    case jsonEncodingError
    case modelError
    case errorResponse(String)
    case networkError(String)
    case contextWindowExceeded(String)
    case cancelled
    
}
