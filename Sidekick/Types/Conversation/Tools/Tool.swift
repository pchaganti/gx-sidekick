//
//  Tool.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import Foundation

// MARK: - Parameter Value Protocol
public protocol ParameterValue {
    init?(stringValue: String)
}

// MARK: - Basic Type Extensions
extension String: ParameterValue {
    public init(stringValue: String) {
        self = stringValue
    }
}

extension Float: ParameterValue {
    public init?(stringValue: String) {
        self.init(stringValue)
    }
}

extension Int: ParameterValue {
    public init?(stringValue: String) {
        self.init(stringValue)
    }
}

extension Bool: ParameterValue {
    public init?(stringValue: String) {
        self.init(stringValue.lowercased() == "true")
    }
}

// MARK: - Array Parameter Value Protocol
protocol ArrayParameterValue: ParameterValue {
    static func parseArray(
        from string: String
    ) -> [Self]?
}

// MARK: - Array Extensions
extension Array: ParameterValue where Element: ParameterValue {
    public init?(
        stringValue: String
    ) {
        // Remove brackets and whitespace, then split by commas
        let trimmed = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let components = trimmed.split(separator: ",").map(String.init)
        // Convert each component to the element type
        let values = components.compactMap { Element(stringValue: $0.trimmingCharacters(in: .whitespaces)) }
        // Only succeed if we could convert all elements
        guard values.count == components.count else { return nil }
        self = values
    }
}

// MARK: - Updated Tool Parameter
public struct ToolParameter: Codable {
    var label: String
    var description: String
    var datatype: Datatype
    var isRequired: Bool = true
    
    public enum Datatype: String, Codable {
        case string
        case integer
        case float
        case boolean
        case stringArray
        case integerArray
        case floatArray
    }
    
    /// Helper function to get the Swift type for a Datatype
    func getSwiftType() -> Any.Type {
        switch datatype {
            case .string:
                return String.self
            case .integer:
                return Int.self
            case .float:
                return Float.self
            case .boolean:
                return Bool.self
            case .stringArray:
                return [String].self
            case .integerArray:
                return [Int].self
            case .floatArray:
                return [Float].self
        }
    }
}

// MARK: - Type-safe Parameter
public struct TypedParameter<T: ParameterValue> {
    
    let label: String
    let value: T?
    let isRequired: Bool
    
    init?(
        label: String,
        stringValue: String?,
        isRequired: Bool = true
    ) {
        self.label = label
        self.isRequired = isRequired
        // Handle nil stringValue for optional parameters
        guard let stringValue = stringValue else {
            if isRequired {
                return nil
            }
            self.value = nil
            return
        }
        // Convert string value to type T
        guard let convertedValue = T(stringValue: stringValue) else {
            if isRequired {
                return nil
            }
            self.value = nil
            return
        }
        self.value = convertedValue
    }
    
    // Helper to get the value or throw an error if nil
    func getValue() throws -> T {
        guard let value = self.value else {
            throw ParameterParsingError.invalidValue("Required parameter \(label) is nil")
        }
        return value
    }
}

// MARK: - Tool Protocol
protocol ToolProtocol: Identifiable {
    associatedtype Parameters
    associatedtype Result
    
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var params: [ToolParameter] { get }
    var run: (Parameters) throws -> Result { get }
}

// MARK: - Generic Tool Implementation
public struct Tool<Parameter, Result>: ToolProtocol {
    public var id: String { return name }
    public var name: String
    public var description: String
    public var params: [ToolParameter]
    public var run: (Parameter) throws -> Result
    
    public init(
        name: String,
        description: String,
        params: [ToolParameter],
        run: @escaping (Parameter) throws -> Result
    ) {
        self.name = name
        self.description = description
        self.params = params
        self.run = run
    }
    
    public var toolObject: ToolObject {
        // Create numbered properties to ensure order
        let properties = Dictionary(uniqueKeysWithValues: params.enumerated().map { index, param in
            let numberedKey = String(format: "%04d_%@", index, param.label)
            return (numberedKey, ToolObject.Function.InputSchema.Property(
                type: param.datatype.rawValue,
                description: param.description,
                isRequired: param.isRequired
            ))
        })
        
        return ToolObject(
            type: "function",
            function: ToolObject.Function(
                name: self.name,
                description: self.description,
                inputSchema: ToolObject.Function.InputSchema(
                    type: "object",
                    properties: properties,
                    paramLabels: params.map { $0.label }
                )
            )
        )
    }
    
    public func getJsonSchema() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try! encoder.encode(self.toolObject)
        // Process the JSON to remove the number prefixes
        let jsonStr = String(data: jsonData, encoding: .utf8)!
        return cleanNumberedKeys(jsonStr)
    }
    
    private func cleanNumberedKeys(_ jsonStr: String) -> String {
        // Remove the numbered prefixes from property keys
        var lines = jsonStr.components(separatedBy: .newlines)
        lines = lines.map { line in
            if line.contains("\"0") { // Matches our numbered format
                let components = line.split(separator: "\"", omittingEmptySubsequences: false)
                if components.count >= 2 {
                    var key = String(components[1])
                    if let underscoreIndex = key.firstIndex(of: "_") {
                        key = String(key[key.index(after: underscoreIndex)...])
                        return line.replacingOccurrences(of: components[1], with: key)
                    }
                }
            }
            return line
        }
        return lines.joined(separator: "\n")
    }
    
    public struct ToolObject: Codable {
        var type: String = "function"
        var function: Function
        
        public struct Function: Codable {
            var name: String
            var description: String
            var inputSchema: InputSchema
            
            public struct InputSchema: Codable {
                let type: String
                let properties: [String: Property]
                var required: [String]
                private let paramLabels: [String]
                
                init(
                    type: String,
                    properties: [String: Property],
                    paramLabels: [String]
                ) {
                    self.type = type
                    self.properties = properties
                    self.paramLabels = paramLabels
                    // Compute required preserving the original param order
                    self.required = paramLabels.filter { label in
                        // Find the numbered key that ends with this label
                        properties.first { key, prop in
                            key.hasSuffix("_\(label)") && prop.isRequired
                        } != nil
                    }
                }
                
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(type, forKey: .type)
                    try container.encode(properties, forKey: .properties)
                    // Encode required without number prefixes
                    try container.encode(required, forKey: .required)
                }
                
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.type = try container.decode(String.self, forKey: .type)
                    self.properties = try container.decode([String: Property].self, forKey: .properties)
                    self.required = try container.decode([String].self, forKey: .required)
                    self.paramLabels = self.required.isEmpty ? Array(properties.keys) : self.required
                }
                
                public enum CodingKeys: String, CodingKey {
                    case type, properties, required
                }
                
                public struct Property: Codable {
                    let type: String
                    let description: String
                    let isRequired: Bool
                }
            }
        }
    }
}

// MARK: - Parameter Parsing Error
enum ParameterParsingError: Error {
    case invalidArrayFormat(String)
    case incompatibleType(String)
    case invalidValue(String)
}
