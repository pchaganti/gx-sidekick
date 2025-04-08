//
//  FunctionCall.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

protocol AnyFunctionBox {
    
    var name: String { get }
    func getJsonSchema() -> String
    func call(withData data: Data) throws -> String?
    
}

struct FunctionCall: Codable {
    
    let config: FunctionCallConfig
    
    // Custom coding keys to match the JSON structure
    enum CodingKeys: String, CodingKey {
        case config = "function_call"
    }
    
    /// Function to call the function
    func call() throws -> String? {
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
    
    enum FunctionCallError: String, Error {
        case functionNotFound = "The function called is not available"
    }
}

struct FunctionCallConfig: Codable {
    let name: String
    let arguments: [String: String]
}
