//
//  FunctionCall.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation
import SwiftUI

protocol AnyFunctionBox {
    
    var name: String { get }
    func getJsonSchema() -> String
    func call(withData data: Data) throws -> String?
    
}

public struct FunctionCall: Codable, Equatable, Hashable {
    
    /// Function to conform to equatable
    public static func == (lhs: FunctionCall, rhs: FunctionCall) -> Bool {
        return lhs.config == rhs.config && lhs.status == rhs.status && lhs.timeCalled == rhs.timeCalled
    }
    
    /// The function call's configuration
    let config: FunctionCallConfig
    
    /// A ``Status`` representing if the function was executed successfully
    var status: Status? = .executing
    /// A `Date` for the time where the function was called
    var timeCalled: Date? = nil
    /// A `String` containing the result of the run
    var result: String? = nil
    
    // Custom coding keys to match the JSON structure
    enum CodingKeys: String, CodingKey {
        case config = "function_call"
        case status = "status"
        case timeCalled = "timeCalled"
        case result = "result"
    }
    
    /// Function to call the function
    mutating func call() throws -> String? {
        // Mark as executing
        self.status = .executing
        self.timeCalled = Date.now
        // Locate the function by name
        guard let function = Functions.functions.first(
            where: { $0.name == self.config.name }
        ) else {
            throw FunctionCallError.functionNotFound
        }
        // Instead of expecting a raw type (like a tuple or a simple String), we are using Codable structs for parameters.
        let argumentData = try JSONSerialization.data(withJSONObject: config.arguments, options: [])
        // Use the type erased call method.
        return try function.call(withData: argumentData)
    }
    
    /// Function to convert the function call to JSON
    func getJsonSchema() -> String {
        let encoder: JSONEncoder = JSONEncoder()
        let jsonData: Data? = try? encoder.encode(self)
        return String(data: jsonData!, encoding: .utf8)!
    }
    
    public enum FunctionCallError: String, Error {
        case functionNotFound = "The function called is not available"
    }
    
    public enum Status: Codable, CaseIterable {
        
        case succeeded
        case failed
        case executing
        
        var color: Color {
            switch self {
                case .succeeded:
                    return .brightGreen
                case .failed:
                    return .red
                case .executing:
                    return .secondary
            }
        }
    }
}

public struct FunctionCallConfig: Codable, Hashable {
    let name: String
    let arguments: [String: String]
}
