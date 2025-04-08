//
//  StringOrNumber.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

/// A property wrapper that decodes/encodes a non-optional value of type T from either a number or a String.
@propertyWrapper
struct StringOrNumber<T: LosslessStringConvertible & Codable>: Codable {
    var wrappedValue: T
    
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(T.self) {
            self.wrappedValue = value
        } else if let string = try? container.decode(String.self), let value = T(string) {
            self.wrappedValue = value
        } else {
            throw DecodingError.typeMismatch(
                T.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Expected \(T.self) as either a number or a string.")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

/// A property wrapper that decodes/encodes an optional value of type T from either a number or a String.
@propertyWrapper
struct OptionalStringOrNumber<T: LosslessStringConvertible & Codable>: Codable {
    var wrappedValue: T?
    
    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.wrappedValue = nil
        } else if let value = try? container.decode(T.self) {
            self.wrappedValue = value
        } else if let string = try? container.decode(String.self), let value = T(string) {
            self.wrappedValue = value
        } else {
            // If decoding fails, set to nil (or throw an error if you prefer)
            self.wrappedValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

/// A property wrapper that decodes an array of type T from either a JSON string or directly as an array.
@propertyWrapper
struct StringOrArray<T: Codable>: Codable {
    var wrappedValue: [T]
    
    init(wrappedValue: [T]) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // First, try to decode as a String.
        if let stringValue = try? container.decode(String.self) {
            guard let data = stringValue.data(using: .utf8) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string encoding for array.")
            }
            self.wrappedValue = try JSONDecoder().decode([T].self, from: data)
        } else {
            // Otherwise, decode directly as an array.
            self.wrappedValue = try container.decode([T].self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
