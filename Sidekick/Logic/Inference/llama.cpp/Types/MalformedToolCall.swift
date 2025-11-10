//
//  MalformedToolCall.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import Foundation

/// Represents a tool call that failed to parse
public struct MalformedToolCall {
    
    var index: Int
    var name: String?
    var rawArguments: String
    var errorDescription: String
    
    /// Function to format error message for the model
    func getErrorFeedback() -> String {
        let functionName = name ?? "unknown"
        return """
            Tool call #\(index) ('\(functionName)') failed to parse.
            
            Error: \(errorDescription)
            
            Raw arguments received:
            ```json
            \(rawArguments)
            ```
            
            Please check your tool call format and try again with valid JSON arguments that match the function's parameter schema.
            """
    }
    
    }
