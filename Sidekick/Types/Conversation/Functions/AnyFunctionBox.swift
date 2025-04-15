//
//  AnyFunctionBox.swift
//  Sidekick
//
//  Created by John Bean on 4/15/25.
//

import Foundation

protocol AnyFunctionBox {
    
    var name: String { get }
    var params: [FunctionParameter] { get }
    
    func getJsonSchema() -> String
    func call(withData data: Data) async throws -> String?
    
    var paramsType: any FunctionParams.Type { get }
    var resultType: Codable.Type { get }
    
    var openAiFunctionCall: OpenAIFunction { get }
    
    var functionCallType: DecodableFunctionCall.Type { get }
    
}
