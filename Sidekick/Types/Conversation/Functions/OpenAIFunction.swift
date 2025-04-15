//
//  OpenAIFunction.swift
//  Sidekick
//
//  Created by John Bean on 4/15/25.
//

import Foundation

public struct OpenAIFunction: Codable {
    
    let type: String
    let function: FunctionDetail
    
}

public struct FunctionDetail: Codable {
    
    let name: String
    let description: String
    let parameters: ParameterSchema
    let strict: Bool
    
}

public struct ParameterSchema: Codable {
    
    let type: String
    let properties: [String: PropertyDetail]
    let required: [String]
    let additionalProperties: Bool
    
}

public struct PropertyDetail: Codable {
    
    init(
        functionParameter: FunctionParameter
    ) {
        self.type = Type(
            type: functionParameter.datatype
        )
        self.description = functionParameter.description
        self.items = {
            switch functionParameter.datatype {
                // If not array, return nil
                case .string, .integer, .float, .boolean:
                    return nil
                case .stringArray:
                    return ItemType(type: .string)
                case .integerArray, .floatArray:
                    return ItemType(type: .number)
            }
        }()
    }
    
    let type: `Type`
    let description: String
    let items: ItemType?
    
    public struct ItemType: Codable {
        var type: `Type`
    }
    
    public enum `Type`: String, Codable {
        
        init(
            type: FunctionParameter.Datatype
        ) {
            switch type {
                case .integer, .float:
                    self = .number
                case .boolean:
                    self = .boolean
                case .stringArray, .integerArray, .floatArray:
                    self = .array
                default:
                    self = .string
            }
        }
        
        case string
        case boolean
        case number
        case array
    }
    
}
